/****************************************************************************************
-- Model: fact_order_items
-- Grain: 1 row per order_item_id
-- Purpose: Product-level fact table for item quantity analysis

-- KPIs Supported:
--   Number of open orders by DELIVERY_DATE and STATUS
--   Top 3 delivery dates with more open orders
--   Number of open pending items by PRODUCT_ID, this information can be queried using
--   The order status and the order items
--   Top 3 Customers with more pending orders

-- Notes:
--   Enables product-level aggregation
--   Can join to fact_orders for order-level filtering
--   Supports future revenue metrics
*****************************************************************************************/

{{
    config(
        materialized='table',
        tags=['mart','fact']
    )
}}

select
    order_item_id,
    order_id,
    product_id,
    customer_id,
    delivery_date,
    order_status_category,
    is_completed,
    is_pending,
    is_processing,
    is_open
from {{ ref('int_order_items_current') }}