---
title: Scheduled Hours Report
---

<Note>
  Scheduled and open hours by cost center and day of week. Select a date range to view hours broken down by shift type (Regular vs Special Events).
</Note>

```sql available_weeks
SELECT DISTINCT
  strftime((date_line - INTERVAL (EXTRACT(DOW FROM date_line)::INTEGER) DAY)::DATE, '%Y-%m-%d') AS week_start,
  strftime((date_line - INTERVAL (EXTRACT(DOW FROM date_line)::INTEGER) DAY)::DATE, '%m/%d/%Y') || ' - ' ||
  strftime((date_line - INTERVAL (EXTRACT(DOW FROM date_line)::INTEGER) DAY + INTERVAL 6 DAY)::DATE, '%m/%d/%Y') AS display
FROM warehouse.sched_hours
WHERE date_line IS NOT NULL
  AND (date_line - INTERVAL (EXTRACT(DOW FROM date_line)::INTEGER) DAY)::DATE <= DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'
ORDER BY week_start DESC
```

```sql current_week
SELECT
  strftime((CURRENT_DATE - INTERVAL (EXTRACT(DOW FROM CURRENT_DATE)::INTEGER) DAY)::DATE, '%Y-%m-%d') AS week_start
```

## Select Week

<Dropdown
  data={available_weeks}
  name=selected_week
  label=display
  value=week_start
  title="Select Week"
  defaultValue={current_week[0].week_start}
/>

<ButtonGroup name=hardcoded_options>
    <ButtonGroupItem valueLabel="Illinois" value="il" default=true/>
    <ButtonGroupItem valueLabel="Michigan" value="mi" />
    <ButtonGroupItem valueLabel="Tennessee" value="tn" />
</ButtonGroup>


```sql scheduled_hours
SELECT
  cost_center_name,
  CASE
  WHEN is_training = true THEN 'Orientation/FTO'
    WHEN source_database = 'tn' AND (cost_center_name LIKE 'Memp%' OR cost_center_name LIKE 'Miss%') AND special_event = true THEN 'Memp - Special Event'
    WHEN source_database = 'tn' AND (cost_center_name LIKE 'Memp%' OR cost_center_name LIKE 'Miss%') AND special_event = false THEN 'Memp - Regular'
    WHEN source_database = 'tn' AND cost_center_name LIKE 'Nash%' AND special_event = true THEN 'Nash - Special Event'
    WHEN source_database = 'tn' AND cost_center_name LIKE 'Nash%' AND special_event = false THEN 'Nash - Regular'
    WHEN special_event = true THEN 'Special Event'
    
    ELSE 'Regular'
  END AS shift_type,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 0 THEN scheduled_hours ELSE 0 END), 1) AS sunday_scheduled,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 1 THEN scheduled_hours ELSE 0 END), 1) AS monday_scheduled,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 2 THEN scheduled_hours ELSE 0 END), 1) AS tuesday_scheduled,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 3 THEN scheduled_hours ELSE 0 END), 1) AS wednesday_scheduled,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 4 THEN scheduled_hours ELSE 0 END), 1) AS thursday_scheduled,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 5 THEN scheduled_hours ELSE 0 END), 1) AS friday_scheduled,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 6 THEN scheduled_hours ELSE 0 END), 1) AS saturday_scheduled,
  ROUND(SUM(scheduled_hours), 1) AS total_scheduled
FROM warehouse.sched_hours
WHERE date_line >= '${inputs.selected_week.value}'::DATE
  AND date_line < '${inputs.selected_week.value}'::DATE + INTERVAL '7 days'
  AND source_database = '${inputs.hardcoded_options}'
GROUP BY cost_center_name, shift_type
ORDER BY cost_center_name, shift_type
```

