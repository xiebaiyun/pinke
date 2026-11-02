const https = require('https');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DEPLOY_DIR = 'C:\\Users\\xby\\Documents\\qwen-agent\\m0m16yvhca\\default\\taizhou-pinke-web-20261012T204050045Z\\deploy';

function fileSha1(buf) {
  return crypto.createHash('sha1').update(buf).digest('hex');
}

function readFiles(dir, prefix) {
  const files = {};
  for (const entry of fs.readdirSync(dir)) {
    if (entry === '.github') continue; // skip github workflows for netlify
    if (entry === '.apps-builder') continue;
    const full = path.join(dir, entry);
    const rel = prefix ? prefix + '/' + entry : entry;
    if (fs.statSync(full).isDirectory()) {
      Object.assign(files, readFiles(full, rel));
    } else {
      files[rel] = fs.readFileSync(full);
    }
  }
  return files;
}

function netlifyReq(method, urlPath, body, headers) {
  return new Promise((resolve, reject) => {
    const opts = {
      hostname: 'api.netlify.com',
      path: urlPath,
      method,
      headers: headers || {}
    };
    if (body) {
      opts.headers['Content-Type'] = opts.headers['Content-Type'] || 'application/json';
      opts.headers['Content-Length'] = Buffer.isBuffer(body) ? body.length : Buffer.byteLength(body);
    }
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch (e) { resolve({ status: res.statusCode, data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function deploy() {
  console.log('📦 Reading files...');
  const files = readFiles(DEPLOY_DIR, '');
  console.log('  Files:', Object.keys(files));

  // Step 1: Create site with file digest
  console.log('\n🚀 Creating deploy...');
  const fileDigests = {};
  for (const [k, v] of Object.entries(files)) {
    fileDigests['/' + k] = fileSha1(v);
  }
  const createBody = JSON.stringify({ files: fileDigests });
  const createRes = await netlifyReq('POST', '/api/v1/sites', createBody);
  
  if (createRes.status !== 200 && createRes.status !== 201) {
    console.error('❌ Create site failed:', createRes.status, JSON.stringify(createRes.data).substring(0, 200));
    return;
  }
  
  const siteId = createRes.data.id;
  const siteUrl = createRes.data.ssl_url || createRes.data.url || ('https://' + createRes.data.subdomain + '.netlify.app');
  console.log('  Site ID:', siteId);
  console.log('  URL:', siteUrl);

  // Step 2: Upload required files
  const required = createRes.data.required || [];
  console.log('\n⬆️  Uploading', required.length, 'files...');
  
  const shaToFile = {};
  for (const [k, v] of Object.entries(files)) {
    const sha = fileSha1(v);
    shaToFile[sha] = { path: '/' + k, buf: v };
  }

  for (const sha of required) {
    const f = shaToFile[sha];
    if (!f) { console.warn('  ⚠️ Missing file for sha:', sha); continue; }
    const uploadRes = await netlifyReq('PUT', '/api/v1/sites/' + siteId + '/files' + f.path, f.buf, { 'Content-Type': 'application/octet-stream' });
    if (uploadRes.status >= 200 && uploadRes.status < 300) {
      console.log('  ✓', f.path);
    } else {
      console.log('  ✗', f.path, uploadRes.status);
    }
  }

  console.log('\n✅ 部署完成！');
  console.log('🌐 网站地址:', siteUrl);
  console.log('\n注意：这是一个匿名站点。要永久保留请注册 Netlify 账号 claim 此站点。');
  
  // Write result to file
  fs.writeFileSync(
    path.join(DEPLOY_DIR, 'deploy-result.json'),
    JSON.stringify({ siteId, url: siteUrl, adminUrl: createRes.data.admin_url }, null, 2)
  );
}

deploy().catch(e => console.error('Deploy error:', e));
