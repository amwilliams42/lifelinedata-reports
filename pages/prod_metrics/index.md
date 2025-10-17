---
title: Time On Task/UHU
---


<ButtonGroup name=tot_region>
    <ButtonGroupItem valueLabel="Illinois" value="il" default=true/>
    <ButtonGroupItem valueLabel="Michigan" value="mi" />
    <ButtonGroupItem valueLabel="Memphis/MS" value="tn_memphis" />
    <ButtonGroupItem valueLabel="Nashville" value="tn_nashville" />
</ButtonGroup>

<DateInput
    name=daily_date
    title="Select Date"
    data={date_series}
    dates=date
/>

```sql date_series
select strftime(d, '%Y-%m-%d') as date
from generate_series(current_date() - interval '5 weeks', current_date() - interval '1 day', interval '1 day') as t(d)
order by d desc
```



```sql tot_filtered
select *
from warehouse.tot_daily
where region = '${inputs.tot_region}'
order by service_date

```
```sql tot_this_day
with plswork as (select *,
strftime(service_date, '%Y-%m-%d') as sdate
from warehouse.tot_daily
where region = '${inputs.tot_region}')
select * from plswork where sdate = '${inputs.daily_date.value}'
```

## Selected Day: {inputs.daily_date.value}

<Grid cols=4>
    <BigValue
        data={tot_this_day}
        value=total_time_on_task_hours
        title="ToT Hours"
        fmt="0.1"
    />
    <BigValue
        data={tot_this_day}
        value=total_scheduled_hours
        title="Total Unit Hours"
        fmt="0.1"
    />
    <BigValue
        data={tot_this_day}
        value=time_on_task_pct
        title='ToT%'
        fmt=pct
    />
    
    
    <BigValue
        data={tot_this_day}
        value=avg_scene_time_minutes
        title="Avg Scene Time"
        fmt="0.1"
    />
    <BigValue
        data={tot_this_day}
        value=avg_destination_time_minutes
        title="Avg Dest Time"
        fmt="0.1"
    />
    <BigValue
        data={tot_this_day}
        value=total_runs
        title="Total Runs"
        fmt="#,##0"
    />
    <BigValue
        data={tot_this_day}
        value=uhu
        title="UHU"
        fmt="0.2"
    />
</Grid>

```sql key_metrics
select
    avg(avg_time_on_task_minutes) as avg_tot,
    avg(avg_scene_time_minutes) as avg_scene,
    avg(avg_destination_time_minutes) as avg_destination,
    avg(uhu) as avg_uhu
from warehouse.tot_daily
where region = '${inputs.tot_region}'
    and service_date >= CURRENT_DATE - INTERVAL '7 days'
```

```sql time_series
select
    service_date,
    time_on_task_pct,
    avg(time_on_task_pct) over (
        order by service_date
        rows between 6 preceding and current row
    ) as ma_7day_tot_pct,
    total_scheduled_hours,
    total_time_on_task_hours
from warehouse.tot_daily
where region = '${inputs.tot_region}'
order by service_date
```
```sql tot_run_metrics
select *
from warehouse.tot_run_metrics
where region = '${inputs.tot_region}'
```

```sql scatter_data
select
    scene_time_minutes,
    destination_time_minutes,
    reason_for_transport,
    case
        when reason_for_transport in ('Nursing Home to Nursing Home Transfer', 'Interfacility Transfer', 'Psych Transfer', 'Direct Admit', 'Trauma Transfer', 'Surgery', 'Hospice Transfer', 'Transfer','Nursing Home Transfer') then 'Interfacility Transfer'
        when reason_for_transport in ('Doctors Appointment', 'Outpatient Procedure') then 'Doctors Appointment'
        when reason_for_transport = 'Hospice Discharge' then 'Discharge'
        else reason_for_transport 
    end as rft,
    level_of_service,
    calltype_name
from warehouse.tot_run_metrics
where region = '${inputs.tot_region}'
and scene_time_minutes > 0
and destination_time_minutes > 0
and reason_for_transport not null
and reason_for_transport not in ('Flight Team Transfer','Hospital Standby','Flight Transfer')
and reason_for_transport not like '%Event%' 
```

