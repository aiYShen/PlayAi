SELECT version();
SHOW DATABASES;

CREATE TABLE IF NOT EXISTS default.user_events
(
    event_date Date COMMENT '事件发生日期，用于按月分区与TTL生命周期管理',
    event_time DateTime COMMENT '事件精确时间戳（精确到秒）',
    user_id    UInt64 COMMENT '用户全局唯一ID',
    event_type LowCardinality(String) COMMENT '事件类型：view-浏览, click-点击, purchase-购买',
    amount     Decimal(10, 2)         DEFAULT 0.00 COMMENT '交易金额（单位：元）',
    device_os  LowCardinality(String) DEFAULT 'unknown' COMMENT '客户端操作系统：iOS / Android / Web'
)
    ENGINE = MergeTree()
        PARTITION BY toYYYYMM(event_date)
        ORDER BY (event_type, user_id, event_time)
        TTL event_date + INTERVAL 90 DAY DELETE
        SETTINGS index_granularity = 8192
        COMMENT '用户行为埋点明细表';

ALTER TABLE default.user_events
    ADD COLUMN IF NOT EXISTS channel LowCardinality(String) DEFAULT 'organic' COMMENT '流量来源渠道';
ALTER TABLE default.user_events
    COMMENT COLUMN amount '订单实付金额（单位：元，保留两位小数）';
ALTER TABLE default.user_events
    MODIFY COMMENT '用户端核心行为埋点与交易明细表';

-- 查看完整建表 DDL
SHOW CREATE TABLE default.user_events;
-- 查看字段列表及注释
DESCRIBE TABLE default.user_events;

-- 查询字段名、数据类型及字段注释
SELECT name    AS column_name,
       type    AS data_type,
       default_expression,
       comment AS column_comment
FROM system.columns
WHERE database = 'default'
  AND table = 'user_events';
-- 查询表注释
SELECT name    AS table_name,
       engine,
       comment AS table_comment
FROM system.tables
WHERE database = 'default'
  AND name = 'user_events';

-- CREATE DATABASE IF NOT EXISTS order_dw;

CREATE TABLE IF NOT EXISTS default.orders_rep
(
    order_id     UInt64 COMMENT '订单唯一ID',
    user_id      UInt64 COMMENT '下单用户ID',
    order_status LowCardinality(String) COMMENT '订单状态：CREATED / PAID / SHIPPED / CANCELLED',
    pay_amount   Decimal(12, 2) COMMENT '支付金额（元）',
    updated_at   DateTime64(3) COMMENT '状态更新时间（毫秒，作为去重版本列）',
    event_date   Date COMMENT '订单更新日期（用于分区）'
)
    ENGINE = ReplacingMergeTree(updated_at)
        PARTITION BY toYYYYMM(event_date)
        ORDER BY (order_id)
        SETTINGS index_granularity = 8192
        COMMENT '订单状态去重明细表（ReplacingMergeTree）';

INSERT INTO default.orders_rep
    (order_id, user_id, order_status, pay_amount, updated_at, event_date)
VALUES (10001, 501, 'CREATED', 120.00, '2026-11-27 10:00:00.000', '2026-11-27'),
       (10001, 501, 'PAID', 120.00, '2026-11-27 10:05:00.000', '2026-11-27'),
       (10001, 501, 'SHIPPED', 120.00, '2026-11-27 10:20:00.000', '2026-11-27'),
       (10002, 502, 'CREATED', 250.00, '2026-11-27 10:10:00.000', '2026-11-27'),
       (10002, 502, 'CANCELLED', 250.00, '2026-11-27 10:12:00.000', '2026-11-27');

SELECT order_id,
       user_id,
       order_status,
       pay_amount,
       updated_at
FROM default.orders_rep FINAL
WHERE event_date = '2026-11-27'
ORDER BY order_id;

SELECT
    order_id,
    argMax(user_id, updated_at) AS user_id,
    argMax(order_status, updated_at) AS order_status,
    argMax(pay_amount, updated_at) AS pay_amount,
    max(updated_at) AS latest_updated_at
FROM default.orders_rep
WHERE event_date = '2026-11-27'
GROUP BY order_id
ORDER BY order_id;