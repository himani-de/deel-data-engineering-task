-- macro for historical backfill
-- timeframe can be modified in macrp and use in models

{% macro backfill_twoyears_date() -%}
    -- Returns a date 2 years before today
    CURRENT_DATE - INTERVAL '2 years'
{%- endmacro %}