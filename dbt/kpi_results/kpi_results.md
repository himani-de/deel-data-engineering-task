# KPI Results

## MUST HAVE Requirement

### We must be able to query the historical information along with the current orders’ state data.

This requirement is fulfilled using:

- `fact_orders` → current state analytics
- `orders_scd2` → historical snapshot (SCD Type 2)

## 1. Current Order State (fact orders table)

Query: Current Open Orders

```
select
    order_id,
    customer_id,
    order_status_category,
    delivery_date
from fact_orders
```
## 2. historical Order State (snapshot orders scd2)
```
select
    order_id,
    order_status,            -- raw source status
    order_status_category,   -- business-normalized status
    dbt_valid_from,
    dbt_valid_to
from orders_scd2
order by order_id, dbt_valid_from
```
## 3. Number of open orders by DELIVERY_DATE and STATUS
```
select
    delivery_date,
    order_status_category,
    count(*) as num_open_orders
from fact_orders
where is_open = true
group by delivery_date, order_status_category
order by delivery_date, order_status_category
```
## 4. Top 3 delivery dates with more open orders
```
with delivery_counts as (
    select
        delivery_date,
        count(*) as num_open_orders
    from fact_orders
    where is_open = true
    group by delivery_date
),
ranked_dates as (
    select
        delivery_date,
        num_open_orders,
        dense_rank() over (order by num_open_orders desc) as rnk
    from delivery_counts
)
select
    delivery_date,
    num_open_orders
from ranked_dates
where rnk <= 3
order by num_open_orders desc, delivery_date desc
```
## 5. Number of open pending items by PRODUCT_ID
```
select
    product_id,
    count(*) as num_open_pending_items
from fact_order_items
where is_open = true
  and is_pending = true
group by product_id
order by num_open_pending_items desc, product_id
```
## 6. Top 3 Customers with more pending orders
```
with customer_counts as (
    select
        customer_id,
        count(distinct order_id) as pending_orders
    from fact_orders
    where is_pending = true
    group by customer_id
),
ranked_customers as (
    select
        customer_id,
        pending_orders,
        dense_rank() over (order by pending_orders desc) as rnk
    from customer_counts
)
select
    customer_id,
    pending_orders
from ranked_customers
where rnk <= 3
order by pending_orders desc, customer_id
```