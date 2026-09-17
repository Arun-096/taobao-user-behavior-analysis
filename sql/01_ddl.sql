-- =============================================================
-- 01_ddl_练习.sql  —— 自己写建表语句
-- 对答案：taobao-user-behavior-analysis/sql/01_ddl.sql
-- =============================================================

-- 【任务1】建表 user_behavior，共 7 列，先自己想每列该用什么类型：
--   user_id(用户ID)、item_id(商品ID)、category_id(类目ID)、
--   behavior_type(行为,文本)、ts(秒级时间戳)、date(日期文本)、hour(小时)
-- 写在这里：
CREATE TABLE IF NOT EXISTS user_behavior (
	user_id INTEGER
	item_id INTEGER
	category_id INTEGER
	bahavior_type TEXT
	ts INTEGER
	date TEXT
	hour INTEGER)

-- 【任务2】给高频查询字段建 3 个索引（想想为什么是这三个字段）：
CREATE INDEX IF NOT EXISTS idx_user ON user_behavior(user_id);
CREATE INDEX IF NOT EXISTS idx_date ON user_behavior(date);
CREATE INDEX IF NOT EXISTS idx_behavior ON user_behavior(behavior_type);

-- 【任务3】用自己的话回答（写注释）：
--   a. 为什么 id 用 INTEGER 而不是 TEXT？
--   b. 索引有什么代价，为什么不是每列都建？
/** a : id是数字编号，用INTEGER查询速度更快，占用存储空间更小；如果使用TEXT文本，存储开销更大，效率会更低。
 *  b : 索引会额外占用磁盘空间，每次更新数据时，数据库需要同步更新所有相关索引，写入速度会更慢。
