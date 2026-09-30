-- Baseline 0.2. Apply through backend.app.init_database; do not edit after installation.
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

EXEC(N'CREATE SCHEMA [audit] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [catalog] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [integration] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [operations] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [planning] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [platform] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [quality] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [security] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [shipping] AUTHORIZATION [dbo]');

EXEC(N'CREATE SCHEMA [warehouse] AUTHORIZATION [dbo]');

CREATE TABLE [security].[AppUser] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Login] nvarchar(64) NOT NULL,
    [DisplayName] nvarchar(240) NOT NULL,
    [PasswordHash] nvarchar(512) NOT NULL,
    [IsActive] bit NOT NULL,
    [LockedUntilUtc] datetime2(3) NULL,
    [FailedLoginCount] int NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_AppUser_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_AppUser_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_security_AppUser] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_security_AppUser_1] UNIQUE ([Login])
);

CREATE TABLE [security].[Role] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_Role_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_Role_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_security_Role] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_security_Role_1] UNIQUE ([Code])
);

CREATE TABLE [security].[Permission] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Description] nvarchar(240) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_Permission_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_Permission_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_security_Permission] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_security_Permission_1] UNIQUE ([Code])
);

CREATE TABLE [security].[UserRole] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [UserId] bigint NOT NULL,
    [RoleId] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_UserRole_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_UserRole_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_security_UserRole] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_security_UserRole_1] UNIQUE ([UserId], [RoleId])
);

CREATE TABLE [security].[RolePermission] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RoleId] bigint NOT NULL,
    [PermissionId] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_RolePermission_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_RolePermission_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_security_RolePermission] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_security_RolePermission_1] UNIQUE ([RoleId], [PermissionId])
);

CREATE TABLE [security].[UserWarehouse] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [UserId] bigint NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_UserWarehouse_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_security_UserWarehouse_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_security_UserWarehouse] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_security_UserWarehouse_1] UNIQUE ([UserId], [WarehouseId])
);

CREATE TABLE [platform].[SchemaMigration] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ApplicationCode] nvarchar(64) NOT NULL,
    [Version] nvarchar(64) NOT NULL,
    [ScriptChecksum] binary(32) NOT NULL,
    [AppliedAtUtc] datetime2(3) NOT NULL,
    [ApplicationVersion] nvarchar(64) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_platform_SchemaMigration_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_platform_SchemaMigration] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_platform_SchemaMigration_1] UNIQUE ([Version])
);

CREATE TABLE [platform].[OperationRequest] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [IdempotencyKey] uniqueidentifier NOT NULL,
    [OperationCode] nvarchar(64) NOT NULL,
    [RequestHash] binary(32) NOT NULL,
    [Outcome] nvarchar(64) NOT NULL,
    [ResponseCode] int NOT NULL,
    [ResultJson] nvarchar(max) NULL,
    [CompletedAtUtc] datetime2(3) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_platform_OperationRequest_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_platform_OperationRequest] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_platform_OperationRequest_1] UNIQUE ([ActorUserId], [IdempotencyKey])
);

CREATE TABLE [catalog].[LogisticsPoint] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [PointType] nvarchar(64) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_LogisticsPoint_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_LogisticsPoint_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_LogisticsPoint] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_LogisticsPoint_1] UNIQUE ([Code])
);

CREATE TABLE [catalog].[PointAddress] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PointId] bigint NOT NULL,
    [VersionNumber] int NOT NULL,
    [AddressText] nvarchar(1000) NOT NULL,
    [City] nvarchar(240) NOT NULL,
    [Region] nvarchar(240) NULL,
    [PostalCode] nvarchar(64) NULL,
    [CountryCode] nvarchar(2) NOT NULL,
    [Latitude] decimal(9,6) NULL,
    [Longitude] decimal(9,6) NULL,
    [TimeZoneId] nvarchar(240) NOT NULL,
    [ValidFromUtc] datetime2(3) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_PointAddress_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_catalog_PointAddress] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_PointAddress_1] UNIQUE ([PointId], [VersionNumber]),
    CONSTRAINT [UQ_catalog_PointAddress_2] UNIQUE ([Id], [PointId])
);

