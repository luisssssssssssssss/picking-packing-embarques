-- Minimal reference data. No enabled accounts, credentials, orders or fictitious confirmations.
INSERT INTO [security].[Role] ([Code],[Name],[IsActive]) VALUES
(N'ADMIN',N'Administrador',1),(N'SUPERVISOR',N'Supervisor',1),
(N'FORKLIFT',N'Montacarguista',1),(N'PACKING',N'Packing',1),
(N'SHIPPING',N'Embarques',1),(N'DRIVER',N'Chofer: consulta previa a salida',1);
INSERT INTO [catalog].[UnitOfMeasure] ([Code],[Name],[QuantityScale],[IsActive]) VALUES
(N'PZA',N'Pieza',0,1),(N'KG',N'Kilogramo',3,1),(N'M',N'Metro',3,1);
INSERT INTO [catalog].[HandlingUnitType] ([Code],[Name],[IsActive]) VALUES
(N'PALLET',N'Tarima',1),(N'BOX',N'Caja',1);
