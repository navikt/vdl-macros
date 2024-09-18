{% macro apply_row_access_policy(policy, column, using) %}
    {%- set materialization = config.get("materialized") -%}
    {% if materialization != "view" %} {%- set materialization = "table" -%} {% endif %}
    {% set unset_policy_sql %}
        alter {{materialization}} {{ this }} add row access policy unset masking policy;  
    {% endset %}
    {% do run_query(unset_policy_sql) %}

    alter {{materialization}} {{ this }}
    add row access policy {{ this.database }}.{{ var("policy_schema") }}.{{ policy }}
    using (
    {{ column }}
    {%- for arg in using %}
    ,{{ arg }}
    {% endfor %}
)

{% endmacro %}
