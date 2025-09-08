---
title: "Memphis Week In Review"
---

```sql runs_by_week
select 
  lpad(date_part('week', r.date_of_service),2,'0') as week,
  date_trunc('week', r.date_of_service) - interval '1' day as week_start,
  date_trunc('week', r.date_of_service) - interval '1' day + interval '6' days as week_end,
  date_part('year', date_trunc('week', r.date_of_service) - interval '1' day) as year,
  date_part('year', date_trunc('week', r.date_of_service) - interval '1' day) || '/' || lpad(date_part('week', r.date_of_service),2,'0') as link,

from warehouse.tn_runs r
where date_trunc('week', r.date_of_service) - interval '1' day + interval '7' days < now()
group by 1,2,3,4,5
order by 5 desc
```

<DataTable data={runs_by_week} link=link>
  <Column id=year/>
  <Column id=week/>
  <Column id=week_start label="Week Start" format="date"/>
  <Column id=week_end label="Week End" format="date"/>
</DataTable>