CREATE TABLE [catalog].[Warehouse] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [PointId] bigint NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Warehouse_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Warehouse_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_Warehouse] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_Warehouse_1] UNIQUE ([Code]),
    CONSTRAINT [UQ_catalog_Warehouse_2] UNIQUE ([PointId])
);

CREATE TABLE [catalog].[Location] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [ParentLocationId] bigint NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [LocationType] nvarchar(64) NOT NULL,
    [AllowsPicking] bit NOT NULL,
    [AllowsStorage] bit NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Location_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Location_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_Location] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_Location_1] UNIQUE ([WarehouseId], [Code]),
    CONSTRAINT [UQ_catalog_Location_2] UNIQUE ([Id], [WarehouseId])
);

CREATE TABLE [catalog].[Customer] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Customer_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Customer_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_Customer] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_Customer_1] UNIQUE ([Code])
);

CREATE TABLE [catalog].[DeliverySite] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CustomerId] bigint NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [PointId] bigint NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_DeliverySite_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_DeliverySite_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_DeliverySite] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_DeliverySite_1] UNIQUE ([CustomerId], [Code]),
    CONSTRAINT [UQ_catalog_DeliverySite_2] UNIQUE ([PointId]),
    CONSTRAINT [UQ_catalog_DeliverySite_3] UNIQUE ([Id], [CustomerId])
);

CREATE TABLE [catalog].[DeliveryWindow] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DeliverySiteId] bigint NOT NULL,
    [WeekDay] int NOT NULL,
    [StartLocal] time(0) NOT NULL,
    [EndLocal] time(0) NOT NULL,
    [ValidFrom] date NOT NULL,
    [ValidTo] date NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_DeliveryWindow_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_DeliveryWindow_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_DeliveryWindow] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_DeliveryWindow_1] UNIQUE ([DeliverySiteId], [WeekDay], [StartLocal], [ValidFrom])
);

CREATE TABLE [catalog].[UnitOfMeasure] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [QuantityScale] int NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_UnitOfMeasure_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_UnitOfMeasure_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_UnitOfMeasure] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_UnitOfMeasure_1] UNIQUE ([Code])
);

CREATE TABLE [catalog].[Material] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Description] nvarchar(240) NOT NULL,
    [BaseUnitId] bigint NOT NULL,
    [RequiresLot] bit NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Material_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_Material_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_Material] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_Material_1] UNIQUE ([Code])
);

CREATE TABLE [catalog].[MaterialUnitConversion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [MaterialId] bigint NOT NULL,
    [FromUnitId] bigint NOT NULL,
    [FactorToBase] decimal(28,12) NOT NULL,
    [VersionNumber] int NOT NULL,
    [ValidFromUtc] datetime2(3) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialUnitConversion_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_catalog_MaterialUnitConversion] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_MaterialUnitConversion_1] UNIQUE ([MaterialId], [FromUnitId], [VersionNumber])
);

CREATE TABLE [catalog].[MaterialIdentifier] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [MaterialId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [Scheme] nvarchar(64) NOT NULL,
    [Value] nvarchar(128) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialIdentifier_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialIdentifier_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_MaterialIdentifier] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_MaterialIdentifier_1] UNIQUE ([Scheme], [Value])
);

CREATE TABLE [catalog].[MaterialLot] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [MaterialId] bigint NOT NULL,
    [LotCode] nvarchar(64) NOT NULL,
    [ManufacturedOn] date NULL,
    [ExpiresOn] date NULL,
    [IsBlocked] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialLot_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialLot_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_MaterialLot] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_MaterialLot_1] UNIQUE ([MaterialId], [LotCode]),
    CONSTRAINT [UQ_catalog_MaterialLot_2] UNIQUE ([Id], [MaterialId])
);

CREATE TABLE [catalog].[MaterialLocation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [MaterialId] bigint NOT NULL,
    [LocationId] bigint NOT NULL,
    [IsPreferred] bit NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialLocation_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_MaterialLocation_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_MaterialLocation] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_MaterialLocation_1] UNIQUE ([MaterialId], [LocationId])
);

