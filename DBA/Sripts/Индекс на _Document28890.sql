
-------фильтрованный индекс (наврядли поможет, тк активных строк боллее 90%)
CREATE NONCLUSTERED INDEX IX_1C_Document28890_Base
ON [UPP_Operator].[dbo].[_Document28890]
(
    _Fld28936RRef,
    _Date_Time
)
INCLUDE
(
    _Fld28979RRef,
    _Fld28976RRef,
    _Number
)
WHERE _Marked = 0x00;


-------не фильтрованный индекс, более универсальный, но эффективность под вопросом
CREATE NONCLUSTERED INDEX IX_1C_Document28890_Base
ON [UPP_Operator].[dbo].[_Document28890]
(
    _Fld28936RRef,
    _Date_Time
)
INCLUDE
(
    _Fld28979RRef,
    _Fld28976RRef,
    _Number
)
WITH (ONLINE = ON, MAXDOP = 4, SORT_IN_TEMPDB = ON);