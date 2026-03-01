/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw order items data and deduplicate from products source
-- grain: 1 row per order item
--  primary_key: order_item_id
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
-- logic: last 2 hours for low-latency refresh, full backfill for initial load
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="table",
        tags=["staging", "order_item"]
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
    where order_item_id is not null

    {% if flags.FULL_REFRESH -%}
     -- full refresh: backfill last 2 years
       and updated_at >= {{ backfill_twoyears_date() }}
    {% else %}
   -- normal run: last 2 hours only
       and updated_at >= current_timestamp - interval '2 hour'
    {% endif %}
),

dedup_order_items as (
    select
        order_item_id,
        order_id,
        product_id,
        order_quanity,
        updated_at,
        updated_by,
        created_at,
        created_by,
        dbt_loaded_at,
        load_id
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