---
title: On Time Performance - Last 5 Weeks
---

<Note>
  On time performance over the past 5 weeks. A call is considered "on time" if the crew arrives on scene within 15 minutes of the scheduled pickup time.
  
</Note>




## Select a Market

<ButtonGroup name=hardcoded_options>
    <ButtonGroupItem valueLabel="Illinois" value="il" default=true/>
    <ButtonGroupItem valueLabel="Michigan" value="mi" />
    <ButtonGroupItem valueLabel="Tennessee" value="tn" />
</ButtonGroup>

```sql otp_filtered
SELECT *
FROM warehouse.otp
where otp.source_database = '${inputs.hardcoded_options}'
```

```sql card_data
SELECT
  -- 1. Overall On-Time Performance
  ROUND(AVG(CASE WHEN on_time_pickup_15min_grace THEN 1 ELSE 0.0 END), 3) as otp_percentage,

  -- 2. Total Call Volume
  COUNT(*) as total_calls,

  -- 3. Average Pickup Delay
  ROUND(AVG(ABS(pickup_delay_minutes)), 1) as avg_delay_minutes,

  -- 4. Emergency Call OTP
  ROUND(AVG(CASE WHEN emergency = true AND on_time_pickup_15min_grace THEN 1.0
               WHEN emergency = true THEN 0.0
               ELSE NULL END), 1) as emergency_otp,

  -- 5. Last 7 Days Moving Average OTP
  ROUND(AVG(CASE WHEN service_date >= CURRENT_DATE - 7 AND on_time_pickup_15min_grace THEN 1.0
               WHEN service_date >= CURRENT_DATE - 7 THEN 0.0
               ELSE NULL END), 3) as last_7_days_otp,
  ROUND(
    AVG(CASE WHEN service_date >= CURRENT_DATE - 7 AND on_time_pickup_15min_grace THEN 1.0
             WHEN service_date >= CURRENT_DATE - 7 THEN 0.0
             ELSE NULL END) -
    AVG(CASE WHEN service_date >= CURRENT_DATE - 14 AND service_date < CURRENT_DATE - 7 AND on_time_pickup_15min_grace THEN 1.0
             WHEN service_date >= CURRENT_DATE - 14 AND service_date < CURRENT_DATE - 7 THEN 0.0
             ELSE NULL END), 3
  ) as otp_change_7_day
FROM ${otp_filtered}
```
<Group>
  <BigValue
    data={card_data}
    value=total_calls
  />
  <BigValue
    data={card_data}
    value=otp_percentage
    title="On-Time Performance"
    fmt=pct1
  />
  <BigValue
    data={card_data}
    value=avg_delay_minutes
    title="Average Pickup Delay (Minutes)"
    fmt=num1
  />

  <BigValue
    data={card_data}
    value=emergency_otp
    title="Emergency Call On-Time Performance"
    fmt=pct1
  />
  <BigValue
    data={card_data}
    value=last_7_days_otp
    title="Last 7 Days On-Time Performance"
    fmt=pct1
    comparison=otp_change_7_day
    comparisonFmt=pct1
    comparisonTitle="Change (7 Days)"
  />
  </Group>

```sql trend_line
SELECT
  service_date,
  ROUND(AVG(CASE WHEN on_time_pickup_15min_grace THEN 100.0 ELSE 0.0 END), 1) as daily_otp,
  COUNT(*) as daily_volume
FROM ${otp_filtered}
WHERE service_date >= CURRENT_DATE - 90
GROUP BY service_date
ORDER BY service_date DESC
```


```sql volume_vs_performance
SELECT
  service_date,
  COUNT(*) as daily_volume,
  ROUND(AVG(CASE WHEN on_time_pickup_15min_grace THEN 1.0 ELSE 0.0 END), 3) as daily_otp,
  strftime(service_date, '%Y-%m-%d') as service_date_formatted
FROM ${otp_filtered}
WHERE service_date >= CURRENT_DATE - 35
GROUP BY service_date
ORDER BY service_date
```



<Grid cols=2>
<LineChart 
    data={trend_line}
    x=service_date
    y=daily_otp
    y2=daily_volume
    y2SeriesType=bar
    yAxisTitle="On-Time Performance (%)"
/>
<ScatterPlot 
    data={volume_vs_performance}
    x=daily_volume
    y=daily_otp
    title="Daily Volume vs On-Time Performance"
    subtitle="Each point represents one day over 5 weeks"
    xAxisTitle="Daily Call Volume"
    yAxisTitle="On-Time Performance %"
    yFmt=pct1
    tooltipTitle=service_date_formatted
    pointSize=8
    showDownload=true
/>
</Grid>

