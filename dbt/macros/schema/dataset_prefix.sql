{% macro dataset_prefix() %}
    {# Prefix schema for dev/test environments #}

    {%- if target.name in ["dev", "test"] -%}
        {{ target.schema | trim }}_
    {%- endif -%}

{% endmacro %}