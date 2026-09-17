# -*- coding: utf-8 -*-
"""
02_load_to_db.py —— 清洗后 CSV 入库到 SQLite
做的事：读取 my_clean.csv -> 建表 -> 批量插入 -> 建索引 -> 校验
运行：python src/02_load_to_db.py
前置：先运行 01_clean_data.py 生成 data/my_clean.csv
"""
import os
import sqlite3
import pandas as pd

BASE = os.path.join(os.path.dirname(__file__), "..")
CLEAN = os.path.join(BASE, "data", "my_clean.csv")
DB = os.path.join(BASE, "data", "taobao.db")


def main():
    # 1. 读入清洗好的 CSV
    df_clean = pd.read_csv(CLEAN)
    print("读入数据前五条：")
    print(df_clean.head())

    # 2. 连接 SQLite（文件存在就先删掉，保证脚本可重复执行）
    if os.path.exists(DB):
        os.remove(DB)
    conn = sqlite3.connect(DB)
    cur = conn.cursor()

    # 3. 建表
    cur.execute("""
    CREATE TABLE IF NOT EXISTS user_behavior(
        user_id INTEGER,
        item_id INTEGER,
        category_id INTEGER,
        behavior_type TEXT,
        ts INTEGER,
        date TEXT,
        hour INTEGER
    );
    """)

    # 4. 批量插入数据（executemany 比 for 循环逐条插入快很多）
    records = df_clean.values.tolist()
    cur.executemany("INSERT INTO user_behavior VALUES(?,?,?,?,?,?,?)", records)
    conn.commit()

    # 5. 建索引（加速查询）
    cur.execute("CREATE INDEX idx_user ON user_behavior(user_id);")
    cur.execute("CREATE INDEX idx_date ON user_behavior(date);")
    cur.execute("CREATE INDEX idx_beh ON user_behavior(behavior_type);")
    conn.commit()

    # 6. 入库校验
    print("\n入库校验：")
    print("总行数:", cur.execute("SELECT COUNT(*) FROM user_behavior").fetchone()[0])
    print("用户数:", cur.execute("SELECT COUNT(DISTINCT user_id) FROM user_behavior").fetchone()[0])
    print("\n行为分布：")
    for row in cur.execute("SELECT behavior_type, COUNT(*) FROM user_behavior GROUP BY behavior_type"):
        print(f"  {row[0]}: {row[1]:,}")
    conn.close()
    print(f"\n数据库已保存到：{os.path.abspath(DB)}")


if __name__ == "__main__":
    main()
