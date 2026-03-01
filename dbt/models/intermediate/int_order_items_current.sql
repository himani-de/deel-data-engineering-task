/*----------------------------------------------------------------------------------------------------------------------
-- Model: int_order_items_current
-- Grain: 1 row per order_item_id
-- Purpose: Deduplicated and enriched order-item-level data
-- Notes:
--   - Includes order-level context from int_orders_current.
--   - Keep updated_at for incremental merge.
--   - Keep DBT audit columns for traceability.
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_item_id",
        tags=["intermediate", "order_item"]
    )
}}

/*********************************** source query **********************************************************************/

with staged_order_items as (
    select *
    from {{ ref('stg_order_items') }}
),

staged_order_item_updates as (
    select *
    from staged_order_items s
    {% if is_incremental() %}
        -- incremental run: only new or updated order items
        where not exists (
            select 1
            from {{ this }} t
            where t.order_item_id = s.order_item_id
              and t.updated_at >= s.updated_at
        )
    {% endif %}
),

enriched_order_items as (
    select
        s.*,
        o.customer_id,
        o.order_date,
        o.delivery_date,
        o.order_status_category,
        o.is_completed,
        o.is_pending,
        o.is_processing,
        o.is_open
    from staged_order_item_updates s
    left join {{ ref('int_orders_current') }} o
    on s.order_id = o.order_id
)

/*********************************** Final Upsert **********************************************************************/

select
    order_item_id,
    order_id,
    product_id,
    customer_id,
    order_date,
    delivery_date,
    order_status_category,
    is_completed,
    is_pending,
    is_processing,
    is_open,
    order_quanity,
    created_at,
    created_by,
    updated_at,
    updated_by,
    dbt_loaded_at,
    load_id
from enriched_order_items