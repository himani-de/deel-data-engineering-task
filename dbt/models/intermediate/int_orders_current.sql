/*----------------------------------------------------------------------------------------------------------------------
  -- Description: Intermediate order-grain view. One row per order_id.
  -- Centralize status normalization in ONE place (via the order_status_fields() macro):
  -- raw order_status -> order_status_category + boolean flags
  -- This keeps status logic consistent across all downstream models.
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="view",
        tags=["intermediate", "view", "order"]
    )
}}

/*********************************** source query **********************************************************************/

select
  *,
  -- Derived mapping fields (category + flags) from centralized macro
  {{ order_status_fields('order_status') }}

from {{ ref('stg_orders') }}