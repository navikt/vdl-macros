{% macro convert_dbt_snapshot(
    from,
    to,
    loaded_at_column_name="_loaded_at",
    exclude_columns=[],
    exclude_dbt_columns=["dbt_scd_id","dbt_updated_at","dbt_valid_from","dbt_valid_to"]
) %}

    {% if execute %}
        {% set exclude_set = exclude_columns + exclude_dbt_columns %}
        {% set from_date = run_query(
            "select min(dbt_valid_from)::timestamp from " ~ from
        ).columns[0].values()[0] %}
        {# #}
        {% set current_date = (
            run_query("select current_date::timestamp").columns[0].values()[0]
        ) %}
        {% set number_of_days = (current_date - from_date).days + 2 %}

        {% set query %}
            create table {{ to }} as
            with
                src as (select * from {{ from }}),

                time as (
                    select
                        dateadd(day, seq4(), '{{ from_date.strftime("%Y-%m-%d") }}'::timestamp) as generated_date
                    from table(generator(rowcount => {{ number_of_days }}))
                    where generated_date <= current_timestamp
                    order by generated_date
                ),

                generate_data as (
                    select src.*, time.generated_date as _loaded_at
                    from src
                    join
                        time
                        on time.generated_date
                        between src.dbt_valid_from::timestamp and coalesce(
                            src.dbt_valid_to, '9999-12-31'::timestamp
                        )
                ),

                exclude_columns as (
                    select * exclude({{ exclude_set | join(", ") }}) from generate_data
                ),

                final as (select * from exclude_columns)

            select *
            from final
        {% endset %}

        {% do run_query(query) %}

    {% endif %}
{% endmacro %}