CREATE TABLE [catalog].[HandlingUnitType] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_HandlingUnitType_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_catalog_HandlingUnitType_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_catalog_HandlingUnitType] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_catalog_HandlingUnitType_1] UNIQUE ([Code])
);

CREATE TABLE [integration].[SourceSystem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Description] nvarchar(240) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_SourceSystem_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_SourceSystem_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_integration_SourceSystem] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_SourceSystem_1] UNIQUE ([Code])
);

CREATE TABLE [integration].[MappingProfileVersion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [SourceSystemId] bigint NOT NULL,
    [ProfileCode] nvarchar(64) NOT NULL,
    [VersionNumber] int NOT NULL,
    [Delimiter] nvarchar(8) NOT NULL,
    [EncodingName] nvarchar(64) NOT NULL,
    [HasHeader] bit NOT NULL,
    [DateFormat] nvarchar(64) NOT NULL,
    [DecimalSeparator] nvarchar(1) NOT NULL,
    [SourceTimeZone] nvarchar(240) NOT NULL,
    [Mode] nvarchar(64) NOT NULL,
    [DefinitionHash] binary(32) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_MappingProfileVersion_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_integration_MappingProfileVersion] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_MappingProfileVersion_1] UNIQUE ([SourceSystemId], [ProfileCode], [VersionNumber])
);

CREATE TABLE [integration].[MappingField] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ProfileVersionId] bigint NOT NULL,
    [TargetField] nvarchar(64) NOT NULL,
    [SourceColumnName] nvarchar(240) NULL,
    [SourceColumnIndex] int NULL,
    [ConstantValue] nvarchar(240) NULL,
    [IsRequired] bit NOT NULL,
    [TransformCode] nvarchar(64) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_MappingField_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_integration_MappingField] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_MappingField_1] UNIQUE ([ProfileVersionId], [TargetField])
);

CREATE TABLE [integration].[ImportedFile] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [SourceSystemId] bigint NOT NULL,
    [ContentHash] binary(32) NOT NULL,
    [ByteLength] bigint NOT NULL,
    [OriginalFileName] nvarchar(240) NOT NULL,
    [StorageKey] nvarchar(240) NOT NULL,
    [UploadedBy] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportedFile_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_integration_ImportedFile] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_ImportedFile_1] UNIQUE ([SourceSystemId], [ContentHash])
);

CREATE TABLE [integration].[ImportRun] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [FileId] bigint NOT NULL,
    [ProfileVersionId] bigint NOT NULL,
    [AttemptNumber] int NOT NULL,
    [RequestedBy] bigint NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [StartedAtUtc] datetime2(3) NULL,
    [FinishedAtUtc] datetime2(3) NULL,
    [LeaseToken] uniqueidentifier NULL,
    [LeaseExpiresAtUtc] datetime2(3) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportRun_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportRun_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_integration_ImportRun] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_ImportRun_1] UNIQUE ([FileId], [AttemptNumber]),
    CONSTRAINT [UQ_integration_ImportRun_2] UNIQUE ([Id], [FileId])
);

CREATE TABLE [integration].[ImportOrderResult] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RunId] bigint NOT NULL,
    [ExternalOrderNumber] nvarchar(64) NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [OrderRevisionId] bigint NULL,
    [MessageCode] nvarchar(64) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportOrderResult_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportOrderResult_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_integration_ImportOrderResult] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_ImportOrderResult_1] UNIQUE ([RunId], [ExternalOrderNumber]),
    CONSTRAINT [UQ_integration_ImportOrderResult_2] UNIQUE ([Id], [RunId])
);

CREATE TABLE [integration].[ImportRow] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RunId] bigint NOT NULL,
    [OrderResultId] bigint NULL,
    [RecordNumber] int NOT NULL,
    [PhysicalLineStart] int NOT NULL,
    [PhysicalLineEnd] int NOT NULL,
    [RawText] nvarchar(max) NOT NULL,
    [ParsedJson] nvarchar(max) NULL,
    [Status] nvarchar(64) NOT NULL,
    [AppliedOrderLineId] bigint NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportRow_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_integration_ImportRow] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_integration_ImportRow_1] UNIQUE ([RunId], [RecordNumber]),
    CONSTRAINT [UQ_integration_ImportRow_2] UNIQUE ([Id], [RunId])
);

