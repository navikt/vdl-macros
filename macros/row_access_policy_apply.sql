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
