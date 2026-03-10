{{ config(schema="tests") }}

select '{{ ref("dummy") }}' as ref, '{{ this_rel() }}' as this
from {{ ref("dummy") }}
