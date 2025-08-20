{% macro hist(from, entity_key, check_cols, loaded_at) %}
    {{
        config(
            materialized="incremental",
            unique_key="_hist_record_hash",
            on_schema_change="fail",
        )
    }}

    {% if is_incremental() %}
        {{ vdl_macros._hist__incremental(from, entity_key, check_cols, loaded_at) }}
    {% else %} {{ vdl_macros._hist__full_refresh(from, entity_key, check_cols, loaded_at) }}
    {% endif %}
{% endmacro %}

{% macro _hist__incremental(from, entity_key, check_cols, loaded_at) %}
    with
        src as (
            select *
            from {{ from }}
            where {{ loaded_at }} > (select max(_hist_loaded_at) from {{ this }})
        ),

        src_hash as (
            select
                *,
                {{ dbt_utils.generate_surrogate_key(entity_key) }}
                as _hist_entity_key_hash,
                {{ dbt_utils.generate_surrogate_key(check_cols) }}
                as _hist_check_cols_hash,
                {{ loaded_at }} as _hist_loaded_at,
                current_timestamp as _hist_record_created_at,
            from src
        ),

        last_records as (
            select *
            from {{ this }} as this
            qualify
                max(_hist_loaded_at) over (partition by _hist_entity_key_hash)
                = this._hist_loaded_at
        ),

        union_records as (
            select *, null as _hist_old_record_was_deleted
            from src_hash
            union all
            select
                * exclude(
                    _hist_entity_key_hash,
                    _hist_check_cols_hash,
                    _hist_loaded_at,
                    _hist_entity_key_next_load_time,
                    _hist_next_loaded_at,
                    _hist_entity_key_is_deleted,
                    _hist_entity_key_deleted_at,
                    _hist_last_check_cols_hash,
                    _hist_last_entity_key_is_deleted,
                    _hist_record_has_change,
                    _hist_new_ek,
                    _hist_record_hash,
                    _hist_input__from,
                    _hist_input__entity_key,
                    _hist_input__check_cols,
                    _hist_input__loaded_at,
                    _hist_record_created_at,
                    _hist_record_updated_at
                ),
                _hist_entity_key_hash,
                _hist_check_cols_hash,
                _hist_loaded_at,
                _hist_record_created_at,
                _hist_entity_key_is_deleted as _hist_old_record_was_deleted
            from last_records
        ),

        entity_key_load_times as (
            select
                *,
                lead(_hist_loaded_at) over (
                    partition by _hist_entity_key_hash order by _hist_loaded_at
                ) as _hist_entity_key_next_load_time,
            from union_records
        ),

        unique_load_times as (
            select distinct _hist_loaded_at,
            from src_hash
            union all
            select max(_hist_loaded_at) as _hist_loaded_at,
            from {{ this }}
            order by 1
        ),

        load_times as (
            select
                _hist_loaded_at,
                lead(_hist_loaded_at) over (
                    order by _hist_loaded_at
                ) as _hist_next_loaded_at
            from unique_load_times
        ),

        deletes as (
            select
                entity_key_load_times.* exclude(_hist_old_record_was_deleted),
                load_times._hist_next_loaded_at,
                case
                    when entity_key_load_times._hist_old_record_was_deleted
                    then true
                    when
                        entity_key_load_times._hist_entity_key_next_load_time
                        != load_times._hist_next_loaded_at
                    then true
                    when
                        entity_key_load_times._hist_entity_key_next_load_time is null
                        and load_times._hist_next_loaded_at is not null
                    then true
                    else false
                end as _hist_entity_key_is_deleted,
                case
                    when _hist_entity_key_is_deleted
                    then load_times._hist_next_loaded_at
                    else null
                end as _hist_entity_key_deleted_at
            from entity_key_load_times
            left join
                load_times
                on entity_key_load_times._hist_loaded_at = load_times._hist_loaded_at
        ),

        --
        last_values as (
            select
                *,
                lag(_hist_check_cols_hash, 1, '1') over (
                    partition by _hist_entity_key_hash order by _hist_loaded_at
                ) _hist_last_check_cols_hash,
                lag(_hist_entity_key_is_deleted, 1, false) over (
                    partition by _hist_entity_key_hash order by _hist_loaded_at
                ) _hist_last_entity_key_is_deleted,
            from deletes
        ),

        changed_records as (
            select
                *,
                case
                    when _hist_last_entity_key_is_deleted
                    then true
                    when _hist_entity_key_is_deleted
                    then true
                    when _hist_check_cols_hash != _hist_last_check_cols_hash
                    then true
                end as _hist_record_has_change
            from last_values
            where _hist_record_has_change
        ),

        meta_columns as (
            select
                *,
                _hist_last_check_cols_hash = '1' as _hist_new_ek,
                {{ dbt_utils.generate_surrogate_key(entity_key + ["_hist_loaded_at"]) }}
                as _hist_record_hash,
                '{{ from }}' as _hist_input__from,
                {{ entity_key }} as _hist_input__entity_key,
                {{ check_cols }} as _hist_input__check_cols,
                '{{ loaded_at }}' as _hist_input__loaded_at,
                current_timestamp as _hist_record_updated_at
            from changed_records
        ),

        filter_out_existing_records as (
            -- TODO: Kan kanskje sjekke det her på en annen måte?
            select meta_columns.*
            from meta_columns
            left join
                {{ this }} this
                on meta_columns._hist_record_hash = this._hist_record_hash
                and meta_columns._hist_last_entity_key_is_deleted
                = this._hist_last_entity_key_is_deleted
                and meta_columns._hist_entity_key_is_deleted
                = this._hist_entity_key_is_deleted
            where this._hist_record_hash is null
        ),

        final as (select * from filter_out_existing_records)

    select *
    from final
{% endmacro %}

