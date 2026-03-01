/****************************************************************************************
-- Model: dim_date
-- Grain: 1 row per calendar date
-- Purpose:
--   - Provides a consistent date dimension for analytics and reporting.
--   - Allows easy grouping, filtering, and reporting by day, week, month, quarter, year.
--   - Adds business-friendly attributes (weekday name, weekend flag etc.)
--   - Supports future KPIs and aggregations across facts without repeating date logic.
-- Notes:
--   - Even if facts contain date fields (delivery_date, order_date),
--   - using dim_date ensures consistency across multiple reports and dashboards.
--   - Enables joins BI-friendly calculations.
*****************************************************************************************/

{{
    config(
        materialized='table',
        tags=['dim','date']
    )
}}

/*********************************** source query **********************************************************************/

select
    d as calendar_date,
    extract(year from d) as year,
    extract(month from d) as month,
    extract(day from d) as day,
    to_char(d, 'Day') as weekday_name,
    case when extract(dow from d) in (0,6) then true else false end as is_weekend,
    date_trunc('month', d) as month_start,
    date_trunc('quarter', d) as quarter_start,
    date_trunc('year', d) as year_start
from generate_series('2020-01-01'::date, current_date + interval '2 year', interval '1 day') as t(d);