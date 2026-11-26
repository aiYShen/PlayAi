-- psql -U root -P ******* -d postgres -h 127.0.0.1 -p *****
-- \l ：列出所有数据库
-- \c database_name ：切换到指定数据库
-- \dt ：列出当前数据库中的所有表
-- \d table_name ：查看指定表的结构（字段、类型、约束、索引）
-- \du ：列出所有用户及角色权限
-- \i /path/to/file.sql ：执行外部 SQL 脚本文件
-- \timing ：开启/关闭 SQL 执行时间统计
-- \q ：退出 psql 终端

-- 1. 查看当前会话时区
SHOW TIME ZONE;
SELECT name, setting, source, sourcefile, sourceline
FROM pg_settings
WHERE name IN ('timezone', 'log_timezone');

-- 2. 查看当前带时区的时间与显式转成 Asia/Shanghai 的时间
SELECT NOW()                                          AS now_with_tz,
       LOCALTIMESTAMP                                 AS local_ts_without_tz,
       CURRENT_TIMESTAMP AT TIME ZONE 'UTC'           AS utc_time,
       CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai' AS shanghai_time;

-- 修改时区
ALTER SYSTEM SET timezone = 'Asia/Shanghai';
SELECT pg_reload_conf();

-- 将 mydb 替换为你的实际数据库名
ALTER DATABASE public SET timezone TO 'Asia/Shanghai';
RESET TIME ZONE;
SELECT NOW();

-- 建库
CREATE DATABASE public
    WITH OWNER = root
    ENCODING = 'UTF8';
-- 重命名数据库名称
-- ALTER DATABASE public RENAME TO public_new;
-- 删库
-- DROP DATABASE IF EXISTS public;

--建表
-- DROP TABLE IF EXISTS public.user;
CREATE TABLE public.user
(
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(50)  NULL DEFAULT NULL,
    card_num    varchar(18)  NULL DEFAULT NULL,
    sex         varchar(2)   NULL DEFAULT NULL,
    age         INT CHECK (age >= 0),
    address     varchar(100) NULL DEFAULT NULL,
    birthday    date         NULL DEFAULT NULL,
    phone       varchar(20)  NULL DEFAULT NULL,
    email       varchar(50)  NULL DEFAULT NULL,
    keywords    varchar(50)  NULL DEFAULT NULL,
    profile     JSONB,
    create_time TIMESTAMPTZ       DEFAULT CURRENT_TIMESTAMP
);

-- 唯一索引
CREATE INDEX idx_users_email ON public.user (email);
-- GIN 索引（专为 JSONB、数组、全文检索优化）
CREATE INDEX idx_users_profile_gin ON public.user USING GIN (profile);
-- 在线创建索引(不锁表写入)
CREATE INDEX CONCURRENTLY idx_user_id ON public.user (id);

-- 添加字段说明
COMMENT ON TABLE public.user IS '用户信息表';
COMMENT ON COLUMN public.user.id IS '主键ID';
COMMENT ON COLUMN public.user.name IS '姓名';
COMMENT ON COLUMN public.user.card_num IS '证件号';
COMMENT ON COLUMN public.user.sex IS '性别';
COMMENT ON COLUMN public.user.age IS '年龄';
COMMENT ON COLUMN public.user.address IS '地址';
COMMENT ON COLUMN public.user.birthday IS '出生日期';
COMMENT ON COLUMN public.user.phone IS '电话';
COMMENT ON COLUMN public.user.email IS '邮箱';
COMMENT ON COLUMN public.user.keywords IS '关键字';
COMMENT ON COLUMN public.user.profile IS 'json文件';
COMMENT ON COLUMN public.user.create_time IS '创建日期';

-- 添加字段
ALTER TABLE public.user
    ADD COLUMN phone VARCHAR(20);
-- 修改字段类型
ALTER TABLE public.user
    ALTER COLUMN phone TYPE VARCHAR(30);
