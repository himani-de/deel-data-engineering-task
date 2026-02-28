-- macro for order status mapping to category
-- can be scaled up/down to category needed as per use case

{% macro order_status_fields(status_col) -%}
  {%- set s = "upper(trim(" ~ status_col ~ "))" -%}

  {{ s }} as order_status_norm,

  case
    when {{ s }} = 'COMPLETED' then 'completed'
    when {{ s }} = 'PENDING' then 'pending'
    when {{ s }} in ('PROCESSING', 'REPROCESSING') then 'processing'
    else 'unknown'
  end as order_status_category,

  case when {{ s }} = 'COMPLETED' then true else false end as is_completed,
  case when {{ s }} = 'PENDING' then true else false end as is_pending,
  case when {{ s }} in ('PROCESSING', 'REPROCESSING') then true else false end as is_processing,

  case when {{ s }} != 'COMPLETED' and {{ status_col }} is not null and
            {{ s }} in ('PENDING', 'PROCESSING', 'REPROCESSING')
       then true else false end as is_open
{%- endmacro %}