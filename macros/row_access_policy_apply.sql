{% macro apply_row_access_policy(policy, using) %}
    {%- set materialization = config.get("materialized") -%}
    {% if materialization != "view" %} {%- set materialization = "table" -%} {% endif %}

    alter {{materialization}} {{ this }}
    {% if var("policy_db") is defined %}
        add row access policy {{ var("policy_db") }}.{{ var("policy_schema") }}.{{ policy }}
    {% else %}
        add row access policy {{ this.database }}.{{ var("policy_schema") }}.{{ policy }}
    {% endif %}
    on (
    {%- for arg in using %}
    {{ arg }}{% if not loop.last %},{% endif %}
    {% endfor %}
)

{% endmacro %}
