{% macro generate_schema_name(custom_schema_name, node) %}
    {% set prefix = dataset_prefix() %}

    {# folder-based schema: stg → staging, int → intermediate, mart → mart #}
    {% if node.fqn[1] is defined %}
        {% set schema_part = node.fqn[1] %}
    {% else %}
        {% set schema_part = node.schema %}
    {% endif %}

    {{ prefix ~ schema_part }}
{% endmacro %}

