{% macro apply_masking_policy(
    policy, column, using, database=this.database, schema="policies"
) %}
    {% if database == target.database %} {% set uri = schema ~ "." ~ policy %}
    {% else %} {% set uri = database ~ "." ~ schema ~ "." ~ policy %}
    {% endif %}
    {%- set materialization = config.get("materialized") -%}
    {% if materialization != "view" %} {%- set materialization = "table" -%} {% endif %}
    {% set unset_policy_sql %}
        alter {{ materialization }} {{ this }} modify column {{ column }} unset masking policy;
    {% endset %}
    {% do run_query(unset_policy_sql) %}

    alter {{materialization}} {{ this }}
    modify column {{ column }}
    set masking policy {{ uri }}

    using (
    {{ column }}
    {%- for arg in using %}
    ,{{ arg }}
    {% endfor %}
)

{% endmacro %}


{% macro create_masking_policy(
    name,
    val_type,
    input_params,
    body,
    database=target.database,
    schema="policies"
) %}

    {% set create_sql %}
        create masking policy if not exists {{ database }}.{{ schema }}.{{ name }} as (
            val {{ val_type }}
            {% for param in input_params %}
            ,{{ param }}
            {% endfor %}
        )
        returns {{ val_type }} -> val;
    {% endset %}
    {% do run_query(create_sql) %}

    {% set alter_sql %}
        alter masking policy {{ database }}.{{ schema }}.{{ name }} set body -> {{ body }};
    {% endset %}
    {% do run_query(alter_sql) %}

{% endmacro %}
