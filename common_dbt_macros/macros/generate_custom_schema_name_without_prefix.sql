{% macro generate_custom_schema_name_without_prefix(varargs, kwargs) -%}
    {% set custom_schema_name = varargs[0] %}
    {% set node = varargs[1] %}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%} {{ default_schema }}

    {%- else -%} {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
