-- ============================================================
-- 台州拼客网 Supabase 数据库结构
-- 在 Supabase Dashboard → SQL Editor 中粘贴执行
-- ============================================================

-- 1. 用户资料表（与 Supabase Auth 联动）
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nickname TEXT NOT NULL DEFAULT '',
  phone TEXT DEFAULT '',
  avatar_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "所有人可查看" ON profiles FOR SELECT USING (true);
CREATE POLICY "只能修改自己" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "只能新增自己" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 触发器：注册时自动创建资料
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'nickname', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END; $$;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. 拼客活动表
CREATE TABLE pinke_activities (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'meishi',
  price INTEGER DEFAULT 0,
  original_price INTEGER DEFAULT 0,
  min_people INTEGER DEFAULT 5,
  current_people INTEGER DEFAULT 1,
  deadline DATE DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
  location TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'new' CHECK (status IN ('hot','new','normal','full')),
  organizer TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  views INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE pinke_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "所有人可查看" ON pinke_activities FOR SELECT USING (true);
CREATE POLICY "登录用户可发布" ON pinke_activities FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "作者可修改" ON pinke_activities FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "作者可删除" ON pinke_activities FOR DELETE USING (auth.uid() = created_by);

-- 3. 商家表
CREATE TABLE merchants (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'meishi',
  rating DECIMAL(2,1) DEFAULT 4.5 CHECK (rating >= 0 AND rating <= 5),
  reviews INTEGER DEFAULT 0,
  address TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  description TEXT DEFAULT '',
  discount TEXT DEFAULT '',
  open_time TEXT DEFAULT '',
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "所有人可查看" ON merchants FOR SELECT USING (true);
CREATE POLICY "登录用户可管理" ON merchants FOR ALL USING (auth.role() = 'authenticated');

-- 4. 成功案例表
CREATE TABLE success_stories (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  people INTEGER DEFAULT 0,
  category TEXT DEFAULT 'meishi',
  summary TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE success_stories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "所有人可查看" ON success_stories FOR SELECT USING (true);
CREATE POLICY "登录用户可管理" ON success_stories FOR ALL USING (auth.role() = 'authenticated');

-- 5. 用户收藏表
CREATE TABLE user_favorites (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_id BIGINT NOT NULL REFERENCES pinke_activities(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, activity_id)
);
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "只能操作自己的收藏" ON user_favorites FOR ALL USING (auth.uid() = user_id);

-- 6. 用户参与记录表
CREATE TABLE user_joins (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_id BIGINT NOT NULL REFERENCES pinke_activities(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, activity_id)
);
ALTER TABLE user_joins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "只能操作自己的参与" ON user_joins FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX idx_activities_category ON pinke_activities(category);
CREATE INDEX idx_activities_status ON pinke_activities(status);
CREATE INDEX idx_activities_created ON pinke_activities(created_at DESC);
CREATE INDEX idx_merchants_category ON merchants(category);
CREATE INDEX idx_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_joins_user ON user_joins(user_id);

-- ============================================================
-- 示例数据（可选，建议执行以便网站有初始内容）
-- ============================================================

INSERT INTO pinke_activities (title, category, price, original_price, min_people, current_people, deadline, location, description, status, organizer, phone) VALUES
('周末椒江海门老街美食探秘之旅', 'meishi', 68, 128, 6, 4, '2026-10-18', '椒江区·海门老街', '一起探访海门老街最地道的台州小吃，姜汤面、食饼筒、麦虾，品尝正宗台州味道！包含6家老字号小吃品鉴。', 'hot', '吃货小分队', '138****6789'),
('神仙居秋日红叶徒步拼团', 'lvyou', 158, 268, 10, 7, '2026-10-20', '仙居县·神仙居景区', '金秋十月神仙居红叶季，一起徒步穿越中国最美火山流纹岩地貌，赏如意桥、观云海仙境。含门票+索道+导游。', 'hot', '户外达人阿杰', '139****2345'),
('天台山国清寺禅修体验一日', 'lvyou', 99, 180, 8, 5, '2026-10-22', '天台县·国清寺', '远离喧嚣，在天台山国清寺体验一日禅修，品素斋、听经文、赏千年古刹银杏，修身养性。', 'new', '静心居士', '137****8901'),
('临海紫阳古街摄影采风团', 'yule', 45, 80, 5, 3, '2026-10-25', '临海市·紫阳古街', '千年紫阳古街，保存最完整的古街之一。一起拍摄古街建筑、人文风情，交流摄影技巧。', 'normal', '光影猎手', '136****5678'),
('路桥小商品市场双十一拼单', 'gouwu', 0, 0, 20, 12, '2026-11-05', '路桥区·小商品批发市场', '双十一前路桥小商品市场大清仓！一起拼单享受批发价，日用百货、服装鞋帽应有尽有。', 'hot', '省钱达人小王', '135****4321'),
('温岭石塘海边日出露营', 'lvyou', 120, 200, 6, 6, '2026-10-19', '温岭市·石塘渔村', '在千年曙光首照地看日出！石塘海边露营一晚，观星、听海、等日出，难忘的体验。含帐篷+早餐。', 'full', '海风露营社', '158****7890'),
('黄岩蜜橘采摘亲子游', 'qinzi', 78, 128, 8, 5, '2026-11-10', '黄岩区·蜜橘果园', '带娃体验黄岩蜜橘采摘乐趣！了解蜜橘种植知识，亲子互动游戏，还有橘子手工DIY。含5斤蜜橘。', 'new', '快乐妈妈团', '133****6543'),
('台州湾新区篮球友谊赛', 'jianshen', 30, 50, 10, 8, '2026-10-17', '椒江区·台州湾体育中心', '召集篮球爱好者，5V5全场友谊赛，以球会友。含场地费+饮用水+裁判。', 'normal', '篮球兄弟连', '188****3210'),
('三门青蟹宴·海鲜吃到饱', 'meishi', 198, 358, 8, 6, '2026-10-21', '三门县·蛇蟠岛', '正宗三门青蟹季来了！蛇蟠岛渔家乐海鲜宴，青蟹、望潮、弹涂鱼、各类贝壳，吃到扶墙出。', 'hot', '海鲜控联盟', '159****8765'),
('台州图书馆读书分享会', 'xuexi', 0, 0, 15, 9, '2026-10-26', '椒江区·台州市图书馆', '每月一期读书分享会，本月主题：《台州府城文化》。免费参与，赠送书签+咖啡。', 'new', '书香台州', '177****4567'),
('玉环漩门湾湿地骑行', 'jianshen', 55, 90, 10, 4, '2026-10-23', '玉环市·漩门湾湿地公园', '环漩门湾湿地骑行，全程约25公里，沿途欣赏湿地风光和候鸟栖息地。含自行车租赁+补给。', 'normal', '骑行台州', '182****9012'),
('椒江万达亲子手工DIY', 'qinzi', 35, 60, 6, 2, '2026-10-16', '椒江区·万达广场', '周末亲子时光，一起做陶艺/烘焙/花艺（三选一），锻炼孩子动手能力，成品可带走。', 'new', '巧手妈妈', '155****3456');

INSERT INTO merchants (name, category, rating, reviews, address, phone, description, discount, open_time, tags) VALUES
('海门老街姜汤面馆', 'meishi', 4.8, 256, '椒江区海门老街88号', '0576-8888****', '三代传承的姜汤面老店，台州非物质文化遗产美食。招牌姜汤面、食饼筒远近闻名。', '拼客专享9折', '07:00-21:00', ARRAY['老字号','非遗美食','堂食']),
('仙居神仙居民宿·云栖', 'lvyou', 4.9, 189, '仙居县白塔镇神仙居景区入口', '0576-7777****', '位于神仙居景区入口的精品民宿，推窗见山，云海日出尽收眼底。提供接送服务和景区导览。', '拼客住宿减50元/间', '全天', ARRAY['景区民宿','山景房','接送服务']),
('三门蛇蟠岛渔家乐·老船长', 'meishi', 4.7, 342, '三门县蛇蟠岛码头旁', '0576-6666****', '自家渔船直供海鲜，三门青蟹、望潮、大黄鱼现捞现做，海景包厢可容纳20人聚餐。', '拼客满8人送青蟹2只', '10:30-21:30', ARRAY['海鲜','渔家乐','海景包厢']),
('台州湾体育中心', 'jianshen', 4.5, 178, '椒江区台州湾新区体育路1号', '0576-8800****', '台州最新综合体育场馆，含篮球、羽毛球、游泳、健身等场地，设施一流。', '拼客团体票7折', '06:00-22:00', ARRAY['综合体育','篮球','游泳']),
('黄岩蜜橘庄园', 'qinzi', 4.6, 134, '黄岩区头陀镇蜜橘大道', '0576-5555****', '200亩有机蜜橘种植园，可体验采摘、了解蜜橘文化，设有儿童游乐区和亲子活动区。', '拼客亲子套餐减20元', '08:00-17:00', ARRAY['采摘','亲子','有机']),
('临海紫阳书院', 'xuexi', 4.8, 97, '临海市紫阳古街南端', '0576-5500****', '千年古街中的文化空间，提供茶道、书法、国画等传统文化体验课程。', '拼客体验课8折', '09:00-18:00', ARRAY['文化体验','书法','茶道']),
('温岭石塘·海风帐篷营地', 'lvyou', 4.7, 213, '温岭市石塘镇千年曙光园旁', '0576-6600****', '面朝大海的露营基地，提供专业帐篷装备、烧烤食材和篝火晚会组织服务。', '拼客团购每人减30元', '14:00-次日11:00', ARRAY['露营','海景','烧烤']),
('路桥小商品城·惠购中心', 'gouwu', 4.3, 456, '路桥区银安街小商品批发市场B区', '0576-2222****', '路桥最大的小商品批发零售中心，日用百货、服装鞋帽、家居用品一站式采购。', '拼客满200减30', '08:30-17:30', ARRAY['批发','百货','一站式']);

INSERT INTO success_stories (title, date, people, category, summary) VALUES
('50人三门青蟹节圆满收官', '2026-09-28', 50, 'meishi', '来自台州各县区的50位拼友齐聚三门蛇蟠岛，品尝了超过200斤三门青蟹，还组织了海鲜知识竞答和沙滩排球赛，活动好评率100%。'),
('天台山赏秋徒步·68人同行', '2026-09-15', 68, 'lvyou', '68位户外爱好者从华顶国家森林公园出发，穿越琼台仙谷，全程12公里。沿途秋色斑斓，欢声笑语不断。'),
('临海紫阳古街亲子汉服游', '2026-09-01', 35, 'qinzi', '35组家庭穿汉服游古街，体验了射艺、投壶、糖画等传统游戏，孩子们玩得不亦乐乎。'),
('台州湾骑行挑战赛', '2026-08-20', 120, 'jianshen', '120位骑友完成50公里环湾骑行，最快纪录1小时32分。沿途补给站和医疗保障完善，零事故完赛。');