CREATE TABLE [integration].[ImportError] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RunId] bigint NOT NULL,
    [RowId] bigint NULL,
    [FieldName] nvarchar(64) NULL,
    [Severity] nvarchar(64) NOT NULL,
    [ErrorCode] nvarchar(64) NOT NULL,
    [Message] nvarchar(1000) NOT NULL,
    [RawValue] nvarchar(240) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_integration_ImportError_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_integration_ImportError] PRIMARY KEY ([Id])
);

CREATE TABLE [operations].[SalesOrder] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [SourceSystemId] bigint NOT NULL,
    [ExternalOrderNumber] nvarchar(64) NOT NULL,
    [CustomerId] bigint NOT NULL,
    [CurrentRevisionId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_SalesOrder_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_SalesOrder_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_operations_SalesOrder] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_operations_SalesOrder_1] UNIQUE ([SourceSystemId], [ExternalOrderNumber])
);

CREATE TABLE [operations].[OrderRevision] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderId] bigint NOT NULL,
    [RevisionNumber] int NOT NULL,
    [BusinessContentHash] binary(32) NOT NULL,
    [ExternalRevision] nvarchar(64) NULL,
    [SourceAsOfUtc] datetime2(3) NULL,
    [ChangeReason] nvarchar(1000) NOT NULL,
    [AcceptedBy] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_OrderRevision_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_operations_OrderRevision] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_operations_OrderRevision_1] UNIQUE ([OrderId], [RevisionNumber]),
    CONSTRAINT [UQ_operations_OrderRevision_2] UNIQUE ([Id], [OrderId])
);

CREATE TABLE [operations].[OrderLine] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderId] bigint NOT NULL,
    [ExternalLineKey] nvarchar(128) NOT NULL,
    [IsClosed] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_OrderLine_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_OrderLine_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_operations_OrderLine] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_operations_OrderLine_1] UNIQUE ([OrderId], [ExternalLineKey]),
    CONSTRAINT [UQ_operations_OrderLine_2] UNIQUE ([Id], [OrderId])
);

CREATE TABLE [operations].[OrderLineRevision] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderId] bigint NOT NULL,
    [OrderRevisionId] bigint NOT NULL,
    [OrderLineId] bigint NOT NULL,
    [MaterialId] bigint NOT NULL,
    [DeliverySiteId] bigint NOT NULL,
    [RequestedUnitId] bigint NOT NULL,
    [RequestedQuantity] decimal(19,6) NOT NULL,
    [FactorToBase] decimal(28,12) NOT NULL,
    [RequiredBaseQuantity] decimal(19,6) NOT NULL,
    [RequestedDate] date NOT NULL,
    [Priority] int NOT NULL,
    [IsCancelled] bit NOT NULL,
    [MaterialCodeSnapshot] nvarchar(64) NOT NULL,
    [MaterialDescriptionSnapshot] nvarchar(240) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_OrderLineRevision_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_operations_OrderLineRevision] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_operations_OrderLineRevision_1] UNIQUE ([OrderRevisionId], [OrderLineId]),
    CONSTRAINT [UQ_operations_OrderLineRevision_2] UNIQUE ([Id], [OrderLineId])
);

CREATE TABLE [operations].[FulfillmentAllocation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderLineId] bigint NOT NULL,
    [OrderLineRevisionId] bigint NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [AllocatedBaseQuantity] decimal(19,6) NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [ReleasedAtUtc] datetime2(3) NULL,
    [ReleasedBy] bigint NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_FulfillmentAllocation_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_operations_FulfillmentAllocation_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_operations_FulfillmentAllocation] PRIMARY KEY ([Id])
);

CREATE TABLE [planning].[DistanceReference] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OriginAddressId] bigint NOT NULL,
    [DestinationAddressId] bigint NOT NULL,
    [RoadDistanceKm] decimal(12,3) NOT NULL,
    [ReferenceMinutes] int NULL,
    [SourceDescription] nvarchar(240) NOT NULL,
    [MeasuredOn] date NOT NULL,
    [ValidUntil] date NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_DistanceReference_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_planning_DistanceReference] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_DistanceReference_1] UNIQUE ([OriginAddressId], [DestinationAddressId], [MeasuredOn], [SourceDescription])
);

