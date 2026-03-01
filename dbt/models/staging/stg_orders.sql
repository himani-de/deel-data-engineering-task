/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw order data and deduplicate from orders source
-- grain: 1 row per order_id
--  primary_key: order_id
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
-- logic: last 2 hours for low-latency refresh, full backfill for initial load
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="table",
        tags=["staging", "order"]
    )
}}

/*********************************** source query **********************************************************************/

with raw_orders as (
    select
        order_id,
        order_date,
        delivery_date,
        customer_id,
        status as order_status,
        updated_at,
        updated_by,
        created_at,
        created_by,
        -- audit
        {{ load_info() }}
    from {{ source("customer_orders", "orders") }}
    where order_id is not null

    {% if flags.FULL_REFRESH -%}
    -- full refresh: backfill last 2 years
      and updated_at >= {{ backfill_twoyears_date() }}
    {% else %}
    -- normal run: last 2 hours only
     and updated_at >= current_timestamp - interval '2 hour'
    {% endif %}
),

dedup_orders as (
    select
        order_id,
        order_date,
        delivery_date,
        customer_id,
        order_status,
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
                partition by order_id
                order by updated_at desc nulls last,
                dbt_loaded_at desc
            ) as rn
        from raw_orders
    ) o
    where rn = 1
)

select * from dedup_orders