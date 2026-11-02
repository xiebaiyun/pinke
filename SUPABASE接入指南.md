# 台州拼客网 Supabase 接入指南

## 一、创建 Supabase 项目（约5分钟）

1. 打开 https://supabase.com ，用 GitHub 账号登录
2. 点击 **New Project**
3. 填写：
   - **Name**：`taizhou-pinke`
   - **Database Password**：设一个强密码（记下来）
   - **Region**：选 **Northeast Asia (Tokyo)**（离国内最近）
   - **Pricing Plan**：Free（免费）
4. 等待项目创建完成（约2分钟）

## 二、初始化数据库（约2分钟）

1. 进入项目 → 左侧菜单点 **SQL Editor**
2. 打开项目目录中的 `supabase-schema.sql` 文件
3. **全选复制** 所有内容
4. 粘贴到 SQL Editor 中，点击 **Run**
5. 成功后你会看到左侧 Tables 中出现了 6 张表

## 三、配置连接密钥（约1分钟）

1. 进入项目 → **Settings**（左下角齿轮图标）→ **API**
2. 复制以下两项：
   - **Project URL**（如 `https://abcdefg.supabase.co`）
   - **Project API keys** → **anon** `public`（很长的 eyJ... 开头的字符串）
3. 打开项目中的 `assets/config.js`，填入：
   ```javascript
   window.SUPABASE_URL = 'https://你的项目.supabase.co';
   window.SUPABASE_ANON_KEY = 'eyJ...你的密钥';
   ```
4. 保存文件

## 四、配置邮件验证（可选但推荐）

Supabase 默认会发送验证邮件。如果想跳过验证：

1. 进入 **Authentication** → **Providers** → **Email**
2. 关闭 **Confirm email**（用户注册后直接可用）

如果想用中文邮件模板：
1. 进入 **Authentication** → **Email Templates**
2. 修改 Confirmation 模板，把英文改为中文

## 五、本地测试

1. 用浏览器直接打开 `taizhou-pinke.html`
2. 控制台会显示：
   - 未配置时：`[台州拼客网] Supabase 未配置，当前运行在本地演示模式`
   - 已配置时：无提示，数据从 Supabase 加载
3. 尝试注册 → 登录 → 发布拼客 → 收藏，验证功能正常

## 六、部署到免费云服务器

### 方案 A：GitHub Pages（最简单）

1. 注册 GitHub 账号 → 新建仓库 `taizhou-pinke`
2. 上传以下文件：
   - `taizhou-pinke.html`（重命名为 `index.html`）
   - `assets/` 整个文件夹
3. 仓库 Settings → Pages → Source 选 `main` 分支 → Save
4. 访问 `https://你的用户名.github.io/taizhou-pinke/`

### 方案 B：Cloudflare Pages（国内访问更快）

1. 注册 Cloudflare 账号
2. 选择 Pages → Create a project → Direct upload
3. 上传 `index.html` 和 `assets/` 文件夹
4. 部署后获得 `xxx.pages.dev` 域名

### 方案 C：Vercel

1. 注册 Vercel 账号（可用 GitHub 登录）
2. Import Git Repository → 选择你的仓库
3. Framework Preset: `Other`
4. 自动部署，获得 `xxx.vercel.app` 域名

## 七、绑定自己的域名（购买域名后）

1. 在阿里云/腾讯云购买域名（约 50 元/年），推荐 `.com`
2. 在 Supabase 部署平台（如 Vercel）的 Settings → Domains 中添加你的域名
3. 按提示在域名管理商处添加 CNAME 记录指向部署地址
4. 等待 DNS 生效（通常几分钟到几小时）

## 八、数据库管理

- 登录 Supabase Dashboard → **Table Editor** 可以查看和管理所有数据
- 可以直接在 Table Editor 中添加/修改/删除拼客活动和商家信息
- **Authentication → Users** 查看所有注册用户

## 九、免费额度

Supabase 免费版包含：
- 500MB 数据库存储
- 5 万月活用户
- 1GB 文件存储
- 无限 API 请求

对台州拼客网初期运营完全够用。超出后可升级到 Pro（$25/月）。

## 文件清单

| 文件 | 作用 |
|---|---|
| `taizhou-pinke.html` | 网站主页面（部署时改名为 index.html） |
| `assets/data.js` | 本地示例数据（Supabase 未配置时使用） |
| `assets/config.js` | Supabase 连接配置（需填入你的 URL 和 Key） |
| `supabase-schema.sql` | 数据库表结构（粘贴到 SQL Editor 执行） |
| `SUPABASE接入指南.md` | 本文档 |
