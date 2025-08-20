# Macro Reference

## convert_dbt_snapshot

A 'run-operation' macro that creates a append only history table of daily snapshots of the entire dataset from a dbt snapshot table from the first dbt_valid_to to the current date.

### Usage

```
dbt run-operation convert_dbt_snapshot --args '{
  "from": "your_dbt_snapshot_table",
  "to": "your_target_table"
}'
```

### Arguments

**from**
 - **type:** relation
 - **description:** The dbt snapshot table you want to convert to a daily snapshot history table.

**to**
 - **type:** relation
 - **description:** The target table where the daily snapshot of the history will be stored.

**loaded_at_column_name**
 - **type:** optional[column]
 - **description:** The name of the column that will be used to store the timestamp of when the row was loaded. If not provided, it defaults to '_loaded_at'

**exclude_columns**
 - **type:** optional[list[column]]
 - **description:** A list of columns to exclude from the snapshot history table. If not provided, all columns will be included except columns added by dbt snapshot.

**exclude_dbt_columns**
 - **type:** optional[list[column]]
 - **description:** A list of columns that are added by dbt snapshot to exclude from the snapshot history table.


## scd2

Creates a slowly changing dimension (SCD) table from a table created by the hist-macro.

### Usage

```
{{ vdl_macros.scd2(from=ref("hist_oebs__hierarki")) }}
```

### Arguments

**from**
 - **type:** relation
 - **description:** The table created by the hist-macro that you want to convert to a slowly changing dimension.

**unique_key**
 - **type:** optional[column]
 - **description:** The column in the <from> table that uniquely identifies a record. If not provided, it defaults to '_hist_record_hash'.

**entity_key**
 - **type:** optional[column]
 - **description:** The column in the <from> table that identifies the entity for the slowly changing dimension. If not provided, it defaults to '_hist_entity_key_hash'.

**updated_at**
 - **type:** optional[column]
 - **description:** The column containing timestamp of when the row was updated in the <from> table. If not provided, it defaults to '_hist_record_updated_at'.

**loaded_at**
 - **type:** optional[column]
 - **description:** The column containing timestamp of when the row was loaded in the <from> table. If not provided, it defaults to '_hist_loaded_at'.

**deleted_at**
 - **type:** optional[column]
 - **description:** The column containing timestamp of when the entity_key was deleted in the <from> table. If not provided, it defaults to '_hist_entity_key_deleted_at'.

**created_at**
 - **type:** optional[column]
 - **description:** The column containing timestamp of when the record was created in the <from> table. If not provided, it defaults to '_hist_record_created_at'.

**first_valid_from**
 - **type:** string
 - **description:** A string in valid timestamp format representing the first valid from date used on records with the lowest <loaded_at> value. If not provided, it defaults to '1900-01-01 00:00:00'.

**last_valid_to**
 - **type:** string
 - **description:** A string in valid timestamp format representing the last valid to date used on latest record for each entity key with the highest <loaded_at> value. If not provided, it defaults to '9999-12-31 23:59:59'.


## create_alert

A 'run-operation' macro that creates an alert that sends a notification to slack when the given query is true. Alerts needs to be created using a dbt-profile with role set to 'accountadmin'. See snowflake documentation for more info. ref: https://docs.snowflake.com/en/user-guide/alerts https://docs.getdbt.com/reference/commands/run-operation

### Usage

```
None
```

### Arguments

**name**
 - **type:** string
 - **description:** The name of the alert

**message**
 - **type:** string
 - **description:** The message sendt with the notification

**query**
 - **type:** string
 - **description:** The query to run to check if the alert should be triggered

**integration**
 - **type:** string
 - **description:** The slack integration to use. See slack_integrations in macro for available integrations.

**warehouse**
 - **type:** bool
 - **description:** Use warehouse to run the query. If false, the query will be run in serverless mode.

**schedule**
 - **type:** string
 - **description:** The schedule for the alert. See snowflake documentation for valid schedules. ref: https://docs.snowflake.com/en/sql-reference/sql/create-alert#required-parameters

**database**
 - **type:** string
 - **description:** The database where the alert is created

**schema**
 - **type:** string
 - **description:** The schema where the alert is created


## hist

Creates a compromised history of changes to the specified entity keys from a append only table containing daily full snapshot.

### Usage

```
{{
  vdl_macros.hist(
    from=source("oebs", "hierarki"),
    entity_key=["hierarchy_code", "flex_value_id"],
    check_cols=[
        "flex_value",
        "description",
        "flex_value_id_parent",
        "flex_value_parent",
        "description_parent",
        "flex_value_set_name",
    ],
    loaded_at="_loaded_at",
  )
}}
```

### Arguments

**from**
 - **type:** relation
 - **description:** The append only table containing daily full snapshot you want to make history for.

**entity_key**
 - **type:** column
 - **description:** The entity key(s) column in the <from> table that uniquely identify a record to track changes to.

**check_cols**
 - **type:** list[column]
 - **description:** The columns in the <from> table to check for changes.

**loaded_at**
 - **type:** column
 - **description:** The column containing timestamp of when the row was loaded in the <from> table.


