{% snapshot orders_history %}

/***********************************************************************************************************************
-- Snapshot Name: orders_history
-- Description: Track historical changes to orders for SCD2 analytics while preserving current state.
-- Grain: 1 row per order_id per change (incremental SCD2)
-- Source: stg_orders (staging incremental table, latest state)
-- SCD2 Fields (added automatically by dbt):
--    - dbt_valid_from  → when this version became active
--    - dbt_valid_to    → when this version was replaced (NULL if current)
--    - dbt_scd_id      → unique ID for this snapshot row
--    - Works alongside incremental staging (stg_orders) and intermediate models (int_orders_current)
***********************************************************************************************************************/

{{
    config(
        materialized='snapshot',
        unique_key='order_id',
        strategy='timestamp',
        updated_at='updated_at',
        tags=["snapshot", "scd2", "order"]
    )
}}

select
    order_id,
    customer_id,
    order_date,
    delivery_date,
    order_status,
    {{ order_status_fields('order_status') }},   -- include category + flags
    updated_at,
    updated_by,
    created_at,
    created_by,
    dbt_loaded_at,
    load_id
from {{ ref('stg_orders') }}

{% endsnapshot %}