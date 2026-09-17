-- =============================================================
-- 建表语句：用户行为表结构与索引
-- =============================================================

-- 建表 user_behavior，共 7 列
-- user_id(用户ID)、item_id(商品ID)、category_id(类目ID)、
-- behavior_type(行为,文本)、ts(秒级时间戳)、date(日期文本)、hour(小时)
CREATE TABLE IF NOT EXISTS user_behavior (
	user_id INTEGER,
	item_id INTEGER,
	category_id INTEGER,
	behavior_type TEXT,
	ts INTEGER,
	date TEXT,
	hour INTEGER
);

-- 给高频查询字段建索引：user_id、date、behavior_type
CREATE INDEX IF NOT EXISTS idx_user ON user_behavior(user_id);
CREATE INDEX IF NOT EXISTS idx_date ON user_behavior(date);
CREATE INDEX IF NOT EXISTS idx_behavior ON user_behavior(behavior_type);
