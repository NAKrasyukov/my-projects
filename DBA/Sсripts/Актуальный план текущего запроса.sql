SELECT
    r.session_id,
    qp.query_plan
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp
WHERE r.session_id = 52;