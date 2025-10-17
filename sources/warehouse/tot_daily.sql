select 
    service_date,
    region,
    total_runs,
    total_time_on_task_hours,
    total_time_on_task_excl_transport_hours as mod_total_tot,
    avg_time_on_task_minutes,
    avg_scene_time_minutes,
    avg_destination_time_minutes,
    time_on_task_pct,
    unit_hour_utilization as uhu,
    total_scheduled_hours
from analytics.time_on_task_daily 
where 
    service_date < CURRENT_DATE and 
    service_date >= CURRENT_DATE - INTERVAL '5 weeks'
