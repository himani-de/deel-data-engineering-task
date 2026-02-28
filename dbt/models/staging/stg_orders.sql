/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw order data and deduplicate from orders source
-- grain: 1 row per order_id
--  primary_key: order_id
-- Incremental watermark: updated_at(lookback:2 hrs for low latency but can be updated in future if needed to reduce the latency
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_id",
        tags=["staging"]
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

    {% if is_incremental() %}
        where updated_at >= (
            coalesce(max(updated_at), '1900-01-01'::timestamp)
            from {{ this }}
        ) - interval '2 hour'
    {% else %}
    -- full refresh: backfill last 2 years
        where updated_at >= {{ backfill_twoyears_date() }}
    {% endif %}
        and order_id is not null
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