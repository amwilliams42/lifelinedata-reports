---
  title: Memphis/Mississippi
---

```sql start_and_end_dates
select 
  strftime(
    date_trunc('week', make_date(2025, 1, 1) + interval '7' day * (${params.week} - 1)) - interval '1' day,
    '%Y-%m-%d'
  ) as start,
  strftime(
    date_trunc('week', make_date(2025, 1, 1) + interval '7' day * (${params.week} - 1)) - interval '1' day + interval '6' days,
    '%Y-%m-%d'
  ) as end,
    strftime(
    date_trunc('week', make_date(2025, 1, 1) + interval '7' day * (${params.week} - 1)) + interval '6' days,
    '%Y-%m-%d'
  ) as end_plus_one
```


```sql test
  SELECT
    SUM(CASE WHEN r.run_outcome = 'ran'    THEN 1 ELSE 0 END) AS ran_calls,
    SUM(CASE WHEN r.run_outcome = 'turned' THEN 1 ELSE 0 END) AS turned_calls
  FROM warehouse.tn_runs r
  WHERE r.date_of_service BETWEEN DATE '${start_and_end_dates[0].start}' AND DATE '${start_and_end_dates[0].end_plus_one}'

```



```sql glance
WITH curr AS (
  SELECT
    SUM(CASE WHEN r.run_outcome = 'ran'    THEN 1 ELSE 0 END) AS ran_calls,
    SUM(CASE WHEN r.run_outcome = 'turned' THEN 1 ELSE 0 END) AS turned_calls
  FROM warehouse.tn_runs r
  WHERE r.date_of_service BETWEEN DATE '${start_and_end_dates[0].start}' AND DATE '${start_and_end_dates[0].end_plus_one}'
),
prev AS (
  SELECT
    SUM(CASE WHEN r.run_outcome = 'ran'    THEN 1 ELSE 0 END) AS ran_calls,
    SUM(CASE WHEN r.run_outcome = 'turned' THEN 1 ELSE 0 END) AS turned_calls
  FROM warehouse.tn_runs r
  WHERE r.date_of_service BETWEEN (DATE '${start_and_end_dates[0].start}' - INTERVAL 7 DAY) AND (DATE '${start_and_end_dates[0].end_plus_one}' - INTERVAL 7 DAY)
)
SELECT
  -- Big Values (current window)
  CAST(c.ran_calls AS INTEGER)                                                                AS ran_calls,
  CAST(c.turned_calls AS INTEGER)                                                             AS turned_calls,
  CAST(c.ran_calls + c.turned_calls AS INTEGER)                                               AS total_demand,
  CAST(c.ran_calls AS DOUBLE) / NULLIF(CAST(c.ran_calls + c.turned_calls AS DOUBLE), 0)       AS capture_rate,

  -- Week-over-week comparisons (current vs prior window)
  (CAST(c.ran_calls AS DOUBLE)    - CAST(p.ran_calls AS DOUBLE))    / NULLIF(CAST(p.ran_calls AS DOUBLE), 0)        AS ran_calls_growth,
  (CAST(c.turned_calls AS DOUBLE) - CAST(p.turned_calls AS DOUBLE)) / NULLIF(CAST(p.turned_calls AS DOUBLE), 0)     AS turned_calls_growth,
  (CAST(c.ran_calls + c.turned_calls AS DOUBLE)
   - CAST(p.ran_calls + p.turned_calls AS DOUBLE))
   / NULLIF(CAST(p.ran_calls + p.turned_calls AS DOUBLE), 0)                                                           AS total_demand_growth,
  (CAST(c.ran_calls AS DOUBLE) / NULLIF(CAST(c.ran_calls + c.turned_calls AS DOUBLE), 0))
  - (CAST(p.ran_calls AS DOUBLE) / NULLIF(CAST(p.ran_calls + p.turned_calls AS DOUBLE), 0))                            AS capture_rate_change,
FROM curr c
CROSS JOIN prev p
```

<BigValue 
  data={glance} 
  value=ran_calls
  comparison=ran_calls_growth
  comparisonFmt=pct1
  comparisonTitle="WoW"
/>
<BigValue 
  data={glance} 
  value=turned_calls
  comparison=turned_calls_growth
  comparisonFmt=pct1
  comparisonTitle="WoW"
/>
<BigValue 
  data={glance} 
  value=total_demand
  comparison=total_demand_growth
  comparisonFmt=pct1
  comparisonTitle="WoW"
/>
<BigValue 
  data={glance} 
  value=capture_rate
  valueFmt=pct1
  fmt=pct1
  comparison=capture_rate_change
  comparisonFmt=pct1
  comparisonTitle="WoW"
/>



