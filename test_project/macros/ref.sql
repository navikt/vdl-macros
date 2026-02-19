{% macro ref() %}
    {% do return(vdl_macros.ref_without_db(varargs, kwargs)) %}
{% endmacro %}
