---
title: On Time Performance - Last 5 Weeks
---

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
  ROUND(AVG(CASE WHEN on_time_pickup_5min_grace THEN 1 ELSE 0.0 END), 3) as otp_percentage,
  
  -- 2. Total Call Volume
  COUNT(*) as total_calls,
  
  -- 3. Average Pickup Delay
  ROUND(AVG(ABS(pickup_delay_minutes)), 1) as avg_delay_minutes,
  
  -- 4. Emergency Call OTP
  ROUND(AVG(CASE WHEN emergency = true AND on_time_pickup_5min_grace THEN 1.0 
               WHEN emergency = true THEN 0.0 
               ELSE NULL END), 1) as emergency_otp,
  
  -- 5. Last 7 Days Moving Average OTP
  ROUND(AVG(CASE WHEN service_date >= CURRENT_DATE - 7 AND on_time_pickup_5min_grace THEN 1.0 
               WHEN service_date >= CURRENT_DATE - 7 THEN 0.0 
               ELSE NULL END), 3) as last_7_days_otp,
  ROUND(
    AVG(CASE WHEN service_date >= CURRENT_DATE - 7 AND on_time_pickup_5min_grace THEN 1.0 
             WHEN service_date >= CURRENT_DATE - 7 THEN 0.0 
             ELSE NULL END) -
    AVG(CASE WHEN service_date >= CURRENT_DATE - 14 AND service_date < CURRENT_DATE - 7 AND on_time_pickup_5min_grace THEN 1.0 
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
  ROUND(AVG(CASE WHEN on_time_pickup_5min_grace THEN 100.0 ELSE 0.0 END), 1) as daily_otp,
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
  ROUND(AVG(CASE WHEN on_time_pickup_5min_grace THEN 1.0 ELSE 0.0 END), 3) as daily_otp,
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