```sql weekly_totals
WITH base AS (
  SELECT
    calltype_name,
    CASE market WHEN 'Memphis' THEN 'MEM' WHEN 'Mississippi' THEN 'MS' END AS market_abbrev,
    date_of_service,
    run_outcome
  FROM warehouse.tn_runs
  WHERE market IN ('Memphis', 'Mississippi')
    AND calltype_name IN ('ALS', 'BLS', 'CCT', 'Flight Crew')
    AND date_of_service >= DATE '${start_and_end_dates[0].start}'
    AND date_of_service <  DATE '${start_and_end_dates[0].end_plus_one}'
)
SELECT
  calltype_name,
  market,
  Sunday,
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Total
FROM (
SELECT
  t.*,
  CASE calltype_name
    WHEN 'ALS' THEN 1
    WHEN 'BLS' THEN 2
    WHEN 'CCT' THEN 3
    WHEN 'Total Ran' THEN 4
    WHEN 'Cancelled' THEN 5
    WHEN 'Turned' THEN 6
    ELSE 7
  END AS sort_calltype,
  CASE market WHEN 'MEM' THEN 1 WHEN 'MS' THEN 2 ELSE 3 END AS sort_market
FROM (
-- Detail: ran by calltype and market
SELECT
  calltype_name,
  market_abbrev AS market,
  SUM((EXTRACT(DOW FROM date_of_service) = 0)::int) AS Sunday,
  SUM((EXTRACT(DOW FROM date_of_service) = 1)::int) AS Monday,
  SUM((EXTRACT(DOW FROM date_of_service) = 2)::int) AS Tuesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 3)::int) AS Wednesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 4)::int) AS Thursday,
  SUM((EXTRACT(DOW FROM date_of_service) = 5)::int) AS Friday,
  SUM((EXTRACT(DOW FROM date_of_service) = 6)::int) AS Saturday,
  COUNT(*) AS Total
FROM base
WHERE run_outcome = 'ran'
GROUP BY calltype_name, market_abbrev

UNION ALL
-- Total Ran by market (across call types)
SELECT
  'Total Ran' AS calltype_name,
  market_abbrev AS market,
  SUM((EXTRACT(DOW FROM date_of_service) = 0)::int) AS Sunday,
  SUM((EXTRACT(DOW FROM date_of_service) = 1)::int) AS Monday,
  SUM((EXTRACT(DOW FROM date_of_service) = 2)::int) AS Tuesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 3)::int) AS Wednesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 4)::int) AS Thursday,
  SUM((EXTRACT(DOW FROM date_of_service) = 5)::int) AS Friday,
  SUM((EXTRACT(DOW FROM date_of_service) = 6)::int) AS Saturday,
  COUNT(*) AS Total
FROM base
WHERE run_outcome = 'ran'
GROUP BY market_abbrev

UNION ALL
-- Cancelled by market (across call types)
SELECT
  'Cancelled' AS calltype_name,
  market_abbrev AS market,
  SUM((EXTRACT(DOW FROM date_of_service) = 0)::int) AS Sunday,
  SUM((EXTRACT(DOW FROM date_of_service) = 1)::int) AS Monday,
  SUM((EXTRACT(DOW FROM date_of_service) = 2)::int) AS Tuesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 3)::int) AS Wednesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 4)::int) AS Thursday,
  SUM((EXTRACT(DOW FROM date_of_service) = 5)::int) AS Friday,
  SUM((EXTRACT(DOW FROM date_of_service) = 6)::int) AS Saturday,
  COUNT(*) AS Total
FROM base
WHERE run_outcome = 'cancelled'
GROUP BY market_abbrev

UNION ALL
-- Turned by market (across call types)
SELECT
  'Turned' AS calltype_name,
  market_abbrev AS market,
  SUM((EXTRACT(DOW FROM date_of_service) = 0)::int) AS Sunday,
  SUM((EXTRACT(DOW FROM date_of_service) = 1)::int) AS Monday,
  SUM((EXTRACT(DOW FROM date_of_service) = 2)::int) AS Tuesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 3)::int) AS Wednesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 4)::int) AS Thursday,
  SUM((EXTRACT(DOW FROM date_of_service) = 5)::int) AS Friday,
  SUM((EXTRACT(DOW FROM date_of_service) = 6)::int) AS Saturday,
  COUNT(*) AS Total
FROM base
WHERE run_outcome = 'turned'
GROUP BY market_abbrev
) AS t
) AS s
ORDER BY
  sort_calltype,
  sort_market

```

```sql weekly_demand_totals
WITH base AS (
  SELECT date_of_service, run_outcome
  FROM warehouse.tn_runs
  WHERE date_of_service >= DATE '${start_and_end_dates[0].start}'
    AND date_of_service <  DATE '${start_and_end_dates[0].end_plus_one}'
)
SELECT
  SUM((EXTRACT(DOW FROM date_of_service) = 0)::int) AS Sunday,
  SUM((EXTRACT(DOW FROM date_of_service) = 1)::int) AS Monday,
  SUM((EXTRACT(DOW FROM date_of_service) = 2)::int) AS Tuesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 3)::int) AS Wednesday,
  SUM((EXTRACT(DOW FROM date_of_service) = 4)::int) AS Thursday,
  SUM((EXTRACT(DOW FROM date_of_service) = 5)::int) AS Friday,
  SUM((EXTRACT(DOW FROM date_of_service) = 6)::int) AS Saturday,
  COUNT(*) AS Total
FROM base
WHERE run_outcome IN ('ran', 'turned');

```

