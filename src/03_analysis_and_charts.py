# -*- coding: utf-8 -*-
"""
03_analysis_and_charts.py —— Python 连库分析 + Matplotlib 可视化
做的事：连接 SQLite -> 用 pandas 读 SQL 结果 -> 画 6 张图存到 output/ -> 终端打印业务结论
运行：python src/03_analysis_and_charts.py
"""
import os
import sqlite3
import matplotlib
matplotlib.use("Agg")  # 不弹窗、直接存图片
import matplotlib.pyplot as plt
import pandas as pd

# Windows 中文字体，防止图表中文变方块
plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimHei"]
plt.rcParams["axes.unicode_minus"] = False

BASE = os.path.join(os.path.dirname(__file__), "..")
DB = os.path.join(BASE, "data", "taobao.db")
OUT = os.path.join(BASE, "output")
os.makedirs(OUT, exist_ok=True)

conn = sqlite3.connect(DB)


def q(sql):
    """封装：SQL 文本 -> DataFrame"""
    return pd.read_sql(sql, conn)


def main():
    # ---------- 图1：每日 PV / UV 双轴折线 ----------
    daily = q("""
    SELECT date, COUNT(*) AS pv, COUNT(DISTINCT user_id) AS uv
    FROM user_behavior GROUP BY date ORDER BY date
    """)
    fig, ax1 = plt.subplots(figsize=(9, 4.5))
    ax1.plot(daily["date"], daily["pv"], "o-", color="#4C78A8", label="PV")
    ax1.set_ylabel("PV 浏览量", color="#4C78A8")
    ax1.tick_params(axis="x", rotation=45)
    ax2 = ax1.twinx()
    ax2.plot(daily["date"], daily["uv"], "s--", color="#F58518", label="UV")
    ax2.set_ylabel("UV 独立访客", color="#F58518")
    plt.title("每日 PV / UV 趋势")
    fig.tight_layout()
    plt.savefig(os.path.join(OUT, "01_每日PV_UV趋势.png"), dpi=150)
    plt.close()

    # ---------- 图2：24 小时活跃分布 ----------
    hourly = q("""
    SELECT hour, COUNT(*) AS pv, COUNT(DISTINCT user_id) AS uv
    FROM user_behavior GROUP BY hour ORDER BY hour
    """)
    plt.figure(figsize=(9, 4.5))
    plt.bar(hourly["hour"], hourly["pv"], color="#54A24B", alpha=0.85)
    plt.plot(hourly["hour"], hourly["uv"], "o-", color="#E45756")
    plt.xticks(range(0, 24))
    plt.xlabel("小时")
    plt.ylabel("行为次数（柱）/ 活跃用户（线）")
    plt.title("用户活跃时段分布（晚间高峰）")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT, "02_时段活跃分布.png"), dpi=150)
    plt.close()

    # ---------- 图3：转化漏斗 ----------
    funnel = q("""
    WITH f AS (
      SELECT
        COUNT(DISTINCT CASE WHEN behavior_type='pv' THEN user_id END) AS 浏览,
        COUNT(DISTINCT CASE WHEN behavior_type IN ('fav','cart') THEN user_id END) AS 收藏加购,
        COUNT(DISTINCT CASE WHEN behavior_type='buy' THEN user_id END) AS 购买
      FROM user_behavior)
    SELECT * FROM f
    """).iloc[0]
    steps = ["浏览", "收藏加购", "购买"]
    vals = [int(funnel[s]) for s in steps]
    plt.figure(figsize=(8, 4.5))
    plt.barh(steps[::-1], vals[::-1], color=["#E45756", "#F58518", "#4C78A8"])
    for i, v in enumerate(vals[::-1]):
        plt.text(v, i, f" {v:,}", va="center")
    plt.xlabel("独立用户数")
    plt.title("用户行为转化漏斗")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT, "03_转化漏斗.png"), dpi=150)
    plt.close()

    # ---------- 图4：RFM 用户分层 ----------
    rfm_sql = """
    WITH rfm AS (
      SELECT user_id, julianday('2017-12-03')-julianday(MAX(date)) AS R, COUNT(*) AS F
      FROM user_behavior WHERE behavior_type='buy' GROUP BY user_id),
    s AS (
      SELECT user_id,
        NTILE(4) OVER (ORDER BY R ASC)  AS rs,
        NTILE(4) OVER (ORDER BY F DESC) AS fs
      FROM rfm)
    SELECT CASE WHEN rs>=3 AND fs>=3 THEN '重要价值用户'
                WHEN rs<3  AND fs>=3 THEN '重要保持用户'
                WHEN rs>=3 AND fs<3  THEN '重要发展用户'
                ELSE '一般挽留用户' END AS seg,
           COUNT(*) AS cnt
    FROM s GROUP BY seg
    """
    rfm = q(rfm_sql)
    plt.figure(figsize=(7, 6))
    plt.pie(rfm["cnt"], labels=rfm["seg"], autopct="%1.1f%%", startangle=90,
            colors=["#4C78A8", "#F58518", "#54A24B", "#B279A2"])
    plt.title("购买用户 RFM 分层（RF 二维）")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT, "04_RFM用户分层.png"), dpi=150)
    plt.close()

    # ---------- 图5：购买量 Top10 类目 ----------
    top_cat = q("""
    SELECT category_id, COUNT(*) AS buy_cnt FROM user_behavior
    WHERE behavior_type='buy' GROUP BY category_id
    ORDER BY buy_cnt DESC LIMIT 10
    """)
    plt.figure(figsize=(9, 4.5))
    plt.bar(top_cat["category_id"].astype(str), top_cat["buy_cnt"], color="#72B7B2")
    plt.xlabel("类目 ID")
    plt.ylabel("购买次数")
    plt.title("购买次数 Top10 类目")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT, "05_Top10类目.png"), dpi=150)
    plt.close()

    # ---------- 图6：四种行为占比 ----------
    beh = q("SELECT behavior_type, COUNT(*) cnt FROM user_behavior GROUP BY behavior_type")
    name_map = {"pv": "浏览", "fav": "收藏", "cart": "加购", "buy": "购买"}
    beh["name"] = beh["behavior_type"].map(name_map)
    plt.figure(figsize=(7, 6))
    plt.pie(beh["cnt"], labels=beh["name"], autopct="%1.1f%%", startangle=90)
    plt.title("整体行为类型分布")
    plt.tight_layout()
    plt.savefig(os.path.join(OUT, "06_行为分布.png"), dpi=150)
    plt.close()

    # ---------- 终端打印关键结论 ----------
    print("=" * 50)
    print("关键指标结果")
    print("=" * 50)
    total = q("SELECT COUNT(*) c FROM user_behavior").iloc[0, 0]
    users = q("SELECT COUNT(DISTINCT user_id) c FROM user_behavior").iloc[0, 0]
    print(f"总记录数：{total:,}")
    print(f"总用户数：{users:,}")
    print(f"\n每日 PV/UV：")
    print(daily.to_string(index=False))
    print(f"\n转化漏斗：{dict(zip(steps, vals))}")
    print(f"浏览->购买整体转化率：{vals[2]*100/vals[0]:.2f}%")
    repurchase = q("""
    WITH b AS (SELECT user_id, COUNT(*) c FROM user_behavior
               WHERE behavior_type='buy' GROUP BY user_id)
    SELECT ROUND(SUM(CASE WHEN c>=2 THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS repurchase
    FROM b
    """).iloc[0, 0]
    print(f"用户复购率：{repurchase}%")
    print(f"\nRFM 分层：")
    print(rfm.to_string(index=False))
    conn.close()
    print(f"\n6 张图表已保存到：{os.path.abspath(OUT)}")


if __name__ == "__main__":
    main()
