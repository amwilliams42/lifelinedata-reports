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
        (n+1)::VARCHAR as period_number,  -- Convert to string here
        current_period
    FROM base_info, generate_series(0, current_period) as t(n)
)
SELECT 
    period_number,
    period_start,
    period_end,
    CASE 
        WHEN CURRENT_DATE BETWEEN period_start AND period_end THEN 'CURRENT'
        WHEN period_number::INTEGER = current_period + 1 THEN 'NEXT'
        ELSE 'PAST'
    END as period_status,
    strftime(period_start, '%m/%d') || ' - ' || strftime(period_end, '%m/%d') as display
FROM pay_periods
ORDER BY period_start
```

```sql dd_default
select period_number::varchar as current_default 
FROM ${payperiods} 
WHERE period_status = 'PAST'
ORDER BY period_number DESC 
LIMIT 1
```


```sql global_results
SELECT
    run_number::INTEGER::VARCHAR as run_number,
    name,
    hourly_wage,
    ROUND(time_on_task, 2) as time_on_task,
    CASE
        WHEN hourly_wage < 19.36
        THEN ROUND((19.36 - hourly_wage) * time_on_task, 2)
        ELSE 0.00
    END AS additional_pay,
    name || ' - ' || hourly_wage as display
FROM warehouse.va_pay_list
WHERE time_on_task IS NOT NULL
    AND hourly_wage < 19.36
AND leg_date BETWEEN 
    (select period_start from ${payperiods} where period_number = '${inputs.payperiod_select.value}') 
    and 
    (select period_end from ${payperiods} where period_number = '${inputs.payperiod_select.value}')
ORDER BY hourly_wage, name, run_number
```


{#if dd_default[0].current_default}
<Dropdown data={payperiods} name=payperiod_select label=display value=period_number defaultValue={dd_default[0].current_default} title="Select a Pay Period"/>
{/if}

<Grid cols=2>
    <DataTable data={global_results} groupBy=display subtotals=true totalRow=true groupsOpen=false accordionRowColor=whitesmoke>
        <Column id=run_number/>
        <Column id=time_on_task />
        <Column id=additional_pay fmt=usd/>
    </DataTable>
</Grid>

