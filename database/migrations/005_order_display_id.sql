-- Customer-facing identifier; preserve internal keys and external order numbers.
ALTER TABLE operations.SalesOrder ADD DisplayOrderId nvarchar(100) NULL;
EXEC(N'UPDATE operations.SalesOrder SET DisplayOrderId=ExternalOrderNumber');
EXEC(N'CREATE UNIQUE INDEX UX_SalesOrder_DisplayOrderId ON operations.SalesOrder(SourceSystemId,DisplayOrderId) WHERE DisplayOrderId IS NOT NULL');