-- 重命名字段
ALTER TABLE public.user
    RENAME COLUMN phone TO mobile;
-- 删除字段
ALTER TABLE public.user
    DROP COLUMN IF EXISTS mobile;
-- 清空表数据并重置自增 ID
TRUNCATE TABLE public.user RESTART IDENTITY;
TRUNCATE TABLE public.user_asset, public.user RESTART IDENTITY;
-- 删除表（CASCADE 会级联删除依赖此表的视图/外键）
-- DROP TABLE IF EXISTS public.user CASCADE;

-- 1. 创建资产表
CREATE TABLE public.user_asset
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT         NOT NULL,
    asset_code  VARCHAR(32)    NOT NULL,
    asset_type  VARCHAR(20)    NOT NULL CHECK (asset_type IN ('DEPOSIT', 'STOCK', 'FUND', 'REAL_ESTATE', 'OTHER')),
    asset_name  VARCHAR(100)   NOT NULL,
    cost_amount NUMERIC(18, 2) NOT NULL DEFAULT 0.00 CHECK (cost_amount >= 0),
    curr_value  NUMERIC(18, 2) NOT NULL DEFAULT 0.00 CHECK (curr_value >= 0),
    status      VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'SOLD')),
    meta        JSONB                   DEFAULT '{}'::JSONB,
    acquired_at DATE           NOT NULL DEFAULT CURRENT_DATE,
    create_time TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- 外键约束：用户删除时级联清理资产（生产环境通常视业务改为 RESTRICT 或软删）
    CONSTRAINT fk_user_asset_user
        FOREIGN KEY (user_id) REFERENCES public.user (id) ON DELETE CASCADE
);

-- 创建常用索引（优化 JOIN、过滤与 JSONB 查询）
CREATE INDEX idx_user_asset_user_id ON public.user_asset (user_id);
CREATE INDEX idx_user_asset_type_status ON public.user_asset (asset_type, status);
CREATE INDEX idx_user_asset_meta_gin ON public.user_asset USING GIN (meta);

-- 表及逐字段注释
COMMENT ON TABLE public.user_asset IS '用户资产表';
COMMENT ON COLUMN public.user_asset.id IS '主键ID，自增标识';
COMMENT ON COLUMN public.user_asset.user_id IS '关联用户ID，外键引用 public.user.id';
COMMENT ON COLUMN public.user_asset.asset_code IS '资产业务编码';
COMMENT ON COLUMN public.user_asset.asset_type IS '资产类型：DEPOSIT存款, STOCK股票, FUND基金, REAL_ESTATE房产, OTHER其他';
COMMENT ON COLUMN public.user_asset.asset_name IS '资产名称';
COMMENT ON COLUMN public.user_asset.cost_amount IS '资产买入/投入成本金额（元），保留两位小数';
COMMENT ON COLUMN public.user_asset.curr_value IS '资产当前估值/市值（元），保留两位小数';
COMMENT ON COLUMN public.user_asset.status IS '资产状态：ACTIVE在持, FROZEN冻结, SOLD已卖出/已清仓';
COMMENT ON COLUMN public.user_asset.meta IS '资产扩展属性（JSONB，如股票代码、持股数、房产城市、月租、利率等）';
COMMENT ON COLUMN public.user_asset.acquired_at IS '资产取得/买入日期';
COMMENT ON COLUMN public.user_asset.create_time IS '记录创建时间（带时区）';

