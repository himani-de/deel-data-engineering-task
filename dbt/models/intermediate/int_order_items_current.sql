
/*----------------------------------------------------------------------------------------------------------------------
  -- Description: Intermediate order-item-grain view.
  -- reporting almost always needs to filter/split by order status (completed vs pending vs processing).
  -- One row per order_item_id (and belongs to an order_id).
  -- left join to int_orders so items are not dropped if an order record is missing.
---------------------------------------------------------------------------------------------------------------------*/

{{
    config(
        materialized="view",
        tags=["incremental", "view", "order_item"]
    )
}}

/*********************************** source query **********************************************************************/

select
  i.*,
  -- Order-level status context on each item row
  o.customer_id,
  o.order_date,
  o.order_status_category,
  o.is_completed,
  o.is_pending,
  o.is_processing

from {{ ref('stg_order_items') }} i
left join {{ ref('int_orders_current') }} o
on i.order_id = o.order_id