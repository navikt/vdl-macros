{% macro create_masking_policy(name, val_type, input_params, body) %}

    {% set create_sql %}
        create masking policy if not exists {{ target.database }}.{{ var("policy_schema") }}.{{ name }} as (
            val {{ val_type }}
            {% for param in input_params %}
            ,{{ param }}
            {% endfor %}
        )
        returns {{ val_type }} -> val;
    {% endset %}
    {% do run_query(create_sql) %}

    {% set alter_sql %}
        alter masking policy {{ target.database }}.{{ var("policy_schema") }}.{{ name }} set body -> {{ body }};
    {% endset %}
    {% do run_query(alter_sql) %}

{% endmacro %}