CREATE TABLE [planning].[Carrier] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Carrier_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Carrier_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_Carrier] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_Carrier_1] UNIQUE ([Code])
);

CREATE TABLE [planning].[Trailer] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Registration] nvarchar(64) NOT NULL,
    [RegistrationRegion] nvarchar(64) NOT NULL,
    [CarrierId] bigint NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Trailer_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Trailer_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_Trailer] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_Trailer_1] UNIQUE ([Code]),
    CONSTRAINT [UQ_planning_Trailer_2] UNIQUE ([RegistrationRegion], [Registration])
);

CREATE TABLE [planning].[Driver] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [DisplayName] nvarchar(240) NOT NULL,
    [CarrierId] bigint NULL,
    [UserId] bigint NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Driver_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Driver_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_Driver] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_Driver_1] UNIQUE ([Code])
);

CREATE TABLE [planning].[Trip] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [OriginWarehouseId] bigint NOT NULL,
    [CurrentRevisionId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Trip_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_Trip_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_Trip] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_Trip_1] UNIQUE ([Code])
);

CREATE TABLE [planning].[TripRevision] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TripId] bigint NOT NULL,
    [RevisionNumber] int NOT NULL,
    [OriginAddressId] bigint NOT NULL,
    [PlannedDepartureUtc] datetime2(3) NULL,
    [PlannedTrailerId] bigint NULL,
    [PlannedDriverId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAtUtc] datetime2(3) NULL,
    [ChangeReason] nvarchar(1000) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_TripRevision_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_TripRevision_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_TripRevision] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_TripRevision_1] UNIQUE ([TripId], [RevisionNumber]),
    CONSTRAINT [UQ_planning_TripRevision_2] UNIQUE ([Id], [TripId])
);

CREATE TABLE [planning].[TripStop] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TripRevisionId] bigint NOT NULL,
    [SequenceNumber] int NOT NULL,
    [DeliverySiteId] bigint NOT NULL,
    [AddressVersionId] bigint NOT NULL,
    [WindowStartUtc] datetime2(3) NULL,
    [WindowEndUtc] datetime2(3) NULL,
    [DistanceFromPreviousId] bigint NULL,
    [Instructions] nvarchar(1000) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_TripStop_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_TripStop_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_TripStop] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_TripStop_1] UNIQUE ([TripRevisionId], [SequenceNumber]),
    CONSTRAINT [UQ_planning_TripStop_2] UNIQUE ([Id], [TripRevisionId])
);

CREATE TABLE [planning].[TripAllocation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [StopId] bigint NOT NULL,
    [AllocationId] bigint NOT NULL,
    [PlannedBaseQuantity] decimal(19,6) NOT NULL,
    [CancelledBaseQuantity] decimal(19,6) NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_TripAllocation_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_TripAllocation_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_TripAllocation] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_TripAllocation_1] UNIQUE ([StopId], [AllocationId])
);

CREATE TABLE [warehouse].[PickingTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [AssignedUserId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [StartedAtUtc] datetime2(3) NULL,
    [CompletedAtUtc] datetime2(3) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PickingTask_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PickingTask_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_warehouse_PickingTask] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_warehouse_PickingTask_1] UNIQUE ([Code])
);

CREATE TABLE [warehouse].[PickingTaskLine] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TaskId] bigint NOT NULL,
    [AllocationId] bigint NOT NULL,
    [SourceLocationId] bigint NOT NULL,
    [LotId] bigint NULL,
    [PlannedBaseQuantity] decimal(19,6) NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PickingTaskLine_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PickingTaskLine_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_warehouse_PickingTaskLine] PRIMARY KEY ([Id])
);

