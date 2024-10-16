{% macro create_alert(
    name,
    message,
    query,
    integration,
    warehouse=true,
    schedule="using cron 0-59/10 6-19 * * * Europe/Oslo",
    database=target.database,
    schema=var("alert_schema")
) %}
    {% set slack_integrations = {
        "slack_test": "slack_test_webhook_int",
        "slack_alert": "slack_alert_webhook_int",
        "slack_info": "slack_info_webhook_int",
    } %}

    {% if integration not in slack_integrations.keys() %}
        {{
            exceptions.raise_compiler_error(
                "Invalid `integration`. Got: "
                ~ integration
                ~ ".\nAvailable integrations: "
                ~ slack_integrations
            )
        }}
    {% endif %}

    {% set sql %}
        create or replace alert {{ database }}.{{ schema }}.{{ name }}
        schedule = '{{ schedule }}'
        {% if warehouse %}
            warehouse = 'regnskap_streamer'
        {% endif %}
        if(exists ({{ query }}))
        then
            call system$send_snowflake_notification(
                snowflake.notification.text_plain(
                    snowflake.notification.sanitize_webhook_content('{{ message }}')
                ),
                snowflake.notification.integration('{{ slack_integrations[integration] }}')
            );
    {% endset %}

    {% do run_query(sql) %}
    {% set resume %}
      alter alert {{ database }}.{{ schema }}.{{ name }} resume;
    {% endset %}
    {% do run_query(resume) %}

    {{ log("Alert " ~ name ~ " is created successfully", info=True) }}
{% endmacro %}