-- 插入
INSERT INTO public.user (name, card_num, sex, age, address, birthday, phone, email, keywords, profile)
VALUES ('*宇', '15***************X', '男', 20, '内蒙古****市**区', '2006-02-18', 18158550101, '78******0@qq.com',
        '帅气', '{}'::JSONB),
       ('*云*', '33***************4', '男', 4, '浙江省**市**区', '2022-10-24', 18158550101, '78******0@qq.com',
        '帅气', '{}'::JSONB),
       ('毛**', '22***************5', '女', 23, '浙江省**市**区', '2003-01-05', 15999998204,
        'ma*******ao0@qq.com', '矫情', '{}'::JSONB),
       ('张三', '110101199001011234', '男', 36, '北京市海淀区', '1990-01-01', '13800138001', 'zhangsan@example.com',
        '稳健,科技', '{
         "vip_level": 3,
         "tags": [
           "高净值",
           "长期投资者"
         ],
         "risk_score": 78
       }'::JSONB),
       ('李四', '310101199505055678', '女', 31, '上海市浦东新区', '1995-05-05', '13800138002', 'lisi@example.com',
        '进取,基金', '{
         "vip_level": 2,
         "tags": [
           "定投用户"
         ],
         "risk_score": 65
       }'::JSONB),
       ('王五', '440101198508089999', '女', 41, '广州市天河区', '1985-08-08', '13800138003', 'wangwu@example.com',
        '房产,保守', '{
         "vip_level": 4,
         "tags": [
           "高净值",
           "房产持有者"
         ],
         "risk_score": 42
       }'::JSONB),
       ('赵六', '330101200012121111', '女', 26, '杭州市西湖区', '2000-12-12', '13800138004', 'zhaoliu@example.com',
        '新手', '{
         "vip_level": 1,
         "tags": [
           "新客"
         ],
         "risk_score": 50
       }'::JSONB);
INSERT INTO public.user (name, card_num, sex, age, address, birthday, phone, email, keywords, profile)
VALUES ('张三', '110101199001011234', 'M', 36, '北京市海淀区', '1990-01-01', '13800138001', 'zhangsan@example.com',
        '稳健,科技', '{
    "vip_level": 3,
    "tags": [
      "高净值",
      "长期投资者"
    ],
    "risk_score": 78
  }'::JSONB),
       ('李四', '310101199505055678', 'F', 31, '上海市浦东新区', '1995-05-05', '13800138002', 'lisi@example.com',
        '进取,基金', '{
         "vip_level": 2,
         "tags": [
           "定投用户"
         ],
         "risk_score": 65
       }'::JSONB),
       ('王五', '440101198508089999', 'M', 41, '广州市天河区', '1985-08-08', '13800138003', 'wangwu@example.com',
        '房产,保守', '{
         "vip_level": 4,
         "tags": [
           "高净值",
           "房产持有者"
         ],
         "risk_score": 42
       }'::JSONB),
       ('赵六', '330101200012121111', 'F', 26, '杭州市西湖区', '2000-12-12', '13800138004', 'zhaoliu@example.com',
        '新手', '{
         "vip_level": 1,
         "tags": [
           "新客"
         ],
         "risk_score": 50
       }'::JSONB);

INSERT INTO public.user_asset (user_id, asset_code, asset_type, asset_name, cost_amount, curr_value, status, meta,
                               acquired_at)
VALUES (1, 'AST-001', 'DEPOSIT', '招商银行定期存款', 300000.00, 312000.00, 'ACTIVE', '{
  "bank": "CMB",
  "rate": 0.026,
  "term_months": 24
}'::JSONB, '2024-05-01'),
       (1, 'AST-002', 'STOCK', '某科技龙头股票', 200000.00, 268000.00, 'ACTIVE', '{
         "symbol": "TECH01",
         "shares": 1000,
         "market": "US"
       }'::JSONB, '2024-08-15'),
       (1, 'AST-003', 'FUND', '沪深300指数增强', 150000.00, 142000.00, 'ACTIVE', '{
         "code": "000300E",
         "auto_invest": true
       }'::JSONB, '2025-01-10'),
       (2, 'AST-004', 'FUND', '新能源主题基金', 80000.00, 96000.00, 'ACTIVE', '{
         "code": "012345",
         "auto_invest": true
       }'::JSONB, '2024-11-20'),
       (2, 'AST-005', 'DEPOSIT', '余额宝/活期理财', 50000.00, 50850.00, 'ACTIVE', '{
         "bank": "MYBANK",
         "rate": 0.017
       }'::JSONB, '2025-06-01'),
       (3, 'AST-006', 'REAL_ESTATE', '天河区住宅', 3500000.00, 3850000.00, 'ACTIVE', '{
         "city": "广州",
         "area_sqm": 115,
         "rent_monthly": 8500
       }'::JSONB, '2020-03-18'),
       (3, 'AST-007', 'STOCK', '高股息银行股', 400000.00, 430000.00, 'ACTIVE', '{
         "symbol": "BANK09",
         "shares": 50000,
         "market": "CN"
       }'::JSONB, '2023-09-01'),
       (3, 'AST-008', 'STOCK', '已清仓主题股', 100000.00, 0.00, 'SOLD', '{
         "symbol": "OLD01",
         "realized_pnl": -8000
       }'::JSONB, '2022-02-01');

