{% macro ref_without_db(varargs, kwargs) %}
    -- based on https://docs.getdbt.com/reference/dbt-jinja-functions/builtins#usage
    -- extract user-provided positional and keyword arguments
    {% set version = kwargs.get("version") or kwargs.get("v") %}
    {% set packagename = none %}
    {%- if (varargs | length) == 1 -%} {% set modelname = varargs[0] %}
    {%- else -%} {% set packagename = varargs[0] %} {% set modelname = varargs[1] %}
    {% endif %}

    -- call builtins.ref based on provided positional arguments
    {% set rel = None %}
    {% if packagename is not none %}
        {% set rel = builtins.ref(packagename, modelname, version=version) %}
    {% else %} {% set rel = builtins.ref(modelname, version=version) %}
    {% endif %}

    -- finally, return relation without the database name
    {% if rel.database == target.database %}
        {% set newrel = rel.include(database=false) %}
    {% else %}
        -- we need to preserve the database name if it's different from the target
        -- database, otherwise we might end up with ambiguous references to e.g.
        -- snapshots
        {% set newrel = rel %}
    {% endif %}
    {% do return(newrel) %}

{% endmacro %}