{% macro _hist__full_refresh(from, entity_key, check_cols, loaded_at) %}
    with
        src as (
            select
                *,
                {{ dbt_utils.generate_surrogate_key(entity_key) }}
                as _hist_entity_key_hash,
                {{ dbt_utils.generate_surrogate_key(check_cols) }}
                as _hist_check_cols_hash,
                {{ loaded_at }} as _hist_loaded_at,
            from {{ from }}
        ),

        entity_key_load_times as (
            select
                *,
                lead(_hist_loaded_at) over (
                    partition by _hist_entity_key_hash order by _hist_loaded_at
                ) as _hist_entity_key_next_load_time,
            from src
        ),

        unique_load_times as (
            select distinct _hist_loaded_at, from src order by _hist_loaded_at
        ),

        load_times as (
            select
                _hist_loaded_at,
                lead(_hist_loaded_at) over (
                    order by _hist_loaded_at
                ) as _hist_next_loaded_at
            from unique_load_times
        ),

        deletes as (
            select
                entity_key_load_times.*,
                load_times._hist_next_loaded_at,
                case
                    when
                        entity_key_load_times._hist_entity_key_next_load_time
                        != load_times._hist_next_loaded_at
                    then true
                    when
                        entity_key_load_times._hist_entity_key_next_load_time is null
                        and load_times._hist_next_loaded_at is not null
                    then true
                    else false
                end as _hist_entity_key_is_deleted,
                case
                    when _hist_entity_key_is_deleted
                    then load_times._hist_next_loaded_at
                    else null
                end as _hist_entity_key_deleted_at
            from entity_key_load_times
            left join
                load_times
                on entity_key_load_times._hist_loaded_at = load_times._hist_loaded_at
        ),

        last_values as (
            select
                *,
                lag(_hist_check_cols_hash, 1, '1') over (
                    partition by _hist_entity_key_hash order by _hist_loaded_at
                ) _hist_last_check_cols_hash,
                lag(_hist_entity_key_is_deleted, 1, false) over (
                    partition by _hist_entity_key_hash order by _hist_loaded_at
                ) _hist_last_entity_key_is_deleted,
            from deletes
        ),

        changed_records as (
            select
                *,
                case
                    when _hist_last_entity_key_is_deleted
                    then true
                    when _hist_entity_key_is_deleted
                    then true
                    when _hist_check_cols_hash != _hist_last_check_cols_hash
                    then true
                end as _hist_record_has_change
            from last_values
            where _hist_record_has_change
        ),

        meta_columns as (
            select
                changed_records.*,
                _hist_last_check_cols_hash = '1' as _hist_new_ek,
                {{ dbt_utils.generate_surrogate_key(entity_key + [loaded_at]) }}
                as _hist_record_hash,
                '{{ from }}' as _hist_input__from,
                {{ entity_key }} as _hist_input__entity_key,
                {{ check_cols }} as _hist_input__check_cols,
                '{{ loaded_at }}' as _hist_input__loaded_at,
            from changed_records
        ),

        record_timestamps as (
            select
                meta_columns.*,
                current_timestamp as _hist_record_created_at,
                current_timestamp as _hist_record_updated_at
            from meta_columns
        ),

        final as (select * from record_timestamps)

    select *
    from final
    order by _hist_loaded_at, _hist_entity_key_hash
{% endmacro %}
