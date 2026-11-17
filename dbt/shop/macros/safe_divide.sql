{# Деление без ошибки на ноль: если знаменатель 0 или NULL, результат NULL. #}
{% macro safe_divide(numerator, denominator, digits=2) %}
    round(({{ numerator }})::numeric / nullif({{ denominator }}, 0), {{ digits }})
{% endmacro %}
