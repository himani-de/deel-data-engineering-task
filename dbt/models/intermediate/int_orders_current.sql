/*----------------------------------------------------------------------------------------------------------------------
  -- Description: Intermediate order-grain table
  -- Grain: 1 row per order_id
  -- Purpose: Deduplicate staging, normalize order_status, add business logic
  -- Incremental merge: only new or updated rows added; full refresh handles backfill.
  -- Keep updated_at for incremental merge.
  --   Keep DBT audit columns for traceability.
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="order_id",
        tags=["intermediate", "order"]
    )
}}

/*********************************** source query **********************************************************************/

with staged_orders as (
    select *
    from {{ ref('stg_orders') }}
),

staged_orders_updates as (
    select
        *
    from staged_orders s
    {% if is_incremental() %}
        -- Incremental run: only rows not in target or updated after last load
        where not exists (
            select 1
            from {{ this }} t
            where t.order_id = s.order_id
              and t.updated_at >= s.updated_at
        )
    {% endif %}
 )

/*********************************** Final Upsert **********************************************************************/

select
    order_id,
    customer_id,
    order_date,
    delivery_date,
    order_status,
    {{ order_status_fields('order_status') }},  -- normalized status
    created_at,
    created_by,
    updated_at,
    updated_by,
    dbt_loaded_at,
    load_id
from staged_orders_updates