WITH base AS (
  SELECT
    r.leg_id,
    r.run_number,
    r.pcr_number,
    r.date_of_service,
    r.calltype_name,
    r.source_id,
    r.source_name,
    r.level_of_service,
    r.market,
    r.priority_id,
    r.transport_priority_id,
    r.emergency,
    r.trip_status,
    r.last_status_id,
    r.source_database,
    r.created_timestamp,
    r.modified_timestamp,

    t.service_date,
    t.pickup_time,
    t.orig_pickup_time,
    t.requested_pickup_time,
    t.appointment_time,
    t.return_time,
    t.ready_now,
    t.call_started_date,
    t.late_dispatch_created,
    t.late_dispatch_time,
    t.company_assignment_timestamp,
    t.assigned_time,
    t.acknowledged_time,
    t.enroute_time,
    t.at_scene_time,
    t.transporting_time,
    t.at_destination_time,
    t.clear_time,
    t.canceled_time,
    t.last_status_timestamp,
    t.at_patient_bedside_time,
    t.last_modified_date,
    t.record_modified,

    t.call_to_assignment_minutes,
    t.assignment_to_ack_minutes,
    t.ack_to_enroute_minutes,
    t.enroute_to_scene_minutes,
    t.scene_time_minutes,
    t.transport_time_minutes,
    t.destination_to_clear_minutes,
    t.total_call_duration_minutes,
    t.total_unit_time_minutes,
    t.response_time_minutes,

    t.pickup_hour,
    t.pickup_day_of_week,
    t.pickup_week_of_year
  FROM staging.stg_runs r
  JOIN staging.stg_run_timestamps t
    ON t.leg_id = r.leg_id
  WHERE t.pickup_time >= (current_date - interval '5 weeks') and t.pickup_time < current_date
  and r.trip_status = 4
  and calltype_name in ('ALS', 'BLS', 'CCT')
)
SELECT
  -- Identifiers
  leg_id,
  run_number,
  pcr_number,

  -- Dimensions
  date_of_service,
  service_date,
  calltype_name,
  level_of_service,
  market,
  source_name,
  source_database,
  emergency,
  trip_status,

  -- Time fields
  pickup_time,
  requested_pickup_time,
  appointment_time,
  orig_pickup_time,

  -- Derived schedule and windows
  COALESCE(requested_pickup_time, appointment_time, orig_pickup_time) AS scheduled_pickup_time,
  date_trunc('week', pickup_time)::date AS pickup_week_start,

  -- Timeliness metrics
  CASE
    WHEN pickup_time IS NOT NULL
         AND COALESCE(requested_pickup_time, appointment_time, orig_pickup_time) IS NOT NULL
    THEN EXTRACT(EPOCH FROM (at_scene_time - COALESCE(pickup_time, appointment_time, orig_pickup_time))) / 60.0
    ELSE NULL
  END AS pickup_delay_minutes,

  -- On-time flags
  CASE
    WHEN pickup_time IS NOT NULL
         AND COALESCE(requested_pickup_time, appointment_time, orig_pickup_time) IS NOT NULL
         AND pickup_time <= COALESCE(requested_pickup_time, appointment_time, orig_pickup_time)
    THEN TRUE
    ELSE FALSE
  END AS on_time_pickup_strict,

  CASE
    WHEN pickup_time IS NOT NULL
         AND COALESCE(requested_pickup_time, appointment_time, orig_pickup_time) IS NOT NULL
         AND pickup_time <= COALESCE(requested_pickup_time, appointment_time, orig_pickup_time) + interval '5 minutes'
    THEN TRUE
    ELSE FALSE
  END AS on_time_pickup_5min_grace,

  -- Status timestamps (optional for drilldowns)
  assigned_time,
  acknowledged_time,
  enroute_time,
  at_scene_time,

  -- Bucketing helpers
  pickup_hour,
  pickup_day_of_week,
  pickup_week_of_year
FROM base;
