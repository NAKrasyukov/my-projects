EXEC sp_helpindex '_AccumRgT39253';

SELECT
    i.name,
    c.name,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.indexes i
JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
JOIN sys.columns c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo._AccumRgT39253')
ORDER BY
    i.index_id,
    ic.key_ordinal;