```sql open_hours
SELECT
  cost_center_name,
  CASE
    WHEN is_training = true THEN 'Orientation/FTO'
    WHEN source_database = 'tn' AND (cost_center_name LIKE 'Memp%' OR cost_center_name LIKE 'Miss%') AND special_event = true THEN 'Memp - Special Event'
    WHEN source_database = 'tn' AND (cost_center_name LIKE 'Memp%' OR cost_center_name LIKE 'Miss%') AND special_event = false THEN 'Memp - Regular'
    WHEN source_database = 'tn' AND cost_center_name LIKE 'Nash%' AND special_event = true THEN 'Nash - Special Event'
    WHEN source_database = 'tn' AND cost_center_name LIKE 'Nash%' AND special_event = false THEN 'Nash - Regular'
    WHEN special_event = true THEN 'Special Event'
    ELSE 'Regular'
  END AS shift_type,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 0 THEN open_hours ELSE 0 END), 1) AS sunday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 1 THEN open_hours ELSE 0 END), 1) AS monday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 2 THEN open_hours ELSE 0 END), 1) AS tuesday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 3 THEN open_hours ELSE 0 END), 1) AS wednesday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 4 THEN open_hours ELSE 0 END), 1) AS thursday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 5 THEN open_hours ELSE 0 END), 1) AS friday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 6 THEN open_hours ELSE 0 END), 1) AS saturday_open,
  ROUND(SUM(open_hours), 1) AS total_open
FROM warehouse.sched_hours
WHERE date_line >= '${inputs.selected_week.value}'::DATE
  AND date_line < '${inputs.selected_week.value}'::DATE + INTERVAL '7 days'
  AND source_database = '${inputs.hardcoded_options}'
  AND is_training = false
GROUP BY cost_center_name, shift_type
ORDER BY cost_center_name, shift_type
```

```sql worked_hours
SELECT
  cost_center_name,
  CASE
    WHEN is_training = true THEN 'Orientation/FTO'
    WHEN source_database = 'tn' AND (cost_center_name LIKE 'Memp%' OR cost_center_name LIKE 'Miss%') AND special_event = true THEN 'Memp - Special Event'
    WHEN source_database = 'tn' AND (cost_center_name LIKE 'Memp%' OR cost_center_name LIKE 'Miss%') AND special_event = false THEN 'Memp - Regular'
    WHEN source_database = 'tn' AND cost_center_name LIKE 'Nash%' AND special_event = true THEN 'Nash - Special Event'
    WHEN source_database = 'tn' AND cost_center_name LIKE 'Nash%' AND special_event = false THEN 'Nash - Regular'
    WHEN special_event = true THEN 'Special Event'
    ELSE 'Regular'
  END AS shift_type,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 0 THEN worked_hours ELSE 0 END), 1) AS sunday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 1 THEN worked_hours ELSE 0 END), 1) AS monday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 2 THEN worked_hours ELSE 0 END), 1) AS tuesday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 3 THEN worked_hours ELSE 0 END), 1) AS wednesday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 4 THEN worked_hours ELSE 0 END), 1) AS thursday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 5 THEN worked_hours ELSE 0 END), 1) AS friday_open,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 6 THEN worked_hours ELSE 0 END), 1) AS saturday_open,
  ROUND(SUM(worked_hours), 1) AS total_open
FROM warehouse.sched_hours
WHERE date_line >= '${inputs.selected_week.value}'::DATE
  AND date_line < '${inputs.selected_week.value}'::DATE + INTERVAL '7 days'
  AND source_database = '${inputs.hardcoded_options}'
  AND is_training = false
GROUP BY cost_center_name, shift_type
ORDER BY cost_center_name, shift_type
```

