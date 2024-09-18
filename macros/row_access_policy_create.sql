{% macro create_row_access_policy(name, input_params, body) %}

    {% set create_sql %}
        create row access policy if not exists {{ target.database }}.{{ var("policy_schema") }}.{{ name }} as (
            {% for param in input_params %}
            {{ param }} {% if not loop.last %},{% endif %}
            {% endfor %}
        )
        returns boolean -> true;
    {% endset %}
    {% do run_query(create_sql) %}

    {% set alter_sql %}
        alter row access policy {{ target.database }}.{{ var("policy_schema") }}.{{ name }} set body -> {{ body }};
    {% endset %}
    {% do run_query(alter_sql) %}

{% endmacro %}