CREATE TABLE [warehouse].[PickConfirmation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TaskLineId] bigint NOT NULL,
    [BaseQuantity] decimal(19,6) NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [CaptureMethod] nvarchar(64) NOT NULL,
    [ObservedLocationCode] nvarchar(64) NULL,
    [ObservedMaterialCode] nvarchar(128) NULL,
    [OccurredAtUtc] datetime2(3) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PickConfirmation_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_PickConfirmation] PRIMARY KEY ([Id])
);

CREATE TABLE [warehouse].[PickReversal] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PickConfirmationId] bigint NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [Reason] nvarchar(1000) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PickReversal_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_PickReversal] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_warehouse_PickReversal_1] UNIQUE ([PickConfirmationId])
);

CREATE TABLE [warehouse].[PackingReceipt] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PickConfirmationId] bigint NOT NULL,
    [PackingLocationId] bigint NOT NULL,
    [BaseQuantity] decimal(19,6) NOT NULL,
    [ReceivedBy] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [ReceivedAtUtc] datetime2(3) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PackingReceipt_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_PackingReceipt] PRIMARY KEY ([Id])
);

CREATE TABLE [warehouse].[ReceiptReversal] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ReceiptId] bigint NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [Reason] nvarchar(1000) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_ReceiptReversal_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_ReceiptReversal] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_warehouse_ReceiptReversal_1] UNIQUE ([ReceiptId])
);

CREATE TABLE [warehouse].[HandlingUnit] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [TypeId] bigint NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [DeliverySiteId] bigint NOT NULL,
    [CurrentLocationId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [PackedAtUtc] datetime2(3) NULL,
    [PackedBy] bigint NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_HandlingUnit_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_HandlingUnit_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_warehouse_HandlingUnit] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_warehouse_HandlingUnit_1] UNIQUE ([Code])
);

CREATE TABLE [warehouse].[HandlingUnitItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [HandlingUnitId] bigint NOT NULL,
    [ReceiptId] bigint NOT NULL,
    [BaseQuantity] decimal(19,6) NOT NULL,
    [OperationId] bigint NOT NULL,
    [PackedBy] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_HandlingUnitItem_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_HandlingUnitItem] PRIMARY KEY ([Id])
);

CREATE TABLE [warehouse].[PackingReversal] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [HandlingUnitItemId] bigint NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [Reason] nvarchar(1000) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_PackingReversal_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_PackingReversal] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_warehouse_PackingReversal_1] UNIQUE ([HandlingUnitItemId])
);

CREATE TABLE [warehouse].[HandlingUnitMovement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [HandlingUnitId] bigint NOT NULL,
    [FromLocationId] bigint NULL,
    [ToLocationId] bigint NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [MovedAtUtc] datetime2(3) NOT NULL,
    [Reason] nvarchar(1000) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_warehouse_HandlingUnitMovement_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_warehouse_HandlingUnitMovement] PRIMARY KEY ([Id])
);

CREATE TABLE [shipping].[Shipment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TripId] bigint NOT NULL,
    [TripRevisionId] bigint NOT NULL,
    [TrailerId] bigint NOT NULL,
    [DriverId] bigint NULL,
    [DockLocationId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [SealNumber] nvarchar(64) NULL,
    [OpenedAtUtc] datetime2(3) NOT NULL,
    [ClosedAtUtc] datetime2(3) NULL,
    [CancelledAtUtc] datetime2(3) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_shipping_Shipment_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_shipping_Shipment_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_shipping_Shipment] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_shipping_Shipment_1] UNIQUE ([TripId]),
    CONSTRAINT [UQ_shipping_Shipment_2] UNIQUE ([Id], [TripRevisionId])
);

CREATE TABLE [shipping].[ShipmentUnit] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ShipmentId] bigint NOT NULL,
    [TripRevisionId] bigint NOT NULL,
    [StopId] bigint NOT NULL,
    [HandlingUnitId] bigint NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [AssignedBy] bigint NOT NULL,
    [AssignedAtUtc] datetime2(3) NOT NULL,
    [ReleasedAtUtc] datetime2(3) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_shipping_ShipmentUnit_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_shipping_ShipmentUnit_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_shipping_ShipmentUnit] PRIMARY KEY ([Id])
);

