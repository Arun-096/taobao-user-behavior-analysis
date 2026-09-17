-- =============================================================
-- L2 练习题（进阶：子查询/CTE/JOIN/业务指标，手撕高频区）
-- 对答案：sql/L2_进阶查询.sql
-- =============================================================

-- Q10. 转化漏斗：浏览人数、收藏/加购人数、购买人数，以及三个转化率（%，2位小数）
--      浏览->收藏加购、浏览->购买、收藏加购->购买
-- 考点：WITH(CTE)、CASE WHEN 行转列、COUNT(DISTINCT CASE WHEN...)
-- 自检：浏览 10000、收藏加购 5526、购买 2332，浏览->购买 ≈ 23.32%
-- 先回答口径问题（写注释）：为什么分母用"人数"而不是"次数"？
/* 写在这里 */
WITH funnel AS (
	SELECT
		COUNT(DISTINCT CASE WHEN mc.behavior_type = 'pv' THEN user_id END) AS "浏览人数",
		COUNT(DISTINCT CASE WHEN mc.behavior_type IN ('fv','cart')  THEN user_id END) AS "收藏/加购人数",
		COUNT(DISTINCT CASE WHEN mc.behavior_type = 'buy' THEN user_id END) AS "购买人数"
	FROM my_clean mc 
)
SELECT
	"浏览人数","收藏/加购人数","购买人数",
	ROUND("收藏/加购人数" * 100.0 / "浏览人数", 2) AS "浏览到收藏加购转化率(%)",
	ROUND("购买人数" * 100.0 / "浏览人数", 2) AS "浏览到购买转化率(%)",
	ROUND("购买人数" * 100.0 / "收藏/加购人数" , 2) AS "收藏加购到购买转化率"
FROM funnel;
	
-- Q11. 复购率：购买>=2次的用户占全部购买用户的比例（%）
-- 思路提示：先 GROUP BY 用户数购买次数，外层再算比例
-- 自检：复购率 ≈ 100%（演示数据特征，每个购买用户均有多次购买）
/* 写在这里 */
WITH buy_cnt AS(
	SELECT
		user_id,
		COUNT(*) AS cnt
	FROM my_clean mc 
	WHERE mc.behavior_type = 'buy'
	GROUP BY user_id
)
SELECT
	COUNT(*) AS "购买用户数",
	SUM(CASE WHEN cnt >= 2 THEN 1 ELSE 0 END) AS "复购用户数",
	ROUND(SUM(CASE WHEN cnt >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) ,2) AS "复购率(%)"
FROM buy_cnt;
	

-- Q12. 跳失率前置：统计"只有 pv、没有 fav/cart/buy"的用户数
-- 要求：用 NOT IN 子查询写一版，再用 LEFT JOIN ... IS NULL 写第二版
/* 版本A 写在这里 */
SELECT
	COUNT(DISTINCT user_id) AS "仅浏览用户数" 
FROM my_clean mc 
WHERE mc.behavior_type = 'pv'
	AND user_id NOT IN(
	SELECT
		DISTINCT user_id 
	FROM my_clean mc2
	WHERE behavior_type <> 'pv');
	

/* 版本B 写在这里 */
SELECT COUNT(*) AS "仅浏览用户数"
FROM (SELECT DISTINCT mc.user_id FROM my_clean mc WHERE mc.behavior_type = 'pv')  a
LEFT JOIN 
	(SELECT DISTINCT mc2.user_id FROM my_clean mc2 WHERE mc2.behavior_type <> 'pv')  b
ON a.user_id = b.user_id
WHERE b.user_id IS NULL;

-- Q13. INNER JOIN：列出"既浏览过也购买过"的用户，附浏览数和购买数，按购买数降序取20
-- 思路：把同一张表按 pv、buy 拆成两个 CTE，再 ON user_id 内连接
/* 写在这里 */
SELECT
	a.user_id AS "浏览+购买过的用户",
	a.pv_cnt AS "浏览数",
	b.buy_cnt AS "购买数"
FROM (SELECT  
		mc.user_id,
		COUNT(*) AS pv_cnt
		FROM my_clean mc 
		WHERE mc.behavior_type = 'pv' 
		GROUP BY mc.user_id) a
INNER JOIN 
	(SELECT 
		mc2.user_id,
		COUNT(*) AS buy_cnt
		FROM my_clean mc2 
		WHERE mc2.behavior_type = 'buy'
		GROUP BY mc2.user_id) b
ON a.user_id = b.user_id
ORDER BY b.buy_cnt DESC 
LIMIT 20;

-- Q14. 用户购买次数分布：买1次/2次/3次...各有多少用户（分组结果再分组）
/* 写在这里 */
WITH funnel AS (
	SELECT 
		mc.user_id,
		COUNT(*) AS buy_cnt
	FROM my_clean mc 
	WHERE mc.behavior_type = 'buy'
	GROUP BY mc.user_id
	)
SELECT
	buy_cnt AS "购买次数",
	COUNT(*) AS "用户数量" 
FROM funnel
GROUP BY buy_cnt
ORDER BY buy_cnt;

-- Q15. 每个类目的浏览人数、购买人数、类目转化率(%)，只看浏览人数>50的类目，按转化率降序取20
-- 考点：一次扫描的条件聚合；HAVING 过滤小样本
/* 写在这里 */
SELECT 
	mc.category_id ,
	COUNT(DISTINCT CASE WHEN mc.behavior_type = 'pv' THEN user_id END) AS "浏览人数",
	COUNT(DISTINCT CASE WHEN mc.behavior_type = 'buy' THEN user_id END) AS "购买人数",
	ROUND(COUNT(DISTINCT CASE WHEN mc.behavior_type = 'buy' THEN user_id END) * 100.0 / COUNT(DISTINCT CASE WHEN mc.behavior_type = 'pv' THEN user_id END),2) AS "类目转化率"
FROM my_clean mc 
WHERE mc.behavior_type IN ('pv','buy')
GROUP BY mc.category_id 
HAVING COUNT(DISTINCT CASE WHEN mc.behavior_type = 'pv' THEN user_id END) > 50
ORDER BY "类目转化率" DESC 
LIMIT 20;
 
-- Q16. 工作日 vs 周末 的 UV、PV 对比
-- 提示：SQLite 用 strftime('%w',date)，'0'和'6' 是周末；MySQL 用 WEEKDAY()
/* 写在这里 */
SELECT
	CASE WHEN strftime('%w',date) IN('0','6') THEN "周末" ELSE "工作日" END AS "日期类型", 	
	COUNT(*) AS "PV",
	COUNT(DISTINCT user_id) AS "UV" 
FROM my_clean mc 
WHERE mc.behavior_type = 'pv'
GROUP BY 
	CASE WHEN strftime('%w',date) IN('0','6') THEN "周末" ELSE "工作日" END;


