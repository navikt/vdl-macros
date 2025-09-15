{% macro scd2(
    from,
    unique_key="_hist_record_hash",
    entity_key="_hist_entity_key_hash",
    updated_at="_hist_record_updated_at",
    loaded_at="_hist_loaded_at",
    deleted_at="_hist_entity_key_deleted_at",
    created_at="_hist_record_created_at",
    first_valid_from="1900-01-01 00:00:00+01:00",
    last_valid_to="9999-01-01 23:59:59+01:00"
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
                        from=from, entity_key=entity_key, updated_at=updated_at, loaded_at=loaded_at, deleted_at=deleted_at, last_valid_to=last_valid_to
                    )
                }}
            {% else %}
                {{
                    vdl_macros._scd2__full_refresh(
                        from=from, entity_key=entity_key, loaded_at=loaded_at, deleted_at=deleted_at, first_valid_from=first_valid_from, last_valid_to=last_valid_to
                    )
                }}
            {% endif %}
        ),

        _scd2_rename_cols as (
            select
                {{ unique_key }} as pk_{{ var("this_name", this.name) }},
                {{ entity_key }} as ek_{{ var("this_name", this.name) }},
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

{% macro _scd2__incremental(from, entity_key, updated_at, loaded_at, deleted_at, last_valid_to) %}
    with
        _src as (
            select
                *,
                null as _scd2_valid_from,
                current_timestamp as _scd2_record_updated_at,
            from {{ from }}
            where {{ updated_at }} > (select max({{ updated_at }}) from {{ this }})
        ),

        _last_valid_records as (
            select
                this.* exclude(
                    pk_{{ var("this_name", this.name) }},
                    ek_{{ var("this_name", this.name) }},
                    lastet_tidspunkt,
                    oppdatert_tidspunkt,
                    opprettet_tidspunkt,
                    gyldig_fra,
                    gyldig_til,
                    _scd2_valid_from,
                    _scd2_valid_to,
                    _scd2_record_updated_at
                ),
                this._scd2_valid_from,
                current_timestamp as _scd2_record_updated_at
            from {{ this }} as this
            inner join
                _src
                on this.{{ entity_key }} = _src.{{ entity_key }}
                and _src.{{ deleted_at }} is null
            where this._scd2_valid_to = '{{ last_valid_to }}'::timestamp_ltz
        ),

        _union_records as (
            select *
            from _src
            union all
            select *
            from _last_valid_records
        ),

        _valid_from as (
            select
                * exclude _scd2_valid_from,
                coalesce(_scd2_valid_from, {{ loaded_at }}) as _scd2_valid_from
            from _union_records
        ),

        _valid_to as (
            select
                *,
                coalesce(
                    {{ deleted_at }},
                    lead(_scd2_valid_from) over (
                        partition by {{ entity_key }} order by _scd2_valid_from
                    ),
                    '{{ last_valid_to }}'::timestamp_ltz
                ) as _scd2_valid_to
            from _valid_from
        ),

        _macro_final as (select * from _valid_to)

    select *
    from _macro_final

{% endmacro %}

{% macro _scd2__full_refresh(from, entity_key, loaded_at, deleted_at, first_valid_from, last_valid_to) %}
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
                    then '{{ first_valid_from }}'::timestamp_ltz
                    else {{ loaded_at }}
                end as _scd2_valid_from,
                coalesce(
                    {{ deleted_at }},
                    lead(_scd2_valid_from) over (
                        partition by {{ entity_key }} order by _scd2_valid_from
                    ),
                    '{{ last_valid_to }}'::timestamp_ltz
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
