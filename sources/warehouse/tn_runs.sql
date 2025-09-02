select
    *
from staging.stg_runs r
left join staging.stg_run_locations srl on r.leg_id = srl.leg_id and r.source_database = srl.source_database
where r.source_database = 'tn'