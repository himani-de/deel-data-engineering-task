/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw customer data and deduplicate from products source
-- grain: 1 row per customer
--  primary_key: customer_id
-- Incremental watermark: updated_at(lookback:2 hrs for low latency but can be updated in future if needed to reduce the latency
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="customer_id",
        tags=["staging"]
    )
}}

/*********************************** source query **********************************************************************/

with raw_customers as (
    select
        customer_id,
        customer_name,
        is_active as customer_status,
        customer_address,  -- if considered as customer sensitive data, need to hash this column
        updated_at,
        updated_by,
        created_at,
        created_by,
        -- audit
        {{ load_info() }}
    from {{ source("customer_orders", "customers") }}

    {% if is_incremental() %}
        where updated_at >= (
            select coalesce(max(updated_at), '1900-01-01'::timestamp) - interval '2 hour'
        from {{ this }}
    )
    {% else %}
    -- full refresh: backfill last 2 years
        where updated_at >= {{ backfill_twoyears_date() }}
    {% endif %}
        and customer_id is not null
  ),

dedup_customers as (
    select
        customer_id,
        customer_name,
        customer_status,
        customer_address,  -- if considered as customer sensitive data, need to hash this column
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
                partition by customer_id
                order by updated_at desc nulls last,
                dbt_loaded_at desc
            ) as rn
        from raw_customers
    ) c
    WHERE rn = 1
)

select * from dedup_customers