CREATE TABLE [shipping].[LoadEvent] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ShipmentUnitId] bigint NOT NULL,
    [EventType] nvarchar(64) NOT NULL,
    [WarehouseLocationId] bigint NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [OccurredAtUtc] datetime2(3) NOT NULL,
    [Reason] nvarchar(1000) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_shipping_LoadEvent_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_shipping_LoadEvent] PRIMARY KEY ([Id])
);

CREATE TABLE [shipping].[ShipmentClosure] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ShipmentId] bigint NOT NULL,
    [ClosedBy] bigint NOT NULL,
    [OperationId] bigint NOT NULL,
    [ClosedAtUtc] datetime2(3) NOT NULL,
    [ManifestJson] nvarchar(max) NOT NULL,
    [ManifestHash] binary(32) NOT NULL,
    [IsPartial] bit NOT NULL,
    [PartialApprovalId] bigint NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_shipping_ShipmentClosure_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_shipping_ShipmentClosure] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_shipping_ShipmentClosure_1] UNIQUE ([ShipmentId])
);

CREATE TABLE [quality].[IncidentType] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [Name] nvarchar(240) NOT NULL,
    [DefaultSeverity] nvarchar(64) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_IncidentType_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_IncidentType_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_quality_IncidentType] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_quality_IncidentType_1] UNIQUE ([Code])
);

CREATE TABLE [quality].[Incident] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TypeId] bigint NOT NULL,
    [ImportRunId] bigint NULL,
    [OrderLineId] bigint NULL,
    [TaskLineId] bigint NULL,
    [HandlingUnitId] bigint NULL,
    [ShipmentId] bigint NULL,
    [TripId] bigint NULL,
    [ReportedBy] bigint NOT NULL,
    [Severity] nvarchar(64) NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [Description] nvarchar(1000) NOT NULL,
    [ResolvedAtUtc] datetime2(3) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_Incident_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_Incident_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_quality_Incident] PRIMARY KEY ([Id])
);

CREATE TABLE [quality].[IncidentAction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [IncidentId] bigint NOT NULL,
    [ActorUserId] bigint NOT NULL,
    [ActionCode] nvarchar(64) NOT NULL,
    [Comment] nvarchar(1000) NOT NULL,
    [OperationId] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_IncidentAction_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_quality_IncidentAction] PRIMARY KEY ([Id])
);

CREATE TABLE [quality].[Hold] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderLineId] bigint NULL,
    [HandlingUnitId] bigint NULL,
    [ShipmentId] bigint NULL,
    [IncidentId] bigint NULL,
    [Reason] nvarchar(1000) NOT NULL,
    [PlacedBy] bigint NOT NULL,
    [ReleasedAtUtc] datetime2(3) NULL,
    [ReleasedBy] bigint NULL,
    [ReleaseReason] nvarchar(1000) NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_Hold_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_Hold_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_quality_Hold] PRIMARY KEY ([Id])
);

CREATE TABLE [quality].[Approval] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [IncidentId] bigint NULL,
    [OrderLineId] bigint NULL,
    [HandlingUnitId] bigint NULL,
    [ShipmentId] bigint NULL,
    [TripId] bigint NULL,
    [ActionCode] nvarchar(64) NOT NULL,
    [PayloadHash] binary(32) NOT NULL,
    [ReviewPayloadJson] nvarchar(max) NOT NULL,
    [ExpectedVersion] binary(8) NOT NULL,
    [RequestedBy] bigint NOT NULL,
    [DecidedBy] bigint NULL,
    [Decision] nvarchar(64) NOT NULL,
    [DecidedAtUtc] datetime2(3) NULL,
    [ExpiresAtUtc] datetime2(3) NULL,
    [Reason] nvarchar(1000) NOT NULL,
    [ExecutedOperationId] bigint NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_Approval_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_quality_Approval_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_quality_Approval] PRIMARY KEY ([Id])
);

