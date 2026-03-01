# queries.py
# Contains all SQL queries for the analytics API

fact_orders_table = "dev_mart.fact_orders"
fact_order_items_table = "dev_mart.fact_order_items"

# 1 Open orders by delivery_date and status
open_orders = f"""
SELECT
    delivery_date,
    order_status_category,
    COUNT(*) AS num_orders
FROM {fact_orders_table}
WHERE is_open = TRUE
GROUP BY delivery_date, order_status_category
ORDER BY delivery_date;
"""


# 2 Top 3 delivery dates by number of open orders (tie-safe using DENSE_RANK)
def get_top_3_delivery_dates(limit: int):
    return f"""
    WITH delivery_counts AS (
        SELECT
            delivery_date,
            COUNT(*) AS num_open_orders
        FROM {fact_orders_table}
        WHERE is_open = TRUE
        GROUP BY delivery_date
    ),
    ranked_dates AS (
        SELECT
            delivery_date,
            num_open_orders,
            DENSE_RANK() OVER (ORDER BY num_open_orders DESC, delivery_date DESC) AS rnk
        FROM delivery_counts
    )
    SELECT
        delivery_date,
        num_open_orders
    FROM ranked_dates
    WHERE rnk <= {limit}
    ORDER BY num_open_orders DESC, delivery_date DESC
    """


# 3 Open pending items by PRODUCT_ID
open_pending_items_by_product = f"""
SELECT
    product_id,
    COUNT(*) AS open_pending_items
FROM {fact_order_items_table}
WHERE is_pending = TRUE AND is_open = TRUE
GROUP BY product_id
ORDER BY open_pending_items DESC;
"""


# 4 Top 3 Customers with more pending orders
def top_3_customers(limit: int):
    return f"""
    WITH customer_pending AS (
        SELECT
            customer_id,
            COUNT(DISTINCT order_id) AS pending_orders
        FROM {fact_orders_table}
        WHERE is_pending = TRUE AND is_open = TRUE
        GROUP BY customer_id
    ),
    ranked_customers AS (
        SELECT
            customer_id,
            pending_orders,
            DENSE_RANK() OVER (ORDER BY pending_orders DESC) AS rnk
        FROM customer_pending
    )
    SELECT
        customer_id,
        pending_orders
    FROM ranked_customers
    WHERE rnk <= {limit}
    ORDER BY pending_orders DESC, customer_id
    """
