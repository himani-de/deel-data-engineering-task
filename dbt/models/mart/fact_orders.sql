/****************************************************************************************
-- Model: fact_orders
-- Grain: 1 row per order_id
-- Purpose: Core order-level fact table for business KPI calculations

-- KPIs Supported:
--   1) Number of open orders by DELIVERY_DATE and STATUS
--   2) Top 3 delivery dates with more open orders
--   3) Top 3 customers with more pending orders

-- Notes:
--   - Current-state analytical table
--   - Snapshot (orders_scd2) handles historical tracking
--   - Safe for aggregation (no SCD duplication risk)
*****************************************************************************************/

{{
    config(
        materialized='table',
        tags=['mart','fact']
    )
}}

select
    order_id,
    customer_id,
    order_date,
    delivery_date,
    order_status_category,
    is_pending,
    is_completed,
    is_processing
from {{ ref('int_orders_current') }}