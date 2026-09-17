# -*- coding: utf-8 -*-
"""
01_clean_data.py — 淘宝用户行为数据清洗
数据来源：天池 UserBehavior 公开数据集
处理流程：缺失值处理 → 去重 → 行为类型过滤 → 时间戳转换 → 时间范围过滤 → 衍生字段
输出：data/my_clean.csv
"""
import os
from numpy._core.numeric import int64
import pandas as pd

BASE = os.path.join(os.path.dirname(__file__), "..")
RAW = os.path.join(BASE, "data", "user_behavior_raw.csv")
OUT = os.path.join(BASE, "data", "my_clean.csv")


def main():
    # 读取原始数据（无表头，手动指定列名）
    df = pd.read_csv(RAW, names=["user_id", "item_id", "category_id", "behavior_type", "ts"])
    print("原始数据行数:", len(df))

    # 删除含空值的行（空字符串视为缺失）
    df = df.dropna()
    df = df.replace("", pd.NA).dropna()
    print("删除空值后:", len(df))

    # 删除完全重复的记录
    df = df.drop_duplicates()
    print("去重后:", len(df))

    # 只保留合法行为类型：pv浏览、fav收藏、cart加购、buy购买
    VALID_BEHAVIOR = {"pv", "fav", "cart", "buy"}
    df = df[df["behavior_type"].isin(VALID_BEHAVIOR)]
    print("过滤非法行为后:", len(df))

    # 秒级时间戳转换为东八区时间
    df["dt"] = pd.to_datetime(df["ts"].astype('int64'), unit='s', utc=True) \
        .dt.tz_convert('Asia/Shanghai').dt.tz_localize(None)

    # 过滤时间范围：2017-11-25 至 2017-12-03
    df = df[(df["dt"] >= '2017-11-25') & (df["dt"] <= '2017-12-03 23:59:59')]
    print("过滤时间范围后:", len(df))

    # 衍生日期和小时字段
    df['date'] = df["dt"].dt.date.astype(str)
    df['hour'] = df["dt"].dt.hour

    # ID列转为整数类型
    for col in ['user_id', 'item_id', 'category_id']:
        df[col] = df[col].astype('int64')

    # 按指定列顺序导出
    df = df[['user_id', 'item_id', 'category_id', 'behavior_type', 'ts', 'date', 'hour']]
    df.to_csv(OUT, index=False, encoding='utf-8')
    print("清洗完成，最终行数:", len(df))
    print("行为分布:\n", df['behavior_type'].value_counts())


if __name__ == "__main__":
    main()
