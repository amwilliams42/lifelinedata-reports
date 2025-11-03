# Memphis Demand Analysis

## 5-Week Average Demand Patterns

The following heatmaps show average demand patterns across hours of the day and days of the week, based on a rolling 5-week average.

```sql heatmaps
select * from warehouse."5wk_demand_mem"
```

### Total Demand (5-Week Average)

<Heatmap
    data={heatmaps}
    title='Total Demand by Hour of Day and Day of Week'
    x=hour_of_day
    y=day_of_week
    value=avg_call_count
    colorScale={[
        ['rgb(254,234,159)', 'rgb(254,234,159)'],
        ['rgb(218,66,41)', 'rgb(218,66,41)']
    ]}
    xSort=xsort
    ySort=ysort
    legend=false
/>

### Calls Ran - Historic (5-Week Average)

<Heatmap
    data={heatmaps}
    title='Calls Ran by Hour of Day and Day of Week'
    x=hour_of_day
    y=day_of_week
    value=avg_ran_count
    colorScale={[
        ['rgb(199,233,180)', 'rgb(199,233,180)'],
        ['rgb(0,104,55)', 'rgb(0,104,55)']
    ]}
    xSort=xsort
    ySort=ysort
    legend=false
/>

### Calls Turned - Historic (5-Week Average)

<Heatmap
    data={heatmaps}
    title='Calls Turned by Hour of Day and Day of Week'
    x=hour_of_day
    y=day_of_week
    value=avg_turned_count
    xSort=xsort
    ySort=ysort
    legend=false
/>