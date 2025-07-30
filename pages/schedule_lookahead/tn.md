---
title: Tennessee/Mississippi
---
<Dropdown data={payperiods} name=payperiod_select label=display value=period_number title="Select a Pay Period" defaultValue={dd_default[0].current_default}/>






```sql payperiods
WITH RECURSIVE
base_info AS (
    SELECT
        DATE '2025-06-01' as base_date,
        CAST(FLOOR(date_diff('day', DATE '2025-06-01', current_date()) / 14) + 1 as BIGINT) as current_period
),
pay_periods AS (
    SELECT
        base_date + INTERVAL (n * 14) DAY as period_start,
        base_date + INTERVAL (n * 14 + 13) DAY as period_end,
        n+1 as period_number,
        current_period
    FROM base_info, generate_series(0, current_period) as t(n)
)
SELECT 
    period_number,
    period_start,
    period_end,
    CASE 
        WHEN CURRENT_DATE BETWEEN period_start AND period_end THEN 'CURRENT'
        WHEN period_number = current_period + 1 THEN 'NEXT'
        ELSE 'PAST'
    END as period_status,
    strftime(period_start, '%m/%d') || ' - ' || strftime(period_end, '%m/%d') as display
FROM pay_periods
ORDER BY period_start
```

```sql dd_default
select display as current_default 
FROM ${payperiods} 
WHERE period_status = 'CURRENT' 
LIMIT 1
```

```sql schedule
select 
    shift_name,
    strftime(start_time, '%H%M') as start_time,
    strftime(end_time, '%H%M') as end_time,
    strftime(date_line,'%A - %m/%d') as date_line,
    list_extract(crew_names, 1) as crew_1,
    crew_names[1] as crew_2
from warehouse.schedule
where date_line between (select period_start from ${payperiods} where period_number = ${inputs.payperiod_select.value}) and (select period_end from ${payperiods} where period_number = ${inputs.payperiod_select.value})
AND warehouse.schedule.source_databases = 'tn'
```

