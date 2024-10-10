{% macro apply_row_access_policy(policy, using) %}
    {%- set materialization = config.get("materialized") -%}
    {% if materialization != "view" %} {%- set materialization = "table" -%} {% endif %}
    {% set unset_policy_sql %}
        alter {{materialization}} {{ this }} drop row access policy;  
    {% endset %}
    {% do run_query(unset_policy_sql) %}

    alter {{materialization}} {{ this }}
    {% if var("policy_db") is defined %}
        add row access policy {{ var("policy_db") }}.{{ var("policy_schema") }}.{{ policy }}
    {% else %}
        add row access policy {{ this.database }}.{{ var("policy_schema") }}.{{ policy }}
    {% endif %}
    using (
    {{ column }}
    {%- for arg in using %}
    ,{{ arg }}
    {% endfor %}
)

{% endmacro %}
