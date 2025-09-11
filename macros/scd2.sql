{% macro scd2(
    from,
    unique_key="_hist_record_hash",
    entity_key="_hist_entity_key_hash",
    updated_at="_hist_record_updated_at",
    loaded_at="_hist_loaded_at",
    deleted_at="_hist_entity_key_deleted_at",
    created_at="_hist_record_created_at",
    first_valid_from="1900-01-01 00:00:00",
    last_valid_to="9999-01-01 23:59:59"
) %}
    {{
        config(
            materialized="incremental",
            unique_key=unique_key,
            on_schema_change="fail",
        )
    }}
    with
        _scd2_cte as (
            {% if is_incremental() %}
                {{
                    vdl_macros._scd2__incremental(
                        from, unique_key, entity_key, updated_at, loaded_at, deleted_at, first_valid_from, last_valid_to
                    )
                }}
            {% else %}
                {{
                    vdl_macros._scd2__full_refresh(
                        from, unique_key, entity_key, updated_at, loaded_at, deleted_at, first_valid_from, last_valid_to
                    )
                }}
            {% endif %}
        ),

        _scd2_rename_cols as (
            select
                {{ unique_key }} as pk_{{ this.name }},
                {{ entity_key }} as ek_{{ this.name }},
                {{ loaded_at }} as lastet_tidspunkt,
                _scd2_record_updated_at as oppdatert_tidspunkt,
                {{ created_at }} as opprettet_tidspunkt,
                _scd2_valid_from as gyldig_fra,
                _scd2_valid_to as gyldig_til,
                *,
            from _scd2_cte
        ),

        _final as (select *, from _scd2_rename_cols)
    select *
    from _final

{% endmacro %}

{% macro _scd2__incremental(from, unique_key, entity_key, updated_at, loaded_at, deleted_at, first_valid_from, last_valid_to) %}
    with
        _src as (
            select
                {{ dbt_utils.star(from=from, quote_identifiers=false) }},
                current_timestamp as _scd2_record_updated_at,
            from {{ from }}
            where {{ updated_at }} > (select max({{ updated_at }}) from {{ this }})
        ),

        _last_valid_records as (
            select
                {{ dbt_utils.star(from=from, relation_alias='this', quote_identifiers=false) }},
                current_timestamp as _scd2_record_updated_at
            from {{ this }} as this
            inner join _src on this.{{ entity_key }} = _src.{{ entity_key }}
            where this._scd2_valid_to = '{{ last_valid_to }}'::timestamp
        ),

        _union_records as (
            select *
            from _src
            union all
            select *
            from _last_valid_records
        ),

        _valid_to_from as (
            select
                *,
                {{ loaded_at }} as _scd2_valid_from,
                coalesce(
                    {{ deleted_at }},
                    lead(_scd2_valid_from) over (
                        partition by {{ entity_key }} order by _scd2_valid_from
                    ),
                    '{{ last_valid_to }}'::timestamp
                ) as _scd2_valid_to
            from _union_records
        ),

        _filter_out_deleted_duplicates as (
            select *
            from _valid_to_from
            qualify
                row_number() over (
                    partition by _hist_record_hash order by _scd2_valid_to
                )
                = 1
        ),

        _macro_final as (select * from _filter_out_deleted_duplicates)

    select *
    from _macro_final

{% endmacro %}

{% macro _scd2__full_refresh(from, unique_key, entity_key, updated_at, loaded_at, deleted_at, first_valid_from, last_valid_to) %}
    with
        _src as (
            select
                *,
                min({{ loaded_at }}) over (partition by 1)
                = {{ loaded_at }} as _first_loaded
            from {{ from }}
        ),

        _valid_to_from as (
            select
                * exclude _first_loaded,
                case
                    when _first_loaded
                    then '{{ first_valid_from }}'::timestamp
                    else {{ loaded_at }}
                end as _scd2_valid_from,
                coalesce(
                    {{ deleted_at }},
                    lead(_scd2_valid_from) over (
                        partition by {{ entity_key }} order by _scd2_valid_from
                    ),
                    '{{ last_valid_to }}'::timestamp
                ) as _scd2_valid_to
            from _src
        ),

        _meta_data as (
            select *, current_timestamp as _scd2_record_updated_at, from _valid_to_from
        ),

        _macro_final as (select * from _meta_data)
    select *
    from _macro_final
{% endmacro %}
