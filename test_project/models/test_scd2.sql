{{ vdl_macros.scd2(
    from=ref("test_scd2_src"),
    unique_key="unique_key",
    entity_key="entity_key",
    updated_at="updated_at",
    loaded_at="loaded_at",
    deleted_at="deleted_at",
    created_at="created_at",
    first_valid_from="1900-01-01 00:00:00",
    last_valid_to="9999-01-01 23:59:59"
) }}
