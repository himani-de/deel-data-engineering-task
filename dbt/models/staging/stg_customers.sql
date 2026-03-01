/* ------------------------------------------------------------------------------------------------------------------
-- Description: staging layer to collect raw customer data and deduplicate from products source
-- grain: 1 row per customer
--  primary_key: customer_id
-- purpose: no business logic, raw mapping from source, cast/renaming for more clear business context and deduplication
-- logic: last 2 hours for low-latency refresh, full backfill for initial load
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="table",
        tags=["staging", "customers"]
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
    where customer_id is not null

    {% if flags.FULL_REFRESH -%}
    -- full refresh: backfill last 2 years
      and updated_at >= {{ backfill_twoyears_date() }}
    {% else %}
    -- normal run: last 2 hours only
     and updated_at >= current_timestamp - interval '2 hour'
    {% endif %}
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