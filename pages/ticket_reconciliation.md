---
title: EPCR/Export Ticket Reconciliation
fullWidth: true
builtWithEvidence: false
---

```sql state_selector
SELECT
    source_database,
    CASE
        WHEN source_database = 'il' THEN 'Illinois'
        WHEN source_database = 'mi' THEN 'Michigan'
        WHEN source_database = 'tn' THEN 'Tennessee'
    END as display
FROM warehouse.qa_runlist
```



```sql selectors
SELECT
    calltype,
    status_name,
    exported,
    finalized
FROM warehouse.qa_runlist WHERE source_database = '${inputs.state_select}' AND date_of_service BETWEEN '${inputs.date_filter.start}' AND '${inputs.date_filter.end}' 
```

```sql table_filter
SELECT
    DISTINCT run_num,
    date_of_service,
    calltype,
    patient_name,
    dob,
    finalized,
    finalized_date,
    status_name as qa_status,
    reviewer_name,
    case when reviewer_name is null then null else strftime(qa_date, '%Y-%m-%d') end as qa_date_str,
    exported
FROM warehouse.qa_runlist 
WHERE run_num IS NOT NULL AND ${inputs.selected_dimensions} 
AND source_database = '${inputs.state_select}'
AND date_of_service BETWEEN '${inputs.date_filter.start}' AND '${inputs.date_filter.end}' 

```

    <DateRange
        name=date_filter
        start='2025-06-01'
    />    <ButtonGroup data={state_selector} name=state_select value=source_database label=display/>




<DimensionGrid data={selectors}
                name="selected_dimensions"
                multiple=true/>

<DataTable data={table_filter} rows="all">
    <Column id=run_num title="Run #"/>
    <Column id=date_of_service title="Date of Service"/>
    <Column id=calltype title="Call Type"/>
    <Column id=patient_name title="Patient Name"/>
    <Column id=dob title="Date of Birth"/>
    <Column id=finalized title="Locked?"/>
    <Column id=finalized_date/>
    <Column id=qa_status title="QA Status"/>
    <Column id=reviewer_name/>
    <Column id=qa_date_str title="QA Date"/>
    <Column id=exported title="Export Status"/>
</DataTable>