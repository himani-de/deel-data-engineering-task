/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw order items data and deduplicate from products source
-- grain: 1 row per order id, updated at
--  primary_key: order_item_id
-- Incremental watermark: updated_at(lookback:2 hrs for low latency but can be updated in future if needed to reduce the latency
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_item_id",
        tags=["staging"]
    )
}}

/*********************************** source query **********************************************************************/

with raw_order_items as (
    select
        order_item_id,
        order_id,
        product_id,
        quanity as order_quanity,
        updated_at,
        updated_by,
        created_at,
        created_by,
        -- audit
        {{ load_info() }}
    from {{ source("customer_orders", "order_items") }}

    {% if is_incremental() %}
        where updated_at >= (
            select max(updated_at) - interval '2 hour'
            from {{ this }}
        )
    {% else %}
    -- full refresh: backfill last 2 years
        where updated_at >= {{ backfill_twoyears_date() }}
    {% endif %}
        and order_item_id is not null
  ),

dedup_order_items as (
    select *
    from (
        select
            *,
            row_number() over (
                partition by order_item_id
                order by updated_at desc nulls last,
                dbt_loaded_at desc
            ) as rn
        from raw_order_items
    ) oi
    WHERE rn = 1
)

select * from dedup_order_items