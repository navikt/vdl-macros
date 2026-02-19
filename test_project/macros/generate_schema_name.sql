{% macro generate_schema_name() %}
    {{ vdl_macros.generate_custom_schema_name_without_prefix(varargs, kwargs) }}
{% endmacro %}
