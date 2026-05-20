
EXEC sp_changedbowner 'sa';

SELECT 
    pr.name AS grantee,
    pe.permission_name,
    pe.state_desc,
    pe.class_desc
FROM sys.server_permissions pe
JOIN sys.server_principals pr 
    ON pe.grantee_principal_id = pr.principal_id
WHERE pe.grantor_principal_id = SUSER_ID(N'TECHNODOM\fman');

SELECT 
    e.name,
    e.type_desc,
    e.state_desc,
    sp.name AS owner
FROM sys.endpoints e
JOIN sys.server_principals sp 
    ON e.principal_id = sp.principal_id
WHERE sp.name = N'TECHNODOM\fman';


use [master]
GO
ALTER AUTHORIZATION ON ENDPOINT::[Hadr_endpoint] TO sa;  -- Hadr_endpoint   Mirroring
GO
REVOKE CONNECT ON ENDPOINT::[Hadr_endpoint] TO [TECHNODOM\sqlservice] 
GO
use [master]
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [TECHNODOM\sqlservice] as sa
GO

use [master]
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[AG_ope_030] TO sa;
GO