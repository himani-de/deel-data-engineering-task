/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw product data and deduplicate from products source
-- grain: 1 row per product_id
--  primary_key: product_id
-- Incremental watermark: updated_at(lookback:2 hrs for low latency but can be updated in future if needed to reduce the latency
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="product_id",
        tags=["staging"]
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

    {% if is_incremental() %}
        where updated_at >= (
            select coalesce(max(updated_at), '1900-01-01'::timestamp) - interval '2 hour'
        from {{ this }}
    )
    {% else %}
    -- full refresh: backfill last 2 years
        where updated_at >= {{ backfill_twoyears_date() }}
    {% endif %}
        and product_id is not null
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