-- 更新
UPDATE public.user
SET age = age + 1
WHERE name = '*宇'
RETURNING id, name, age;

-- 查询
SELECT id, name, email, age
FROM public.user
WHERE age BETWEEN 2 AND 35
ORDER BY create_time DESC
LIMIT 2 OFFSET 0;

-- 聚合与分组
SELECT sex,
       COUNT(*)           AS user_count,
       ROUND(AVG(age), 1) AS avg_age
FROM public.user
GROUP BY sex
HAVING COUNT(*) > 1;

-- 插入 JSON 数据
UPDATE public.user
SET profile = '{
  "city": "Shanghai",
  "level": 3
}'
WHERE name = '*宇';

-- 查询 JSON 属性（->> 提取为文本）
SELECT name, profile ->> 'city' AS city
FROM public.user
WHERE (profile ->> 'level')::int >= 2;

-- CTE 公用表表达式 (WITH)：让复杂查询模块化、易读
WITH active_users AS (SELECT id, name, sex
                      FROM public.user
                      WHERE sex = '男')
SELECT au.sex, COUNT(au.id) AS total_orders
FROM active_users au
group by au.sex;

-- JSONB 深度关联查询: 查询用户画像（user.profile）中包含标签 "高净值" 且 risk_score 大于等于 40 的用户，找出他们名下在持资产中 meta
-- 包含 "auto_invest": true 或房产月租（meta->>'rent_monthly' 转数值）大于 5000 的资产明细
SELECT u.id                              AS user_id,
       u.name,
       (u.profile ->> 'vip_level')::INT  AS vip_level,
       (u.profile ->> 'risk_score')::INT AS risk_score,
       a.asset_code,
       a.asset_type,
       a.asset_name,
       a.curr_value,
       a.meta
FROM public.user u
         INNER JOIN public.user_asset a
                    ON u.id = a.user_id
WHERE a.status = 'ACTIVE'
  -- JSONB 数组包含判断
  AND u.profile -> 'tags' @> '[
  "高净值"
]'::JSONB
  -- JSONB 数值提取与比较
  AND COALESCE((u.profile ->> 'risk_score')::INT, 0) >= 40
  -- 资产 meta 条件组合
  AND (
    (a.meta @> '{
      "auto_invest": true
    }'::JSONB)
        OR (
        a.meta ? 'rent_monthly'
            AND (a.meta ->> 'rent_monthly')::NUMERIC > 5000
        )
    )
ORDER BY a.curr_value DESC;

-- 窗口函数
SELECT id,
       age,
       RANK() OVER (PARTITION BY id ORDER BY age DESC) AS order_rank
FROM public.user;

