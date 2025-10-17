select
    distinct leg_id,
    run_number,
    date_of_service,
    calltype_name,
    level_of_service,
    emergency,
    trip_status,
    region,
    reason_for_transport,

    --- times
    pickup_time,
    assigned_time,
    time_on_task_minutes,
    time_on_task_excl_transport_minutes,

    ---durations
    scene_time_minutes,
    destination_time_minutes,


    source_database
from analytics.time_on_task_run_metrics
where 
    date_of_service < CURRENT_DATE and 
    date_of_service >= CURRENT_DATE - INTERVAL '5 weeks'
and calltype_name in ('ALS','BLS','CCT')