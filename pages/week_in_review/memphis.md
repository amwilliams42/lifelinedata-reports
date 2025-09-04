---
  title: Memphis/Mississippi
---

```sql top5s
WITH base AS (
  SELECT
    r.calltype_name,
    r.pickup_facility AS facility,
    COUNT(*) OVER (PARTITION BY r.calltype_name, r.pickup_facility) AS cnt_rt,
    COUNT(*) OVER (PARTITION BY r.pickup_facility) AS cnt_total,
    ROW_NUMBER() OVER (PARTITION BY r.calltype_name, r.pickup_facility ORDER BY r.leg_id) AS dedup_rt,
    ROW_NUMBER() OVER (PARTITION BY r.pickup_facility ORDER BY r.leg_id) AS dedup_total
  FROM warehouse.tn_runs r
  WHERE r.calltype_name IN ('ALS', 'BLS', 'CCT')
  and r.date_of_service between '2025-08-24' and '2025-08-31'
  and (r.market = 'Memphis' or r.market = 'Mississippi')
),
per_type AS (
  SELECT
    calltype_name AS run_group,
    facility,
    cnt_rt AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY calltype_name
      ORDER BY cnt_rt DESC, facility
    ) AS rn
  FROM base
  WHERE dedup_rt = 1
),
tot AS (
  SELECT
    'TOTAL' AS run_group,
    facility,
    cnt_total AS cnt,
    ROW_NUMBER() OVER (
      ORDER BY cnt_total DESC, facility
    ) AS rn
  FROM base
  WHERE dedup_total = 1
)
SELECT
  run_group,
  facility,
  cnt
FROM (
  SELECT * FROM per_type
  UNION ALL
  SELECT * FROM tot
) x
WHERE rn <= 5
ORDER BY
  CASE run_group
    WHEN 'ALS' THEN 1
    WHEN 'BLS' THEN 2
    WHEN 'CCT' THEN 3
    WHEN 'TOTAL' THEN 4
    ELSE 5
  END,
  cnt DESC,
  facility
```

```sql calltypes
select distinct run_group from ${top5s}
```
## Top 5 Origins By Call Type
<Grid cols=2>
  {#each calltypes as row}
    <Group>
        <DataTable data={top5s.where(`run_group = '${row.run_group}'`)}>
            <Column id=facility title='{row.run_group}'/>
            <Column id=cnt title='Count' />
        </DataTable>    
    </Group>
  {/each}
</Grid>

```sql week_dates

-- Extract the start date from your date range and calculate each day of the week
with date_range as (
  select 
    DATE '2025-08-24' as start_date,
    DATE '2025-08-31' as end_date
),
week_calc as (
  select 
    start_date,
    -- Find the Sunday of that week (DuckDB dayofweek: 0=Sunday, 6=Saturday)
    start_date - INTERVAL (dayofweek(start_date)) DAYS as week_sunday
  from date_range
)
select 
  'Sunday ' || strftime(week_sunday, '%m/%d') as sunday_header,
  'Monday ' || strftime(week_sunday + INTERVAL 1 DAY, '%m/%d') as monday_header,
  'Tuesday ' || strftime(week_sunday + INTERVAL 2 DAYS, '%m/%d') as tuesday_header,
  'Wednesday ' || strftime(week_sunday + INTERVAL 3 DAYS, '%m/%d') as wednesday_header,
  'Thursday ' || strftime(week_sunday + INTERVAL 4 DAYS, '%m/%d') as thursday_header,
  'Friday ' || strftime(week_sunday + INTERVAL 5 DAYS, '%m/%d') as friday_header,
  'Saturday ' || strftime(week_sunday + INTERVAL 6 DAYS, '%m/%d') as saturday_header
from week_calc

```



```sql by_source

with call_types(calltype_name) as (
  VALUES ('ALS'), ('BLS'), ('CCT')
),
sources AS (
  select distinct r.source_id
  from warehouse.tn_runs r
)

SELECT
  s.source_id,
  r.source_name,
  ct.calltype_name,
  COALESCE(SUM(CASE WHEN day_of_week = 'Monday'    THEN 1 END), 0) AS monday,
  COALESCE(SUM(CASE WHEN day_of_week = 'Tuesday'   THEN 1 END), 0) AS tuesday,
  COALESCE(SUM(CASE WHEN day_of_week = 'Wednesday' THEN 1 END), 0) AS wednesday,
  COALESCE(SUM(CASE WHEN day_of_week = 'Thursday'  THEN 1 END), 0) AS thursday,
  COALESCE(SUM(CASE WHEN day_of_week = 'Friday'    THEN 1 END), 0) AS friday,
  COALESCE(SUM(CASE WHEN day_of_week = 'Saturday'  THEN 1 END), 0) AS saturday,
  COALESCE(SUM(CASE WHEN day_of_week = 'Sunday'    THEN 1 END), 0) AS sunday
FROM sources s
cross join call_types ct
left join warehouse.tn_runs r 
  on r.calltype_name = ct.calltype_name
  and r.source_id = s.source_id
  and r.date_of_service between '2025-08-24' and '2025-08-31'
  and r.run_outcome = 'ran'
GROUP BY s.source_id, r.source_name, ct.calltype_name
ORDER BY s.source_id, ct.calltype_name
```

```sql sources_of_interest

select * from

(values (1, 'Methodist IOC'), (13, 'Memphis VA'), (30, 'St. Jude'), (21, 'Baptist Priority Ambulance')) as t(id, name)


```
## Calltype by Selected Source by Day
<Grid cols=2>

{#each sources_of_interest as row}
<Group>
  <Value data={row} column=name/>
  <DataTable data={by_source.where(`source_id = '${row.id}'`)} wrapTitles=true>
    <Column id=calltype_name title='Calltype'/>
    <Column id=sunday title={week_dates[0].sunday_header} align=center/>
    <Column id=monday title={week_dates[0].monday_header} align=center/>
    <Column id=tuesday title={week_dates[0].tuesday_header} align=center/>
    <Column id=wednesday title={week_dates[0].wednesday_header} align=center/>
    <Column id=thursday title={week_dates[0].thursday_header} align=center/>
    <Column id=friday title={week_dates[0].friday_header} align=center/>
    <Column id=saturday title={week_dates[0].saturday_header} align=center/>

  </DataTable>
</Group>

{/each}

</Grid>