-- 针对在持资产（ACTIVE），计算每笔资产占该用户总资产的百分比，标注该资产在该用户名下的金额排名，同时给出该资产在全平台所有在持资产中的金额排名。
WITH active_assets AS (SELECT a.id                                       AS asset_id,
                              u.id                                       AS user_id,
                              u.name                                     AS user_name,
                              u.address,
                              a.asset_type,
                              a.asset_name,
                              a.curr_value,
                              SUM(a.curr_value) OVER (PARTITION BY u.id) AS user_total_value
                       FROM public.user_asset a
                                INNER JOIN public.user u
                                           ON a.user_id = u.id
                       WHERE a.status = 'ACTIVE')
SELECT user_id,
       user_name,
       address,
       asset_name,
       asset_type,
       curr_value,
       user_total_value,
       ROUND(
               CASE
                   WHEN user_total_value = 0 THEN 0
                   ELSE (curr_value / user_total_value) * 100
                   END,
               2
       )                                                                 AS pct_in_user_portfolio,
       DENSE_RANK() OVER (PARTITION BY user_id ORDER BY curr_value DESC) AS rank_in_user,
       DENSE_RANK() OVER (ORDER BY curr_value DESC)                      AS rank_global
FROM active_assets
ORDER BY user_id, rank_in_user;

-- 多表聚合 + 盈亏计算 + 零资产用户保留: 统计所有用户（包括没有资产的用户）的在持（ACTIVE）资产总成本、总现值、浮动盈亏金额及盈亏率，
-- 并分别统计存款与股票/基金的现值。
SELECT u.id                                                                 AS user_id,
       u.name,
       u.age,
       COUNT(a.id) FILTER (WHERE a.status = 'ACTIVE')                       AS active_asset_count,
       COALESCE(SUM(a.cost_amount) FILTER (WHERE a.status = 'ACTIVE'),
                0.00)                                                       AS total_cost,
       COALESCE(SUM(a.curr_value) FILTER (WHERE a.status = 'ACTIVE'), 0.00) AS total_curr_value,
       COALESCE(SUM(a.curr_value - a.cost_amount) FILTER (WHERE a.status = 'ACTIVE'),
                0.00)                                                       AS unrealized_pnl,
       CASE
           WHEN COALESCE(SUM(a.cost_amount) FILTER (WHERE a.status = 'ACTIVE'), 0) = 0 THEN 0.00
           ELSE ROUND(
                   (SUM(a.curr_value - a.cost_amount) FILTER (WHERE a.status = 'ACTIVE')
                       / SUM(a.cost_amount) FILTER (WHERE a.status = 'ACTIVE')) * 100,
                   2
                )
           END                                                              AS pnl_rate_pct,
       COALESCE(SUM(a.curr_value) FILTER (WHERE a.status = 'ACTIVE' AND a.asset_type = 'DEPOSIT'),
                0.00)                                                       AS deposit_value,
       COALESCE(SUM(a.curr_value) FILTER (WHERE a.status = 'ACTIVE' AND a.asset_type IN ('STOCK', 'FUND')),
                0.00)                                                       AS equity_fund_value
FROM public.user u
         LEFT JOIN public.user_asset a
                   ON u.id = a.user_id
GROUP BY u.id, u.name, u.age
ORDER BY total_curr_value DESC, u.id ASC;

-- 关联子查询: 找出每位用户当前在持资产中，浮动盈利（curr_value - cost_amount）最高的那 1 条资产记录（若用户无在持资产则不输出）
SELECT u.id                                           AS user_id,
       u.name,
       u.phone,
       top_asset.asset_code,
       top_asset.asset_name,
       top_asset.asset_type,
       top_asset.cost_amount,
       top_asset.curr_value,
       (top_asset.curr_value - top_asset.cost_amount) AS profit_amount
FROM public.user u
         CROSS JOIN LATERAL (
    SELECT a.asset_code,
           a.asset_name,
           a.asset_type,
           a.cost_amount,
           a.curr_value
    FROM public.user_asset a
    WHERE a.user_id = u.id
      AND a.status = 'ACTIVE'
    ORDER BY (a.curr_value - a.cost_amount) DESC, a.curr_value DESC
    LIMIT 1
    ) AS top_asset