```sql training_hours
SELECT
  cost_center_name,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 0 THEN worked_hours ELSE 0 END), 1) AS sunday_hours,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 1 THEN worked_hours ELSE 0 END), 1) AS monday_hours,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 2 THEN worked_hours ELSE 0 END), 1) AS tuesday_hours,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 3 THEN worked_hours ELSE 0 END), 1) AS wednesday_hours,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 4 THEN worked_hours ELSE 0 END), 1) AS thursday_hours,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 5 THEN worked_hours ELSE 0 END), 1) AS friday_hours,
  ROUND(SUM(CASE WHEN EXTRACT(DOW FROM date_line) = 6 THEN worked_hours ELSE 0 END), 1) AS saturday_hours,
  ROUND(SUM(worked_hours), 1) AS total_hours
FROM warehouse.sched_hours
WHERE date_line >= '${inputs.selected_week.value}'::DATE
  AND date_line < '${inputs.selected_week.value}'::DATE + INTERVAL '7 days'
  AND source_database = '${inputs.hardcoded_options}'
  AND is_training = true
GROUP BY cost_center_name
ORDER BY cost_center_name
```

## Actual Hours

<DataTable data={worked_hours} rows=all groupBy=shift_type subtotals=true groupType=section >
  <Column id=cost_center_name title="Cost Center" />
  <Column id=shift_type title="Shift Type" />
  <Column id=sunday_open title="Sunday" fmt=num1 align=center />
  <Column id=monday_open title="Monday" fmt=num1 align=center />
  <Column id=tuesday_open title="Tuesday" fmt=num1 align=center />
  <Column id=wednesday_open title="Wednesday" fmt=num1 align=center />
  <Column id=thursday_open title="Thursday" fmt=num1 align=center />
  <Column id=friday_open title="Friday" fmt=num1 align=center />
  <Column id=saturday_open title="Saturday" fmt=num1 align=center />
  <Column id=total_open title="Total" fmt=num1 align=center />
</DataTable>

## Training Hours

<DataTable data={training_hours} rows=all>
  <Column id=cost_center_name title="Cost Center" />
  <Column id=sunday_hours title="Sunday" fmt=num1 align=center />
  <Column id=monday_hours title="Monday" fmt=num1 align=center />
  <Column id=tuesday_hours title="Tuesday" fmt=num1 align=center />
  <Column id=wednesday_hours title="Wednesday" fmt=num1 align=center />
  <Column id=thursday_hours title="Thursday" fmt=num1 align=center />
  <Column id=friday_hours title="Friday" fmt=num1 align=center />
  <Column id=saturday_hours title="Saturday" fmt=num1 align=center />
  <Column id=total_hours title="Total" fmt=num1 align=center />
</DataTable>

## Scheduled Hours

<DataTable data={scheduled_hours} rows=all groupBy=shift_type subtotals=true groupType=section>
  <Column id=cost_center_name title="Cost Center" />
  <Column id=shift_type title="Shift Type" />
  <Column id=sunday_scheduled title="Sunday" fmt=num1 align=center />
  <Column id=monday_scheduled title="Monday" fmt=num1 align=center />
  <Column id=tuesday_scheduled title="Tuesday" fmt=num1 align=center />
  <Column id=wednesday_scheduled title="Wednesday" fmt=num1 align=center />
  <Column id=thursday_scheduled title="Thursday" fmt=num1 align=center />
  <Column id=friday_scheduled title="Friday" fmt=num1 align=center />
  <Column id=saturday_scheduled title="Saturday" fmt=num1 align=center />
  <Column id=total_scheduled title="Total" fmt=num1 align=center />
</DataTable>

## Open Hours

<DataTable data={open_hours} rows=all groupBy=shift_type subtotals=true groupType=section >
  <Column id=cost_center_name title="Cost Center" />
  <Column id=shift_type title="Shift Type" />
  <Column id=sunday_open title="Sunday" fmt=num1 align=center />
  <Column id=monday_open title="Monday" fmt=num1 align=center />
  <Column id=tuesday_open title="Tuesday" fmt=num1 align=center />
  <Column id=wednesday_open title="Wednesday" fmt=num1 align=center />
  <Column id=thursday_open title="Thursday" fmt=num1 align=center />
  <Column id=friday_open title="Friday" fmt=num1 align=center />
  <Column id=saturday_open title="Saturday" fmt=num1 align=center />
  <Column id=total_open title="Total" fmt=num1 align=center />
</DataTable>


