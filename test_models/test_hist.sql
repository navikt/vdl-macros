{{
    hist(
        from=ref("test_hist_src"),
        entity_key=["id"],
        check_cols=["val"],
        loaded_at="t",
    )
}}