ORDER BY profit_amount DESC;

-- 多维分组 + ROLLUP 小计与总计 + 用户年龄段分箱: 按年龄段（30岁以下、30-39岁、40岁及以上）和资产类型统计在持资产总现值，
-- 并使用 GROUPING SETS / ROLLUP 生成各维度小计与全表总计。
WITH user_bucket_asset AS (SELECT CASE
                                      WHEN u.age < 30 THEN '1. 30岁以下'
                                      WHEN u.age BETWEEN 30 AND 39 THEN '2. 30-39岁'
                                      WHEN u.age >= 40 THEN '3. 40岁及以上'
                                      ELSE '0. 未知年龄'
                                      END AS age_group,
                                  a.asset_type,
                                  a.curr_value
                           FROM public.user u
                                    INNER JOIN public.user_asset a
                                               ON u.id = a.user_id
                           WHERE a.status = 'ACTIVE')
SELECT COALESCE(age_group, '【全部年龄段合计】') AS age_group,
       COALESCE(asset_type, '【该年龄段小计】')  AS asset_type,
       COUNT(*)                                AS asset_items,
       SUM(curr_value)                         AS total_curr_value
FROM user_bucket_asset
GROUP BY ROLLUP (age_group, asset_type)
ORDER BY GROUPING(age_group),
         age_group NULLS LAST,
         GROUPING(asset_type),
         asset_type NULLS LAST;

-- 开启事务
BEGIN;
UPDATE public.user
SET age = age + 100
WHERE id = 2;
SAVEPOINT sp1; -- 设置保存点
UPDATE public.user
SET age = age - 100
WHERE id = 1;
-- 若出错可回滚到保存点或全部回滚：
-- ROLLBACK TO sp1;
-- ROLLBACK;
-- 提交事务
COMMIT;


-- 1. 启用 pgvector 扩展（需数据库已安装 pgvector 插件）
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. 创建存储向量的表
CREATE TABLE public.doc_embedding
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    biz_id      VARCHAR(64)  NOT NULL,
    doc_title   VARCHAR(200) NOT NULL,
    content     TEXT         NOT NULL,
    embedding   vector(1536) NOT NULL,
    metadata    JSONB        NOT NULL DEFAULT '{}'::JSONB,
    status      SMALLINT     NOT NULL DEFAULT 1,
    create_time TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 表与逐字段注释
COMMENT ON TABLE public.doc_embedding IS '文档向量存储表';
COMMENT ON COLUMN public.doc_embedding.id IS '主键ID，自增标识';
COMMENT ON COLUMN public.doc_embedding.biz_id IS '业务唯一标识（如文档ID或分片编码）';
COMMENT ON COLUMN public.doc_embedding.doc_title IS '文档标题';
COMMENT ON COLUMN public.doc_embedding.content IS '原始文本切片内容';
COMMENT ON COLUMN public.doc_embedding.embedding IS '文本向量（1536维单精度浮点向量）';
COMMENT ON COLUMN public.doc_embedding.metadata IS '扩展元数据（如来源、标签、租户ID等，JSONB格式）';
COMMENT ON COLUMN public.doc_embedding.status IS '状态：1-有效，0-失效/归档';
COMMENT ON COLUMN public.doc_embedding.create_time IS '创建时间（带时区）';
COMMENT ON COLUMN public.doc_embedding.update_time IS '更新时间（带时区）';

-- 常规业务字段与 JSONB 索引
CREATE INDEX idx_doc_embedding_biz_id ON public.doc_embedding (biz_id);
CREATE INDEX idx_doc_embedding_status ON public.doc_embedding (status);
CREATE INDEX idx_doc_embedding_metadata_gin ON public.doc_embedding USING GIN (metadata);

TRUNCATE TABLE public.doc_embedding RESTART IDENTITY;
ALTER TABLE public.doc_embedding
    ALTER COLUMN embedding TYPE vector(4);

