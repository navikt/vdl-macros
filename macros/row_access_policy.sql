{% macro apply_row_access_policy(policy, using, database=this.database, schema="policies") %}
    {%- set materialization = config.get("materialized") -%}
    {% if materialization != "view" %} {%- set materialization = "table" -%} {% endif %}

    alter {{ materialization }} {{ this }}
    add row access policy {{ database }}.{{ schema }}.{{ policy }}
    on (
    {%- for arg in using %}
    {{ arg }}{% if not loop.last %},{% endif %}
    {% endfor %}
)

{% endmacro %}


{% macro create_row_access_policy(
    name, input_params, body, database=target.database, schema="policies"
) %}

    {% set create_sql %}
        create row access policy if not exists {{ database }}.{{ schema }}.{{ name }} as (
            {% for param in input_params %}
            {{ param }} {% if not loop.last %},{% endif %}
            {% endfor %}
        )
        returns boolean -> true;
    {% endset %}
    {% do run_query(create_sql) %}

    {% set alter_sql %}
        alter row access policy {{ database }}.{{ schema }}.{{ name }} set body -> {{ body }};
    {% endset %}
    {% do run_query(alter_sql) %}

{% endmacro %}
