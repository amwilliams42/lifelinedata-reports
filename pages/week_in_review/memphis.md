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
  and r.date_of_service between '2025-08-24' and '2025-08-30'
  and (r.market = 'Memphis' or r.market = 'Mississippi')
  -- AND rl.location_role IN ('ORIGIN', 'DESTINATION')  -- optional: avoid double-counting
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
<Grid cols=2>
    {#each calltypes as row}
        <DataTable data={top5s.where(`run_group = '${row.run_group}'`)}>
            <Column id=facility/>
            <Column id=cnt title='Count' />
        
        </DataTable>
    
    {/each}
</Grid>