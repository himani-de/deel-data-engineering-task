--add load info for auditing and debugging

{% macro load_info() -%}
    {# add current timestamp and invocation id from dbt for logging #}
        CURRENT_TIMESTAMP as dbt_loaded_at,
        '{{ invocation_id }}' as load_id
    {%- endmacro %}