CREATE TABLE [audit].[AuditEvent] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OperationId] bigint NULL,
    [ActorUserId] bigint NULL,
    [ActionCode] nvarchar(64) NOT NULL,
    [EntityType] nvarchar(64) NOT NULL,
    [EntityKey] nvarchar(128) NOT NULL,
    [Outcome] nvarchar(64) NOT NULL,
    [BeforeJson] nvarchar(max) NULL,
    [AfterJson] nvarchar(max) NULL,
    [Reason] nvarchar(1000) NULL,
    [CorrelationId] uniqueidentifier NOT NULL,
    [OccurredAtUtc] datetime2(3) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_audit_AuditEvent_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_audit_AuditEvent] PRIMARY KEY ([Id])
);

CREATE TABLE [planning].[CapacityPool] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [Code] nvarchar(64) NOT NULL,
    [StageCode] nvarchar(64) NOT NULL,
    [CapacityBasis] nvarchar(64) NOT NULL,
    [CapacityUnitId] bigint NULL,
    [TimeZoneId] nvarchar(240) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityPool_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityPool_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_CapacityPool] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_CapacityPool_1] UNIQUE ([WarehouseId], [Code]),
    CONSTRAINT [UQ_planning_CapacityPool_2] UNIQUE ([WarehouseId], [StageCode])
);

CREATE TABLE [planning].[CapacityDay] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PoolId] bigint NOT NULL,
    [WorkDate] date NOT NULL,
    [WindowStartUtc] datetime2(3) NULL,
    [WindowEndUtc] datetime2(3) NULL,
    [BaseCapacity] decimal(19,6) NOT NULL,
    [ExtraCapacity] decimal(19,6) NOT NULL,
    [UnavailableCapacity] decimal(19,6) NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [ClosedAtUtc] datetime2(3) NULL,
    [ChangeReason] nvarchar(1000) NOT NULL,
    [ChangedBy] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityDay_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityDay_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_CapacityDay] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_CapacityDay_1] UNIQUE ([PoolId], [WorkDate]),
    CONSTRAINT [UQ_planning_CapacityDay_2] UNIQUE ([Id], [PoolId])
);

CREATE TABLE [planning].[WorkStandardVersion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PoolId] bigint NOT NULL,
    [MaterialId] bigint NOT NULL,
    [VersionNumber] int NOT NULL,
    [CapacityPerBaseUnit] decimal(28,12) NOT NULL,
    [ValidFromUtc] datetime2(3) NOT NULL,
    [Description] nvarchar(240) NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_WorkStandardVersion_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_planning_WorkStandardVersion] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_WorkStandardVersion_1] UNIQUE ([PoolId], [MaterialId], [VersionNumber]),
    CONSTRAINT [UQ_planning_WorkStandardVersion_2] UNIQUE ([Id], [PoolId])
);

CREATE TABLE [planning].[CapacityBooking] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [AllocationId] bigint NOT NULL,
    [PoolId] bigint NOT NULL,
    [CapacityDayId] bigint NOT NULL,
    [WorkStandardVersionId] bigint NOT NULL,
    [PlannedBaseQuantity] decimal(19,6) NOT NULL,
    [ReleasedBaseQuantity] decimal(19,6) NOT NULL,
    [RescheduledFromId] bigint NULL,
    [Status] nvarchar(64) NOT NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAtUtc] datetime2(3) NULL,
    [ReleaseReason] nvarchar(1000) NULL,
    [LastOperationId] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityBooking_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [UpdatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityBooking_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_planning_CapacityBooking] PRIMARY KEY ([Id]),
    CONSTRAINT [UQ_planning_CapacityBooking_1] UNIQUE ([Id], [PoolId])
);

CREATE TABLE [planning].[CapacityExecution] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [BookingId] bigint NOT NULL,
    [PoolId] bigint NOT NULL,
    [ActualCapacityDayId] bigint NOT NULL,
    [PickConfirmationId] bigint NULL,
    [HandlingUnitItemId] bigint NULL,
    [LoadEventId] bigint NULL,
    [BaseQuantity] decimal(19,6) NOT NULL,
    [UsedStandardCapacity] decimal(19,6) NOT NULL,
    [OperationId] bigint NOT NULL,
    [CreatedAtUtc] datetime2(3) NOT NULL CONSTRAINT [DF_planning_CapacityExecution_CreatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_planning_CapacityExecution] PRIMARY KEY ([Id])
);
