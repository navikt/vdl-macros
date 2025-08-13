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


