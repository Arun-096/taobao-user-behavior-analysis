# -*- coding: utf-8 -*-
"""
01_clean_练习.py —— 自己写 Pandas 清洗的地方
验收目标：清洗后 282769 行（和标准答案一致），输出 data/my_clean.csv
卡住允许查：pandas 文档（read_csv/dropna/drop_duplicates/isin/to_datetime）
做完再对：taobao-user-behavior-analysis/src/01_clean_data.py
"""
import os
from numpy._core.numeric import int64
import pandas as pd

BASE = os.path.join(os.path.dirname(__file__), "..")
RAW = os.path.join(BASE, "data", "user_behavior_raw.csv")
OUT = os.path.join(BASE, "data", "my_clean.csv")


def main():
    # TODO 1：读入 RAW。注意：原始数据【没有表头】，用 names 参数手动指定 5 个列名：
    #         user_id, item_id, category_id, behavior_type, ts
    # df = ?
    df = pd.read_csv(RAW,names=["user_id","item_id","category_id","behavior_type","ts"])

    # TODO 2：打印原始行数 print(len(df))
    print("原始行数为:",df.shape)

    # TODO 3：删除含空值的行（注意空字符串 "" 也算空，先 replace 成 NA 再 dropna）
    df = df.dropna()
    df = df.replace("",pd.NA).dropna()
    print("删除了含空值的行后:",df.shape)

    # TODO 4：删除完全重复的行
    df = df.drop_duplicates()
    print("去掉重复行后:",df.shape)

    # TODO 5：只保留合法行为 {'pv','fav','cart','buy'}（提示：Series.isin）
    VALIED_BEHAVIOR = {"pv","fav","cart","buy"}
    df = df[df["behavior_type"].isin(VALIED_BEHAVIOR)]
    print("过滤非法行为后:",df.shape)

    # TODO 6：ts 是【秒级时间戳】，转成东八区时间，列名叫 dt
    #         提示：pd.to_datetime(..., unit='s', utc=True).dt.tz_convert('Asia/Shanghai')
    df["dt"] = pd.to_datetime(df["ts"].astype('int64'),unit = 's',utc=True).dt.tz_convert('Asia/Shanghai').dt.tz_localize(None)

    # TODO 7：只保留 2017-11-25 ~ 2017-12-03 之间的数据（过滤异常时间）
    df = df[(df["dt"] >= '2017-11-25') & (df["dt"] <= '2017-12-03 23:59:59')]
    print("过滤时间范围后：",df.shape)

    # TODO 8：从 dt 衍生两列：date(日期字符串)、hour(整数小时)
    #         提示：dt.dt.date、dt.dt.hour
    df['date'] = df["dt"].dt.date.astype(str)
    df['hour'] = df["dt"].dt.hour

    # TODO 9：把三个 id 列转成 int64；按下面顺序选列并导出 OUT（index=False）
    #         user_id,item_id,category_id,behavior_type,ts,date,hour
    for col in ['user_id','item_id','category_id']:
        df[col] = df[col].astype('int64')
    

    # TODO 10：打印每一步之后的行数、最终 behavior_type 的 value_counts()
    #          最终应为 282769 行：pv 265656 / cart 7762 / buy 4284 / fav 5067
    df = df[['user_id','item_id','category_id','behavior_type','ts','date','hour']]
    df.to_csv(OUT,index=False,encoding='utf-8')
    print(df.shape)



if __name__ == "__main__":
    main()
