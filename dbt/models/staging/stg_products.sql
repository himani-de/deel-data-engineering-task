/* ------------------------------------------------------------------------------------------------------------------
--  Description: staging layer to collect raw product data and deduplicate from products source
--  grain: 1 row per product_id
--  primary_key: product_id
--  purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
--  logic: last 2 hours for low-latency refresh, full backfill for initial load
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="table",
        tags=["staging", "products"]
    )
}}

/*********************************** source query **********************************************************************/

with raw_products as (
    select
        product_id,
        product_name,
        barcode as product_barcode,
        unity_price as product_unit_price,
        is_active as product_status,
        updated_at,
        updated_by,
        created_at,
        created_by,
        -- audit
        {{ load_info() }}
    from {{ source("customer_orders", "products") }}
    where product_id is not null

    {% if flags.FULL_REFRESH -%}
    -- full refresh: backfill last 2 years
      and updated_at >= {{ backfill_twoyears_date() }}
    {% else %}
    -- normal run: last 2 hours only
     and updated_at >= current_timestamp - interval '2 hour'
    {% endif %}
),

dedup_products as (

    select
        product_id,
        product_name,
        product_barcode,
        product_unit_price,
        product_status,
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
                partition by product_id
                order by updated_at desc nulls last,
                         dbt_loaded_at desc
            ) as rn
        from raw_products
    ) p
    where rn = 1
)
select * from dedup_products