<Grid cols=2>
  <Group>
    <h3>Ran Calls</h3>
      <DataTable data={weekly_totals.where("calltype_name in ('ALS', 'BLS', 'CCT', 'Flight Crew')")} groupBy=calltype_name totalRow=true groupType=section >
    <Column id=calltype_name title='Call Type' />
    <Column id=market totalAgg='Total Calls Ran'/>
    <Column id=Sunday title='Sun' align=center/>
    <Column id=Monday title='Mon' align=center/>
    <Column id=Tuesday title='Tue' align=center/>
    <Column id=Wednesday title='Wed' align=center/>
    <Column id=Thursday title='Thu' align=center/>
    <Column id=Friday title='Fri' align=center/>
    <Column id=Saturday title='Sat' align=center/>
    <Column id=Total title='Total' align=center/>
  </DataTable>
  </Group>
  
    <Group>
    <h3>Lost Calls</h3>
      <DataTable data={weekly_totals.where("calltype_name in ('Cancelled', 'Turned')")} groupBy=calltype_name totalRow=true groupType=section >
    <Column id=calltype_name title='Call Type' />
    <Column id=market totalAgg='Total Calls Lost'/>
    <Column id=Sunday title='Sun' align=center/>
    <Column id=Monday title='Mon' align=center/>
    <Column id=Tuesday title='Tue' align=center/>
    <Column id=Wednesday title='Wed' align=center/>
    <Column id=Thursday title='Thu' align=center/>
    <Column id=Friday title='Fri' align=center/>
    <Column id=Saturday title='Sat' align=center/>
    <Column id=Total title='Total' align=center/>
  </DataTable>
  </Group>
</Grid>


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
  and r.date_of_service between '${start_and_end_dates[0].start}' and '${start_and_end_dates[0].end_plus_one}'
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
    DATE '${start_and_end_dates[0].start}' as start_date,
    DATE '${start_and_end_dates[0].end_plus_one}' as end_date
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
  and r.date_of_service between '${start_and_end_dates[0].start}' and '${start_and_end_dates[0].end_plus_one}'
  and r.run_outcome = 'ran'
GROUP BY s.source_id, r.source_name, ct.calltype_name
ORDER BY s.source_id, ct.calltype_name
```

```sql sources_of_interest

select * from

(values (1, 'Methodist IOC'), (13, 'Memphis VA - Vetride Only'), (30, 'St. Jude'), (21, 'Baptist Priority Ambulance')) as t(id, name)


```
## Calltype by Selected Source by Day
<Grid cols=2>

{#each sources_of_interest as row}
<Group>
  <Value data={row} column=name/>
  <DataTable data={by_source.where(`source_id = '${row.id}'`)} wrapTitles=true totalRow=true>
    <Column id=calltype_name title='Calltype' totalAgg='Total'/>
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


```sql ran_heatmap
SELECT
  r.hour_of_day,          -- x-axis categorical
  r.day_of_week,          -- y-axis categorical
  SUM(CASE WHEN r.run_outcome = 'ran' THEN 1 ELSE 0 END)::int AS ran_count,
  SUM(CASE WHEN r.run_outcome  = 'turned' THEN 1 ELSE 0 END)::int AS turned_count,
  COUNT(*)::int AS call_count,
  CAST(r.hour_of_day AS int) AS xsort,
  CASE lower(r.day_of_week)
  WHEN 'sunday' THEN 1 WHEN 'monday' THEN 2 WHEN 'tuesday' THEN 3
  WHEN 'wednesday' THEN 4 WHEN 'thursday' THEN 5
  WHEN 'friday' THEN 6 WHEN 'saturday' THEN 7 ELSE 8
END AS ysort
    -- numeric sort key for x-axis (0000..2300 -> 0..2300)
FROM warehouse.tn_runs AS r
WHERE
  r.date_of_service BETWEEN '${start_and_end_dates[0].start}' AND '${start_and_end_dates[0].end_plus_one}'
GROUP BY
  r.hour_of_day,
  r.day_of_week
ORDER BY
  CASE lower(r.day_of_week)
    WHEN 'sunday'    THEN 1
    WHEN 'monday'    THEN 2
    WHEN 'tuesday'   THEN 3
    WHEN 'wednesday' THEN 4
    WHEN 'thursday'  THEN 5
    WHEN 'friday'    THEN 6
    WHEN 'saturday'  THEN 7
    ELSE 8
  END,
  xsort
```


<Heatmap 
    data={ran_heatmap}
    title='Calls Ran by Hour and Day'
    x=hour_of_day 
    y=day_of_week 
    value=ran_count 
    colorScale={[
        ['rgb(254,234,159)', 'rgb(254,234,159)'],
        ['rgb(218,66,41)', 'rgb(218,66,41)']
    ]}
    xSort=xsort
    ySort=ysort
    legend=false
/>

<Heatmap 
    data={ran_heatmap} 
    title='Calls Turned by Hour and Day'
    x=hour_of_day 
    y=day_of_week 
    value=turned_count 
    xSort=xsort
    ySort=ysort 
    legend=false
/>