-- ================================================================
-- L3_窗口函数与业务模型.sql —— 简历加分项：留存、RFM、连续活跃、组内TopN、环比
-- 窗口函数是数据分析岗笔试/面试最高频的考点，这一文件全部吃透就超过大多数竞争者
-- 通用语法：函数() OVER (PARTITION BY 分组列 ORDER BY 排序列)
-- ================================================================

-- ---------- Q17. 每日新增用户：每个用户第一次活跃的那天算"新增" ----------
-- 【知识点】ROW_NUMBER() 按用户内时间排序，rn=1 就是首日（也可以直接 MIN(date)）
WITH ud AS (
    SELECT DISTINCT user_id, date FROM user_behavior
),
t AS (
    SELECT user_id, date,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY date) AS rn
    FROM ud
)
SELECT date AS 日期, COUNT(*) AS 新增用户数
FROM t WHERE rn = 1
GROUP BY date ORDER BY date;

-- ---------- Q18. 次日留存率：当天活跃的人，第二天还活跃的比例（北极星指标，必背） ----------
-- 【知识点】去重用户日表自连接 + LEFT JOIN；b 表匹配到 = 次日回来的人
WITH ud AS (
    SELECT DISTINCT user_id, date FROM user_behavior
)
SELECT
    a.date AS 日期,
    COUNT(DISTINCT a.user_id) AS 当日活跃用户,
    COUNT(DISTINCT b.user_id) AS 次日留存用户,
    ROUND(COUNT(DISTINCT b.user_id) * 100.0 / COUNT(DISTINCT a.user_id), 2) AS 次日留存率百分比
FROM ud a
LEFT JOIN ud b
    ON a.user_id = b.user_id
   AND b.date = date(a.date, '+1 day')   -- MySQL 写法：DATE_ADD(a.date, INTERVAL 1 DAY)
GROUP BY a.date ORDER BY a.date;
-- 口径背诵：留存率 = 第N天仍活跃的用户 / 首日新增(或当日活跃)用户，分母口径必须说清楚

-- ---------- Q19. 连续活跃 3 天及以上的用户（经典"连续登录"问题） ----------
-- 【知识点】岛屿法：日期 - 行号 = 常数，同一连续段内这个常数相同
WITH ud AS (
    SELECT DISTINCT user_id, date FROM user_behavior
),
t1 AS (
    SELECT user_id, date,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY date) AS rn
    FROM ud
),
t2 AS (
    -- 连续日期里，date 减 rn 得到的值相同，用它给每个"连续段"编号
    SELECT user_id, date, date(date, '-' || rn || ' day') AS grp
    FROM t1
)
SELECT user_id AS 用户ID, grp AS 连续段起点, COUNT(*) AS 连续活跃天数
FROM t2
GROUP BY user_id, grp
HAVING COUNT(*) >= 3
ORDER BY 连续活跃天数 DESC
LIMIT 20;

-- ---------- Q20. RFM 用户价值分层（本数据集无金额，做 RF 二维分层） ----------
-- 【知识点】NTILE(4) 等频分箱打 1-4 分；R=最近购买距期末天数(越小越好)，F=购买次数(越多越好)
WITH rfm AS (
    SELECT user_id,
           julianday('2017-12-03') - julianday(MAX(date)) AS R,  -- MySQL: DATEDIFF('2017-12-03',MAX(date))
           COUNT(*) AS F
    FROM user_behavior
    WHERE behavior_type = 'buy'
    GROUP BY user_id
),
score AS (
    SELECT user_id, R, F,
           NTILE(4) OVER (ORDER BY R ASC)  AS R_score,  -- R 越小分数越高
           NTILE(4) OVER (ORDER BY F DESC) AS F_score   -- F 越大分数越高
    FROM rfm
)
SELECT
    CASE
        WHEN R_score >= 3 AND F_score >= 3 THEN '重要价值用户'
        WHEN R_score <  3 AND F_score >= 3 THEN '重要保持用户'
        WHEN R_score >= 3 AND F_score <  3 THEN '重要发展用户'
        ELSE '一般挽留用户'
    END AS 用户分层,
    COUNT(*) AS 用户数,
    ROUND(AVG(F), 2) AS 层内平均购买次数
FROM score
GROUP BY 用户分层
ORDER BY 用户数 DESC;
-- 面试讲法：RFM 是用户运营最经典模型，R近度、F频度、M额度；本数据无支付金额所以只做RF，
-- 并主动说明"如果有订单金额表 JOIN 进来就能补全 M"，体现你知道模型全貌

-- ---------- Q21. 组内 TopN：每个类目下购买量前 3 的商品（ROW_NUMBER 经典题） ----------
WITH base AS (
    SELECT category_id, item_id, COUNT(*) AS buy_cnt
    FROM user_behavior
    WHERE behavior_type = 'buy'
    GROUP BY category_id, item_id
),
ranked AS (
    SELECT category_id, item_id, buy_cnt,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY buy_cnt DESC) AS rn
    FROM base
)
SELECT * FROM ranked WHERE rn <= 3
ORDER BY category_id, rn
LIMIT 30;
-- 必背三者区别：ROW_NUMBER 不重复连续编号；RANK 并列后跳号(1,1,3)；DENSE_RANK 并列不跳号(1,1,2)

-- ---------- Q22. 日活环比增长率（LAG 取上一行） ----------
WITH daily AS (
    SELECT date, COUNT(DISTINCT user_id) AS uv
    FROM user_behavior GROUP BY date
)
SELECT date AS 日期, uv AS 当日UV,
       LAG(uv) OVER (ORDER BY date) AS 前一日UV,
       ROUND((uv - LAG(uv) OVER (ORDER BY date)) * 100.0
             / LAG(uv) OVER (ORDER BY date), 2) AS 环比增长率百分比
FROM daily ORDER BY date;
-- 对比记忆：LAG 向上取第N行，LEAD 向下取；同属窗口函数，不会改变行数

-- ---------- Q23. 累计购买用户数（累计求和，窗口版 ORDER BY 的移动窗口） ----------
WITH daily AS (
    SELECT date, COUNT(DISTINCT user_id) AS 当日购买人数
    FROM user_behavior WHERE behavior_type='buy' GROUP BY date
)
SELECT date, 当日购买人数,
       SUM(当日购买人数) OVER (ORDER BY date) AS 累计购买用户
FROM daily ORDER BY date;
