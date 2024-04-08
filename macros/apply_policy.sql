{% macro apply_masking_policy(policy, column, using) %}
    {%- set materialization = config.get("materialized") -%}
    {% if materialization != "view" %} {%- set materialization = "table" -%} {% endif %}
    {% set unset_policy_sql %}
        alter {{materialization}} {{ this }} modify column {{column}} unset masking policy;  
    {% endset %}
    {% do run_query(unset_policy_sql) %}

    alter {{materialization}} {{ this }}
    modify column {{ column }}
    set masking policy {{ this.database }}.{{ var("policy_schema") }}.{{ policy }}
    using (
    {{ column }}
    {%- for arg in using %}
    ,{{ arg }}
    {% endfor %}
)

{% endmacro %}
