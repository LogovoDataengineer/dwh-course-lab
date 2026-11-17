{# Схема модели — ровно то, что указано в +schema (stg, cdm), без префикса целевой схемы #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name if custom_schema_name else target.schema }}
{%- endmacro %}