```sql opt_table
SELECT 
  late_status,
  SUM(number_of_trips) as number_of_trips,
  ROUND(SUM(number_of_trips) * 100.0 / SUM(SUM(number_of_trips)) OVER(), 2) as percent
FROM (
  SELECT 
    CASE 
      WHEN delay_bucket = 0 THEN 'On Time'
      WHEN delay_bucket >= 12 THEN 'Over 60 Minutes Late'
      ELSE (delay_bucket * 5) || ' to ' || ((delay_bucket + 1) * 5 - 1) || ' Minutes Late'
    END as late_status,
    COUNT(*) as number_of_trips
  FROM (
    SELECT 
      GREATEST(0, FLOOR(GREATEST(0, pickup_delay_minutes) / 5)) as delay_bucket
    FROM ${otp_filtered} 
    WHERE pickup_delay_minutes IS NOT NULL
  )
  GROUP BY delay_bucket
)
GROUP BY late_status
ORDER BY 
  CASE 
    WHEN late_status = 'On Time' THEN 0
    WHEN late_status = 'Over 60 Minutes Late' THEN 999
    ELSE CAST(SPLIT_PART(late_status, ' ', 1) AS INTEGER)
  END
```

```sql otp_histo
SELECT 
  pickup_delay_minutes
FROM ${otp_filtered} 
WHERE pickup_delay_minutes IS NOT NULL 
  AND pickup_delay_minutes >= -30  -- Remove extreme outliers
  AND pickup_delay_minutes <= 120  
```
<Grid cols=2>
  <Histogram
    data={otp_histo}
    x=pickup_delay_minutes
    title="Distribution of Pickup Delays"
    subtitle="Frequency of delays across all calls (5 weeks)"
    xAxisTitle="Minutes Late/Early"
    yAxisTitle="Number of Calls"
    color="#2563eb"
    showDownload=true
/>


<DataTable data={opt_table} rows=all/>
</Grid>

```sql dist_facs
SELECT DISTINCT 
  pickup_facility
FROM ${otp_filtered} 
WHERE pickup_facility IS NOT NULL
ORDER BY pickup_facility DESC
```
## Late Call Details for Selected Facilities

<Dropdown
    name=facility_filter
    data={dist_facs}
    value=pickup_facility
    multiple=true
    title="Select Facilities"
/>

```sql late_calls_detail
SELECT
  CAST(run_number::INTEGER AS TEXT) as run_number,
  service_date,
  pickup_facility,
  dropoff_facility,
  calltype_name,
  market,
  pickup_delay_minutes,
  CASE
    WHEN pickup_delay_minutes <= 15 THEN 'On Time'
    WHEN pickup_delay_minutes <= 30 THEN '16-30 Min Late'
    WHEN pickup_delay_minutes <= 60 THEN '31-60 Min Late'
    ELSE 'Over 60 Min Late'
  END as delay_category,
  emergency,
  strftime(service_date, '%Y-%m-%d') as service_date_formatted
FROM ${otp_filtered}
WHERE pickup_facility IN ${inputs.facility_filter.value}
  AND pickup_delay_minutes > 0  -- Only late calls
  AND pickup_delay_minutes IS NOT NULL
ORDER BY pickup_delay_minutes DESC
```

```sql facility_delay_breakdown
SELECT
  CASE
    WHEN pickup_delay_minutes <= 15 THEN '1-15 Min Late (On Time)'
    WHEN pickup_delay_minutes <= 30 THEN '16-30 Min Late'
    WHEN pickup_delay_minutes <= 60 THEN '31-60 Min Late'
    ELSE 'Over 60 Min Late'
  END as name,
  COUNT(*) as value
FROM ${otp_filtered}
WHERE pickup_facility IN ${inputs.facility_filter.value}
  AND pickup_delay_minutes > 0
  AND pickup_delay_minutes IS NOT NULL
GROUP BY 1
ORDER BY value DESC
```

<Grid cols=2>
<DataTable 
    data={late_calls_detail}
    rows=15
    emptyMessage="No late calls for selected facilities"
>
  <Column id=run_number title="Run Number"/>
  <Column id=service_date_formatted title="Date"/>
  <Column id=calltype_name title="Call Type"/>
  <Column id=pickup_delay_minutes title="Minutes Late" fmt=num1/>
  <Column id=pickup_facility title="Pickup Facility"/>
  <Column id=dropoff_facility title="Dropoff Facility"/>
</DataTable>
  <ECharts config={
    {
        title: {
            text: 'Late Call Percentage Breakdown',
            left: 'center'
        },
        tooltip: {
            formatter: '{b}: {c} calls ({d}%)'
        },
        legend: {
            orient: 'vertical',
            left: 'left'
        },
        series: [
        {
          type: 'pie',
          radius: '50%',
          data: [...facility_delay_breakdown],
          label: {
            show: true,
            formatter: '{b}\n{d}%'
          },
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          }
        }
      ]
      }
    }
/>
</Grid>