```sql histo_plot
select
    time_on_task_minutes,
    time_on_task_excl_transport_minutes
from warehouse.tot_run_metrics
where region = '${inputs.tot_region}'
    and time_on_task_minutes is not null
```

## 7 Day Moving Average (from {date_series[0].date})

<Grid cols=4>
    <BigValue
        data={key_metrics}
        value=avg_tot
        title="Avg Time on Task"
        fmt="0.1"
    />
    <BigValue
        data={key_metrics}
        value=avg_scene
        title="Avg Scene Time"
        fmt="0.1"
    />
    <BigValue
        data={key_metrics}
        value=avg_destination
        title="Avg Destination Time"
        fmt="0.1"
    />
    <BigValue
        data={key_metrics}
        value=avg_uhu
        title="Avg UHU"
        fmt="0.2"
    />
</Grid>

## Trends Over Time

<Grid cols=2>
    <BarChart
        data={time_series}
        x=service_date
        y=time_on_task_pct
        title="% Time on Task"
        yAxisTitle="Percent"
        y2=ma_7day_tot_pct
        y2SeriesType=line
        yFmt=pct1
    />
    <ScatterPlot
        data={time_series}
        x=total_scheduled_hours
        y=time_on_task_pct
        title="Scheduled Hours vs % Time on Task"
        xAxisTitle="Total Scheduled Hours"
        yAxisTitle="% Time on Task"
        yFmt=pct1
    />
</Grid>

## Distribution Analysis

<Grid cols=2>
    <Group>
        <Histogram
            data={histo_plot}
            x=time_on_task_minutes
            title="Total Time on Task Distribution"
            seriesColors={['#003f5c', '#374c80', '#7a5195', '#bc5090', '#ef5675', '#ff764a', '#ffa600']}
        />
        <Details title='About This Chart'>
            Distribution of total time on task from dispatch to completion. Includes responding time, scene time, transport time, and destination time. (Dispatch to Clear)
        </Details>
    </Group>

    <Group>
        <Histogram
            data={histo_plot}
            x=time_on_task_excl_transport_minutes
            title="Time on Task (Excluding Transport)"
            seriesColors={['#003f5c', '#374c80', '#7a5195', '#bc5090', '#ef5675', '#ff764a', '#ffa600']}
        />
        <Details title='About This Chart'>
            Distribution of time on task excluding transport between scene and destination. Shows time spent responding, at scene and destination only. (Dispatch to Clear minus Transporting)
        </Details>
    </Group>

    <Group>
        <ScatterPlot
            data={scatter_data}
            x=destination_time_minutes
            y=scene_time_minutes
            series=rft
            title="Scene vs. Destination Time by Transport Reason"
            xAxisTitle="Destination Time (minutes)"
            yAxisTitle="Scene Time (minutes)"
            xMin=0
            yMin=0
            xMax=450
            yMax=300
            yLog=true
            colorPalette={['#003f5c', '#ef5675', '#ffa600', '#374c80', '#7a5195', '#bc5090', '#ff764a']}
        />
        <Details title='About This Chart'>
            Scene time vs. destination time by reason for transport. Points farther from origin indicate longer times (worse performance). Y-axis is logarithmic.
        </Details>
    </Group>

    <Group>
        <ScatterPlot
            data={scatter_data}
            x=destination_time_minutes
            y=scene_time_minutes
            series=calltype_name
            title="Scene vs. Destination Time by Call Type"
            xAxisTitle="Destination Time (minutes)"
            yAxisTitle="Scene Time (minutes)"
            xMin=0
            yMin=0
            xMax=450
            yMax=300
            yLog=true
            colorPalette={['#003f5c', '#ef5675', '#ffa600', '#374c80', '#7a5195', '#bc5090', '#ff764a']}
        />
        <Details title='About This Chart'>
            Scene time vs. destination time by call type. Points farther from origin indicate longer times (worse performance). Y-axis is logarithmic.
        </Details>
    </Group>
</Grid>
