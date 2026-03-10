select 1 as id, '2024-01-01'::timestamp as t, 'foo' as val
union all
select 2 as id, '2024-01-01'::timestamp as t, 'foo' as val
union all
select 1 as id, '2024-02-01'::timestamp as t, 'foo' as val
union all
select 2 as id, '2024-02-01'::timestamp as t, 'foo' as val
union all
select 1 as id, '2024-03-01'::timestamp as t, 'bar' as val

--union all
--select 2 as id, '2024-03-01'::timestamp as t, 'bar' as val

--union all
--select 1 as id, '2024-04-01'::timestamp as t, 'foo' as val
--union all
--select 2 as id, '2024-04-01'::timestamp as t, 'foo' as val

--union all
--select 1 as id, '2024-05-01'::timestamp as t, 'foo' as val
--union all
--select 2 as id, '2024-05-01'::timestamp as t, 'foo' as val

--union all
--select 1 as id, '2024-06-01'::timestamp as t, 'bar' as val
--union all
--select 2 as id, '2024-06-01'::timestamp as t, 'bar' as val