-- 单条插入
INSERT INTO public.doc_embedding (biz_id, doc_title, content, embedding, metadata, status)
VALUES ('DOC_001',
        'PGSQL 索引原理',
        'B-Tree 适合等值和范围查询，GIN 适合 JSONB 与全文检索。',
        '[0.12, -0.05, 0.33, 0.81]'::vector,
        '{
          "source": "wiki",
          "lang": "zh"
        }'::JSONB,
        1);

-- 批量插入（推荐业务批量写入时使用）
INSERT INTO public.doc_embedding (biz_id, doc_title, content, embedding, metadata, status)
VALUES ('DOC_002', '事务隔离级别', '可重复读与读已提交在 MVCC 下的快照行为差异。', '[0.10, 0.02, 0.29, 0.77]'::vector, '{
  "source": "notes"
}'::JSONB, 1),
       ('DOC_003', '向量检索入门', '余弦距离常用于归一化后的语义向量检索。', '[0.55, 0.41, -0.12, 0.08]'::vector, '{
         "source": "guide"
       }'::JSONB, 1);

-- SELECT — 精确查询与 Top-K 相似度检索
-- <=> ：余弦距离（Cosine Distance），文本语义向量最常用，搭配 vector_cosine_ops
-- <-> ：欧氏距离 / L2 距离，搭配 vector_l2_ops
-- <#> ：负内积（Negative Inner Product），搭配 vector_ip_ops（返回负值，排序时同样 ORDER BY ... ASC 取最小）
-- 2.1 按业务条件精确查询
SELECT id, biz_id, doc_title, status, metadata
FROM public.doc_embedding
WHERE biz_id = 'DOC_001'
  AND status = 1;

-- Top-K 相似度检索（按余弦距离找最相似的前 5 条，并带出相似度分数）
SELECT id,
       biz_id,
       doc_title,
       content,
       (embedding <=> '[0.11, -0.04, 0.31, 0.80]'::vector)     AS cosine_distance,
       1 - (embedding <=> '[0.11, -0.04, 0.31, 0.80]'::vector) AS cosine_similarity
FROM public.doc_embedding
WHERE status = 1
ORDER BY embedding <=> '[0.11, -0.04, 0.31, 0.80]'::vector ASC
LIMIT 2;

-- 结合结构化过滤与阈值过滤的混合查询
SELECT id,
       biz_id,
       doc_title,
       (embedding <=> '[0.11, -0.04, 0.31, 0.80]'::vector) AS cosine_distance
FROM public.doc_embedding
WHERE status = 1
  AND metadata @> '{
  "lang": "zh"
}'::JSONB
  AND (embedding <=> '[0.11, -0.04, 0.31, 0.80]'::vector) < 0.35
ORDER BY embedding <=> '[0.11, -0.04, 0.31, 0.80]'::vector ASC
LIMIT 2;

-- 更新指定记录的向量与文本
UPDATE public.doc_embedding
SET
    content     = '更新后的文本内容：HNSW 适合高召回与低延迟检索。',
    embedding   = '[0.14, -0.02, 0.35, 0.79]'::vector,
    metadata    = jsonb_set(metadata, '{updated_by}', '"system"'::JSONB),
    update_time = CURRENT_TIMESTAMP
WHERE biz_id = 'DOC_001';

-- HNSW 索引（查询延迟低、召回率高，建索引更吃内存和时间，适合多数在线检索场景）
CREATE INDEX idx_doc_embedding_hnsw_cosine
ON public.doc_embedding
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
-- IVFFlat 索引（建索引更快、内存占用相对更低，适合数据先批量导入后再建索引）
-- CREATE INDEX idx_doc_embedding_ivfflat_cosine
-- ON public.doc_embedding
-- USING ivfflat (embedding vector_cosine_ops)
-- WITH (lists = 100);