-- =============================================================
-- L1 基础查询：分组聚合与统计分析
-- =============================================================

-- Q1. 统计：总记录数、去重用户数、去重商品数、去重类目数（各起中文别名）
-- 考点：COUNT(*) 与 COUNT(DISTINCT 列) 的区别
-- 自检：总记录数应 = 282769，用户数 = 10000
/* 写在这里 */
SELECT 
	COUNT(*) AS "总记录数",
	COUNT(DISTINCT mc.user_id) AS "用户数",
	COUNT(DISTINCT mc.item_id) AS "商品数",
	COUNT(DISTINCT mc.category_id) AS "类目数" 
FROM my_clean mc ;
 
-- Q2. 统计四种行为各自的次数和占比（%，保留2位小数），按次数降序
-- 考点：GROUP BY；占比需要子查询先拿总数
-- 自检：pv 应为 265656（约 93.95%）
/* 写在这里 */
SELECT 
	mc.behavior_type AS "行为类型",
	COUNT(*) AS "次数",
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM my_clean), 2) AS "占比（%）"
FROM my_clean mc 
GROUP BY mc.behavior_type 
ORDER BY "次数" DESC ;
	

-- Q3. 每天的 PV（=行为总次数），按日期升序
/* 写在这里 */
SELECT
	date,
	COUNT(*) AS PV
FROM my_clean mc 
GROUP BY date 
ORDER BY date ASC;

-- Q4. 每天的 UV（=去重用户数）
/* 写在这里 */
SELECT 
	mc.date,
	COUNT(DISTINCT mc.user_id) AS "UV"
FROM my_clean mc 
GROUP BY date 
ORDER BY date ASC;


-- Q5. 一张表同时出：每天 PV、UV、人均访问次数(PV/UV，保留2位)
-- 自检：每天 UV 约 5800 左右
/* 写在这里 */
SELECT 
	mc.date,
	COUNT(*) AS PV,
	COUNT(DISTINCT mc.user_id) AS UV,
	ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT mc.user_id),2) AS "人均访问次数"
FROM my_clean mc 
GROUP BY date 
ORDER BY date ASC;

-- Q6. 每个小时(0-23)的 PV 和 UV，按小时升序（做完观察几点是高峰）
/* 写在这里 */
SELECT 
	mc.hour,
	COUNT(*) AS PV,
	COUNT(DISTINCT mc.user_id) AS UV
FROM my_clean mc 
GROUP BY hour 
ORDER BY hour;
	
-- Q7. 浏览(pv)次数最多的 10 个商品，显示商品ID和次数
-- 考点：WHERE + GROUP BY + ORDER BY + LIMIT 的组合顺序
/* 写在这里 */
SELECT 
	mc.item_id ,
	COUNT(*) AS PV
FROM my_clean mc 
WHERE mc.behavior_type = 'pv' 
GROUP BY mc.item_id 
ORDER BY PV DESC 
LIMIT 10;

-- Q8. 每个用户的 pv 次数，只保留浏览超过 60 次的"重度用户"，降序
-- 考点：为什么这里必须用 HAVING 而不能用 WHERE？（在注释里回答）
/* 写在这里 */
SELECT 
	mc.user_id ,
	COUNT(*) AS "浏览次数"
FROM my_clean mc 
WHERE mc.behavior_type = 'pv' 
GROUP BY mc.user_id
HAVING COUNT(*) > 60
ORDER BY "浏览次数" DESC;


-- Q9. 每个类目的【购买人数】和【购买次数】，取前 20
/* 写在这里 */
SELECT
	mc.category_id ,
	COUNT(*) AS "购买次数",
	COUNT(DISTINCT user_id) AS "购买人数"
FROM my_clean mc 
WHERE mc.behavior_type = 'buy'
GROUP BY mc.category_id 
ORDER BY "购买人数" DESC
LIMIT 20;