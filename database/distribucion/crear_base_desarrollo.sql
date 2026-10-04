-- Paquete de desarrollo 0.2. Ejecutar COMPLETO en SSMS, conectado a su propia instancia.
-- No requiere Python ni modo SQLCMD. No contiene credenciales ni datos operativos.
-- Si ocurre un error, las migraciones se revierten; una base nueva puede quedar vacia.
USE [master];
SET NOCOUNT ON;
IF @@TRANCOUNT <> 0 THROW 51000, 'Ejecute en una ventana nueva sin transaccion abierta.', 1;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'PickingPackingEmbarques:install:4003f77415bd1f590f21b0fb7d9049f150ea58aec852247b0f9a5f91af62661e', @LockMode='Exclusive', @LockOwner='Session', @LockTimeout=0;
IF @lock < 0 THROW 51000, 'Otra instalacion esta en curso.', 1;
BEGIN TRY
 IF DB_ID(N'PickingPackingEmbarques_Dev') IS NULL EXEC(N'CREATE DATABASE [PickingPackingEmbarques_Dev]');
 EXEC(N'
USE [PickingPackingEmbarques_Dev];
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @marker nvarchar(128);
 SELECT @marker=CONVERT(nvarchar(128),value) FROM sys.extended_properties WHERE class=0 AND name=N''ApplicationCode'';
 IF @marker IS NOT NULL
 BEGIN
   IF @marker <> N''PickingPackingEmbarques'' THROW 51000, ''Base de otra aplicacion; no se modifico.'', 1;
   IF OBJECT_ID(N''platform.SchemaMigration'',N''U'') IS NULL THROW 51000, ''Falta el historial; revisar manualmente.'', 1;
   EXEC(N''IF (SELECT COUNT(*) FROM platform.SchemaMigration) <> 5 THROW 51000, ''''Version distinta; use las migraciones del repositorio.'''', 1;
IF NOT EXISTS (SELECT 1 FROM platform.SchemaMigration WHERE Version=''''001'''' AND ApplicationCode=''''PickingPackingEmbarques'''' AND ScriptChecksum=0x6eb79a0eba6a40da0387d7c8f752c38fffbfec768b15973c5dd2ec5c02aed1a5) THROW 51000, ''''Historial diferente; no se modifico la base.'''', 1;
IF NOT EXISTS (SELECT 1 FROM platform.SchemaMigration WHERE Version=''''002'''' AND ApplicationCode=''''PickingPackingEmbarques'''' AND ScriptChecksum=0x27a748d064a39209ff56884ac9999a0716bfe5045c7b2eef5b422c45eb48fb5c) THROW 51000, ''''Historial diferente; no se modifico la base.'''', 1;
IF NOT EXISTS (SELECT 1 FROM platform.SchemaMigration WHERE Version=''''003'''' AND ApplicationCode=''''PickingPackingEmbarques'''' AND ScriptChecksum=0xf41ac156ae1ee89b69c86b04fa5ee74086a555e3b1c282a4431f86a027603270) THROW 51000, ''''Historial diferente; no se modifico la base.'''', 1;
IF NOT EXISTS (SELECT 1 FROM platform.SchemaMigration WHERE Version=''''004'''' AND ApplicationCode=''''PickingPackingEmbarques'''' AND ScriptChecksum=0xfb3fff542a337ca31679d4768ab4f5cc34212d0acade2b65cd5994c6b7049438) THROW 51000, ''''Historial diferente; no se modifico la base.'''', 1;
IF NOT EXISTS (SELECT 1 FROM platform.SchemaMigration WHERE Version=''''005'''' AND ApplicationCode=''''PickingPackingEmbarques'''' AND ScriptChecksum=0x62e8272b15833968af7f756488c0582f0c4148a3a356d4fd45f4133f29fc6987) THROW 51000, ''''Historial diferente; no se modifico la base.'''', 1;'');
   COMMIT;
   PRINT N''La base ya tiene la version 0.2. Datos conservados.'';
   RETURN;
 END;
 IF EXISTS (SELECT 1 FROM sys.objects WHERE is_ms_shipped=0)
   THROW 51000, ''La base contiene objetos sin identificacion. Use una base vacia.'', 1;
 EXEC sys.sp_addextendedproperty @name=N''ApplicationCode'', @value=N''PickingPackingEmbarques'';

EXEC(N''-- Baseline 0.2. Apply through backend.app.init_database; do not edit after installation.
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

EXEC(N''''CREATE SCHEMA [audit] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [catalog] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [integration] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [operations] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [planning] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [platform] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [quality] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [security] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [shipping] AUTHORIZATION [dbo]'''');

EXEC(N''''CREATE SCHEMA [warehouse] AUTHORIZATION [dbo]'''');

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
'');
EXEC(N''INSERT INTO platform.SchemaMigration (ApplicationCode,Version,ScriptChecksum,AppliedAtUtc,ApplicationVersion) VALUES (N''''PickingPackingEmbarques'''',N''''001'''',0x6eb79a0eba6a40da0387d7c8f752c38fffbfec768b15973c5dd2ec5c02aed1a5,SYSUTCDATETIME(),N''''0.2'''');'');

EXEC(N''-- Foreign keys use NO ACTION: historical records are never cascade-deleted.

ALTER TABLE [operations].[SalesOrder] WITH CHECK ADD CONSTRAINT [FK_operations_SalesOrder_1] FOREIGN KEY ([CurrentRevisionId], [Id]) REFERENCES [operations].[OrderRevision] ([Id], [OrderId]);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLineRevision_2] FOREIGN KEY ([OrderRevisionId], [OrderId]) REFERENCES [operations].[OrderRevision] ([Id], [OrderId]);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLineRevision_3] FOREIGN KEY ([OrderLineId], [OrderId]) REFERENCES [operations].[OrderLine] ([Id], [OrderId]);

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [FK_operations_FulfillmentAllocation_4] FOREIGN KEY ([OrderLineRevisionId], [OrderLineId]) REFERENCES [operations].[OrderLineRevision] ([Id], [OrderLineId]);

ALTER TABLE [planning].[Trip] WITH CHECK ADD CONSTRAINT [FK_planning_Trip_5] FOREIGN KEY ([CurrentRevisionId], [Id]) REFERENCES [planning].[TripRevision] ([Id], [TripId]);

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [FK_shipping_Shipment_6] FOREIGN KEY ([TripRevisionId], [TripId]) REFERENCES [planning].[TripRevision] ([Id], [TripId]);

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentUnit_7] FOREIGN KEY ([ShipmentId], [TripRevisionId]) REFERENCES [shipping].[Shipment] ([Id], [TripRevisionId]);

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentUnit_8] FOREIGN KEY ([StopId], [TripRevisionId]) REFERENCES [planning].[TripStop] ([Id], [TripRevisionId]);

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [FK_integration_ImportRow_9] FOREIGN KEY ([OrderResultId], [RunId]) REFERENCES [integration].[ImportOrderResult] ([Id], [RunId]);

ALTER TABLE [integration].[ImportError] WITH CHECK ADD CONSTRAINT [FK_integration_ImportError_10] FOREIGN KEY ([RowId], [RunId]) REFERENCES [integration].[ImportRow] ([Id], [RunId]);

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [FK_catalog_Location_11] FOREIGN KEY ([ParentLocationId], [WarehouseId]) REFERENCES [catalog].[Location] ([Id], [WarehouseId]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_12] FOREIGN KEY ([CapacityDayId], [PoolId]) REFERENCES [planning].[CapacityDay] ([Id], [PoolId]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_13] FOREIGN KEY ([WorkStandardVersionId], [PoolId]) REFERENCES [planning].[WorkStandardVersion] ([Id], [PoolId]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_14] FOREIGN KEY ([BookingId], [PoolId]) REFERENCES [planning].[CapacityBooking] ([Id], [PoolId]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_15] FOREIGN KEY ([ActualCapacityDayId], [PoolId]) REFERENCES [planning].[CapacityDay] ([Id], [PoolId]);

ALTER TABLE [security].[UserRole] WITH CHECK ADD CONSTRAINT [FK_security_UserRole_16] FOREIGN KEY ([UserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [security].[UserRole] WITH CHECK ADD CONSTRAINT [FK_security_UserRole_17] FOREIGN KEY ([RoleId]) REFERENCES [security].[Role] ([Id]);

ALTER TABLE [security].[RolePermission] WITH CHECK ADD CONSTRAINT [FK_security_RolePermission_18] FOREIGN KEY ([RoleId]) REFERENCES [security].[Role] ([Id]);

ALTER TABLE [security].[RolePermission] WITH CHECK ADD CONSTRAINT [FK_security_RolePermission_19] FOREIGN KEY ([PermissionId]) REFERENCES [security].[Permission] ([Id]);

ALTER TABLE [security].[UserWarehouse] WITH CHECK ADD CONSTRAINT [FK_security_UserWarehouse_20] FOREIGN KEY ([UserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [security].[UserWarehouse] WITH CHECK ADD CONSTRAINT [FK_security_UserWarehouse_21] FOREIGN KEY ([WarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [platform].[OperationRequest] WITH CHECK ADD CONSTRAINT [FK_platform_OperationRequest_22] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [FK_catalog_PointAddress_23] FOREIGN KEY ([PointId]) REFERENCES [catalog].[LogisticsPoint] ([Id]);

ALTER TABLE [catalog].[Warehouse] WITH CHECK ADD CONSTRAINT [FK_catalog_Warehouse_24] FOREIGN KEY ([PointId]) REFERENCES [catalog].[LogisticsPoint] ([Id]);

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [FK_catalog_Location_25] FOREIGN KEY ([WarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [catalog].[DeliverySite] WITH CHECK ADD CONSTRAINT [FK_catalog_DeliverySite_26] FOREIGN KEY ([CustomerId]) REFERENCES [catalog].[Customer] ([Id]);

ALTER TABLE [catalog].[DeliverySite] WITH CHECK ADD CONSTRAINT [FK_catalog_DeliverySite_27] FOREIGN KEY ([PointId]) REFERENCES [catalog].[LogisticsPoint] ([Id]);

ALTER TABLE [catalog].[DeliveryWindow] WITH CHECK ADD CONSTRAINT [FK_catalog_DeliveryWindow_28] FOREIGN KEY ([DeliverySiteId]) REFERENCES [catalog].[DeliverySite] ([Id]);

ALTER TABLE [catalog].[Material] WITH CHECK ADD CONSTRAINT [FK_catalog_Material_29] FOREIGN KEY ([BaseUnitId]) REFERENCES [catalog].[UnitOfMeasure] ([Id]);

ALTER TABLE [catalog].[MaterialUnitConversion] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialUnitConversion_30] FOREIGN KEY ([MaterialId]) REFERENCES [catalog].[Material] ([Id]);

ALTER TABLE [catalog].[MaterialUnitConversion] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialUnitConversion_31] FOREIGN KEY ([FromUnitId]) REFERENCES [catalog].[UnitOfMeasure] ([Id]);

ALTER TABLE [catalog].[MaterialIdentifier] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialIdentifier_32] FOREIGN KEY ([MaterialId]) REFERENCES [catalog].[Material] ([Id]);

ALTER TABLE [catalog].[MaterialIdentifier] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialIdentifier_33] FOREIGN KEY ([UnitId]) REFERENCES [catalog].[UnitOfMeasure] ([Id]);

ALTER TABLE [catalog].[MaterialLot] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialLot_34] FOREIGN KEY ([MaterialId]) REFERENCES [catalog].[Material] ([Id]);

ALTER TABLE [catalog].[MaterialLocation] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialLocation_35] FOREIGN KEY ([MaterialId]) REFERENCES [catalog].[Material] ([Id]);

ALTER TABLE [catalog].[MaterialLocation] WITH CHECK ADD CONSTRAINT [FK_catalog_MaterialLocation_36] FOREIGN KEY ([LocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [integration].[MappingProfileVersion] WITH CHECK ADD CONSTRAINT [FK_integration_MappingProfileVersion_37] FOREIGN KEY ([SourceSystemId]) REFERENCES [integration].[SourceSystem] ([Id]);

ALTER TABLE [integration].[MappingField] WITH CHECK ADD CONSTRAINT [FK_integration_MappingField_38] FOREIGN KEY ([ProfileVersionId]) REFERENCES [integration].[MappingProfileVersion] ([Id]);

ALTER TABLE [integration].[ImportedFile] WITH CHECK ADD CONSTRAINT [FK_integration_ImportedFile_39] FOREIGN KEY ([SourceSystemId]) REFERENCES [integration].[SourceSystem] ([Id]);

ALTER TABLE [integration].[ImportedFile] WITH CHECK ADD CONSTRAINT [FK_integration_ImportedFile_40] FOREIGN KEY ([UploadedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [FK_integration_ImportRun_41] FOREIGN KEY ([FileId]) REFERENCES [integration].[ImportedFile] ([Id]);

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [FK_integration_ImportRun_42] FOREIGN KEY ([ProfileVersionId]) REFERENCES [integration].[MappingProfileVersion] ([Id]);

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [FK_integration_ImportRun_43] FOREIGN KEY ([RequestedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [integration].[ImportOrderResult] WITH CHECK ADD CONSTRAINT [FK_integration_ImportOrderResult_44] FOREIGN KEY ([RunId]) REFERENCES [integration].[ImportRun] ([Id]);

ALTER TABLE [integration].[ImportOrderResult] WITH CHECK ADD CONSTRAINT [FK_integration_ImportOrderResult_45] FOREIGN KEY ([OrderRevisionId]) REFERENCES [operations].[OrderRevision] ([Id]);

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [FK_integration_ImportRow_46] FOREIGN KEY ([RunId]) REFERENCES [integration].[ImportRun] ([Id]);

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [FK_integration_ImportRow_47] FOREIGN KEY ([AppliedOrderLineId]) REFERENCES [operations].[OrderLine] ([Id]);

ALTER TABLE [integration].[ImportError] WITH CHECK ADD CONSTRAINT [FK_integration_ImportError_48] FOREIGN KEY ([RunId]) REFERENCES [integration].[ImportRun] ([Id]);

ALTER TABLE [operations].[SalesOrder] WITH CHECK ADD CONSTRAINT [FK_operations_SalesOrder_49] FOREIGN KEY ([SourceSystemId]) REFERENCES [integration].[SourceSystem] ([Id]);

ALTER TABLE [operations].[SalesOrder] WITH CHECK ADD CONSTRAINT [FK_operations_SalesOrder_50] FOREIGN KEY ([CustomerId]) REFERENCES [catalog].[Customer] ([Id]);

ALTER TABLE [operations].[OrderRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderRevision_51] FOREIGN KEY ([OrderId]) REFERENCES [operations].[SalesOrder] ([Id]);

ALTER TABLE [operations].[OrderRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderRevision_52] FOREIGN KEY ([AcceptedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [operations].[OrderLine] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLine_53] FOREIGN KEY ([OrderId]) REFERENCES [operations].[SalesOrder] ([Id]);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLineRevision_54] FOREIGN KEY ([OrderId]) REFERENCES [operations].[SalesOrder] ([Id]);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLineRevision_55] FOREIGN KEY ([MaterialId]) REFERENCES [catalog].[Material] ([Id]);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLineRevision_56] FOREIGN KEY ([DeliverySiteId]) REFERENCES [catalog].[DeliverySite] ([Id]);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [FK_operations_OrderLineRevision_57] FOREIGN KEY ([RequestedUnitId]) REFERENCES [catalog].[UnitOfMeasure] ([Id]);

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [FK_operations_FulfillmentAllocation_58] FOREIGN KEY ([OrderLineId]) REFERENCES [operations].[OrderLine] ([Id]);

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [FK_operations_FulfillmentAllocation_59] FOREIGN KEY ([WarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [FK_operations_FulfillmentAllocation_60] FOREIGN KEY ([ReleasedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [planning].[DistanceReference] WITH CHECK ADD CONSTRAINT [FK_planning_DistanceReference_61] FOREIGN KEY ([OriginAddressId]) REFERENCES [catalog].[PointAddress] ([Id]);

ALTER TABLE [planning].[DistanceReference] WITH CHECK ADD CONSTRAINT [FK_planning_DistanceReference_62] FOREIGN KEY ([DestinationAddressId]) REFERENCES [catalog].[PointAddress] ([Id]);

ALTER TABLE [planning].[Trailer] WITH CHECK ADD CONSTRAINT [FK_planning_Trailer_63] FOREIGN KEY ([CarrierId]) REFERENCES [planning].[Carrier] ([Id]);

ALTER TABLE [planning].[Driver] WITH CHECK ADD CONSTRAINT [FK_planning_Driver_64] FOREIGN KEY ([CarrierId]) REFERENCES [planning].[Carrier] ([Id]);

ALTER TABLE [planning].[Driver] WITH CHECK ADD CONSTRAINT [FK_planning_Driver_65] FOREIGN KEY ([UserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [planning].[Trip] WITH CHECK ADD CONSTRAINT [FK_planning_Trip_66] FOREIGN KEY ([OriginWarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [FK_planning_TripRevision_67] FOREIGN KEY ([TripId]) REFERENCES [planning].[Trip] ([Id]);

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [FK_planning_TripRevision_68] FOREIGN KEY ([OriginAddressId]) REFERENCES [catalog].[PointAddress] ([Id]);

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [FK_planning_TripRevision_69] FOREIGN KEY ([PlannedTrailerId]) REFERENCES [planning].[Trailer] ([Id]);

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [FK_planning_TripRevision_70] FOREIGN KEY ([PlannedDriverId]) REFERENCES [planning].[Driver] ([Id]);

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [FK_planning_TripRevision_71] FOREIGN KEY ([ApprovedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [FK_planning_TripStop_72] FOREIGN KEY ([TripRevisionId]) REFERENCES [planning].[TripRevision] ([Id]);

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [FK_planning_TripStop_73] FOREIGN KEY ([DeliverySiteId]) REFERENCES [catalog].[DeliverySite] ([Id]);

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [FK_planning_TripStop_74] FOREIGN KEY ([AddressVersionId]) REFERENCES [catalog].[PointAddress] ([Id]);

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [FK_planning_TripStop_75] FOREIGN KEY ([DistanceFromPreviousId]) REFERENCES [planning].[DistanceReference] ([Id]);

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [FK_planning_TripAllocation_76] FOREIGN KEY ([StopId]) REFERENCES [planning].[TripStop] ([Id]);

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [FK_planning_TripAllocation_77] FOREIGN KEY ([AllocationId]) REFERENCES [operations].[FulfillmentAllocation] ([Id]);

ALTER TABLE [warehouse].[PickingTask] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickingTask_78] FOREIGN KEY ([WarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [warehouse].[PickingTask] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickingTask_79] FOREIGN KEY ([AssignedUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickingTaskLine_80] FOREIGN KEY ([TaskId]) REFERENCES [warehouse].[PickingTask] ([Id]);

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickingTaskLine_81] FOREIGN KEY ([AllocationId]) REFERENCES [operations].[FulfillmentAllocation] ([Id]);

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickingTaskLine_82] FOREIGN KEY ([SourceLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickingTaskLine_83] FOREIGN KEY ([LotId]) REFERENCES [catalog].[MaterialLot] ([Id]);

ALTER TABLE [warehouse].[PickConfirmation] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickConfirmation_84] FOREIGN KEY ([TaskLineId]) REFERENCES [warehouse].[PickingTaskLine] ([Id]);

ALTER TABLE [warehouse].[PickConfirmation] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickConfirmation_85] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[PickConfirmation] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickConfirmation_86] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [warehouse].[PickReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickReversal_87] FOREIGN KEY ([PickConfirmationId]) REFERENCES [warehouse].[PickConfirmation] ([Id]);

ALTER TABLE [warehouse].[PickReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickReversal_88] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[PickReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_PickReversal_89] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [warehouse].[PackingReceipt] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReceipt_90] FOREIGN KEY ([PickConfirmationId]) REFERENCES [warehouse].[PickConfirmation] ([Id]);

ALTER TABLE [warehouse].[PackingReceipt] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReceipt_91] FOREIGN KEY ([PackingLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [warehouse].[PackingReceipt] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReceipt_92] FOREIGN KEY ([ReceivedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[PackingReceipt] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReceipt_93] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [warehouse].[ReceiptReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_ReceiptReversal_94] FOREIGN KEY ([ReceiptId]) REFERENCES [warehouse].[PackingReceipt] ([Id]);

ALTER TABLE [warehouse].[ReceiptReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_ReceiptReversal_95] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[ReceiptReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_ReceiptReversal_96] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnit_97] FOREIGN KEY ([TypeId]) REFERENCES [catalog].[HandlingUnitType] ([Id]);

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnit_98] FOREIGN KEY ([WarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnit_99] FOREIGN KEY ([DeliverySiteId]) REFERENCES [catalog].[DeliverySite] ([Id]);

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnit_100] FOREIGN KEY ([CurrentLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnit_101] FOREIGN KEY ([PackedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitItem] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitItem_102] FOREIGN KEY ([HandlingUnitId]) REFERENCES [warehouse].[HandlingUnit] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitItem] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitItem_103] FOREIGN KEY ([ReceiptId]) REFERENCES [warehouse].[PackingReceipt] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitItem] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitItem_104] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitItem] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitItem_105] FOREIGN KEY ([PackedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[PackingReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReversal_106] FOREIGN KEY ([HandlingUnitItemId]) REFERENCES [warehouse].[HandlingUnitItem] ([Id]);

ALTER TABLE [warehouse].[PackingReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReversal_107] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[PackingReversal] WITH CHECK ADD CONSTRAINT [FK_warehouse_PackingReversal_108] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitMovement] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitMovement_109] FOREIGN KEY ([HandlingUnitId]) REFERENCES [warehouse].[HandlingUnit] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitMovement] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitMovement_110] FOREIGN KEY ([FromLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitMovement] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitMovement_111] FOREIGN KEY ([ToLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitMovement] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitMovement_112] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [warehouse].[HandlingUnitMovement] WITH CHECK ADD CONSTRAINT [FK_warehouse_HandlingUnitMovement_113] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [FK_shipping_Shipment_114] FOREIGN KEY ([TripId]) REFERENCES [planning].[Trip] ([Id]);

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [FK_shipping_Shipment_115] FOREIGN KEY ([TrailerId]) REFERENCES [planning].[Trailer] ([Id]);

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [FK_shipping_Shipment_116] FOREIGN KEY ([DriverId]) REFERENCES [planning].[Driver] ([Id]);

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [FK_shipping_Shipment_117] FOREIGN KEY ([DockLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentUnit_118] FOREIGN KEY ([TripRevisionId]) REFERENCES [planning].[TripRevision] ([Id]);

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentUnit_119] FOREIGN KEY ([HandlingUnitId]) REFERENCES [warehouse].[HandlingUnit] ([Id]);

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentUnit_120] FOREIGN KEY ([AssignedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [shipping].[LoadEvent] WITH CHECK ADD CONSTRAINT [FK_shipping_LoadEvent_121] FOREIGN KEY ([ShipmentUnitId]) REFERENCES [shipping].[ShipmentUnit] ([Id]);

ALTER TABLE [shipping].[LoadEvent] WITH CHECK ADD CONSTRAINT [FK_shipping_LoadEvent_122] FOREIGN KEY ([WarehouseLocationId]) REFERENCES [catalog].[Location] ([Id]);

ALTER TABLE [shipping].[LoadEvent] WITH CHECK ADD CONSTRAINT [FK_shipping_LoadEvent_123] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [shipping].[LoadEvent] WITH CHECK ADD CONSTRAINT [FK_shipping_LoadEvent_124] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentClosure_125] FOREIGN KEY ([ShipmentId]) REFERENCES [shipping].[Shipment] ([Id]);

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentClosure_126] FOREIGN KEY ([ClosedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentClosure_127] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [FK_shipping_ShipmentClosure_128] FOREIGN KEY ([PartialApprovalId]) REFERENCES [quality].[Approval] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_129] FOREIGN KEY ([TypeId]) REFERENCES [quality].[IncidentType] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_130] FOREIGN KEY ([ImportRunId]) REFERENCES [integration].[ImportRun] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_131] FOREIGN KEY ([OrderLineId]) REFERENCES [operations].[OrderLine] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_132] FOREIGN KEY ([TaskLineId]) REFERENCES [warehouse].[PickingTaskLine] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_133] FOREIGN KEY ([HandlingUnitId]) REFERENCES [warehouse].[HandlingUnit] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_134] FOREIGN KEY ([ShipmentId]) REFERENCES [shipping].[Shipment] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_135] FOREIGN KEY ([TripId]) REFERENCES [planning].[Trip] ([Id]);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [FK_quality_Incident_136] FOREIGN KEY ([ReportedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [quality].[IncidentAction] WITH CHECK ADD CONSTRAINT [FK_quality_IncidentAction_137] FOREIGN KEY ([IncidentId]) REFERENCES [quality].[Incident] ([Id]);

ALTER TABLE [quality].[IncidentAction] WITH CHECK ADD CONSTRAINT [FK_quality_IncidentAction_138] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [quality].[IncidentAction] WITH CHECK ADD CONSTRAINT [FK_quality_IncidentAction_139] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [FK_quality_Hold_140] FOREIGN KEY ([OrderLineId]) REFERENCES [operations].[OrderLine] ([Id]);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [FK_quality_Hold_141] FOREIGN KEY ([HandlingUnitId]) REFERENCES [warehouse].[HandlingUnit] ([Id]);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [FK_quality_Hold_142] FOREIGN KEY ([ShipmentId]) REFERENCES [shipping].[Shipment] ([Id]);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [FK_quality_Hold_143] FOREIGN KEY ([IncidentId]) REFERENCES [quality].[Incident] ([Id]);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [FK_quality_Hold_144] FOREIGN KEY ([PlacedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [FK_quality_Hold_145] FOREIGN KEY ([ReleasedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_146] FOREIGN KEY ([IncidentId]) REFERENCES [quality].[Incident] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_147] FOREIGN KEY ([OrderLineId]) REFERENCES [operations].[OrderLine] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_148] FOREIGN KEY ([HandlingUnitId]) REFERENCES [warehouse].[HandlingUnit] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_149] FOREIGN KEY ([ShipmentId]) REFERENCES [shipping].[Shipment] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_150] FOREIGN KEY ([TripId]) REFERENCES [planning].[Trip] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_151] FOREIGN KEY ([RequestedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_152] FOREIGN KEY ([DecidedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [FK_quality_Approval_153] FOREIGN KEY ([ExecutedOperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [audit].[AuditEvent] WITH CHECK ADD CONSTRAINT [FK_audit_AuditEvent_154] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [audit].[AuditEvent] WITH CHECK ADD CONSTRAINT [FK_audit_AuditEvent_155] FOREIGN KEY ([ActorUserId]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityPool_156] FOREIGN KEY ([WarehouseId]) REFERENCES [catalog].[Warehouse] ([Id]);

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityPool_157] FOREIGN KEY ([CapacityUnitId]) REFERENCES [catalog].[UnitOfMeasure] ([Id]);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityDay_158] FOREIGN KEY ([PoolId]) REFERENCES [planning].[CapacityPool] ([Id]);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityDay_159] FOREIGN KEY ([ChangedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [planning].[WorkStandardVersion] WITH CHECK ADD CONSTRAINT [FK_planning_WorkStandardVersion_160] FOREIGN KEY ([PoolId]) REFERENCES [planning].[CapacityPool] ([Id]);

ALTER TABLE [planning].[WorkStandardVersion] WITH CHECK ADD CONSTRAINT [FK_planning_WorkStandardVersion_161] FOREIGN KEY ([MaterialId]) REFERENCES [catalog].[Material] ([Id]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_162] FOREIGN KEY ([AllocationId]) REFERENCES [operations].[FulfillmentAllocation] ([Id]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_163] FOREIGN KEY ([PoolId]) REFERENCES [planning].[CapacityPool] ([Id]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_164] FOREIGN KEY ([RescheduledFromId]) REFERENCES [planning].[CapacityBooking] ([Id]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_165] FOREIGN KEY ([ApprovedBy]) REFERENCES [security].[AppUser] ([Id]);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityBooking_166] FOREIGN KEY ([LastOperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_167] FOREIGN KEY ([PoolId]) REFERENCES [planning].[CapacityPool] ([Id]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_168] FOREIGN KEY ([PickConfirmationId]) REFERENCES [warehouse].[PickConfirmation] ([Id]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_169] FOREIGN KEY ([HandlingUnitItemId]) REFERENCES [warehouse].[HandlingUnitItem] ([Id]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_170] FOREIGN KEY ([LoadEventId]) REFERENCES [shipping].[LoadEvent] ([Id]);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [FK_planning_CapacityExecution_171] FOREIGN KEY ([OperationId]) REFERENCES [platform].[OperationRequest] ([Id]);

CREATE UNIQUE INDEX [UX_planning_Driver_1] ON [planning].[Driver] ([UserId]) WHERE UserId IS NOT NULL;

CREATE UNIQUE INDEX [UX_quality_Approval_2] ON [quality].[Approval] ([ExecutedOperationId]) WHERE ExecutedOperationId IS NOT NULL;

CREATE UNIQUE INDEX [UX_shipping_ShipmentUnit_3] ON [shipping].[ShipmentUnit] ([HandlingUnitId]) WHERE ReleasedAtUtc IS NULL;

CREATE UNIQUE INDEX [UX_shipping_Shipment_4] ON [shipping].[Shipment] ([TrailerId]) WHERE ClosedAtUtc IS NULL AND CancelledAtUtc IS NULL;

CREATE UNIQUE INDEX [UX_planning_CapacityExecution_5] ON [planning].[CapacityExecution] ([BookingId], [PickConfirmationId]) WHERE PickConfirmationId IS NOT NULL;

CREATE UNIQUE INDEX [UX_planning_CapacityExecution_6] ON [planning].[CapacityExecution] ([BookingId], [HandlingUnitItemId]) WHERE HandlingUnitItemId IS NOT NULL AND LoadEventId IS NULL;

CREATE UNIQUE INDEX [UX_planning_CapacityExecution_7] ON [planning].[CapacityExecution] ([BookingId], [LoadEventId], [HandlingUnitItemId]) WHERE LoadEventId IS NOT NULL;

CREATE INDEX [IX_security_UserRole_2] ON [security].[UserRole] ([RoleId]);

CREATE INDEX [IX_security_RolePermission_2] ON [security].[RolePermission] ([PermissionId]);

CREATE INDEX [IX_security_UserWarehouse_2] ON [security].[UserWarehouse] ([WarehouseId]);

CREATE INDEX [IX_catalog_Location_1] ON [catalog].[Location] ([ParentLocationId], [WarehouseId]);

CREATE INDEX [IX_catalog_Material_1] ON [catalog].[Material] ([BaseUnitId]);

CREATE INDEX [IX_catalog_MaterialUnitConversion_2] ON [catalog].[MaterialUnitConversion] ([FromUnitId]);

CREATE INDEX [IX_catalog_MaterialIdentifier_1] ON [catalog].[MaterialIdentifier] ([MaterialId]);

CREATE INDEX [IX_catalog_MaterialIdentifier_2] ON [catalog].[MaterialIdentifier] ([UnitId]);

CREATE INDEX [IX_catalog_MaterialLocation_2] ON [catalog].[MaterialLocation] ([LocationId]);

CREATE INDEX [IX_integration_ImportedFile_2] ON [integration].[ImportedFile] ([UploadedBy]);

CREATE INDEX [IX_integration_ImportRun_2] ON [integration].[ImportRun] ([ProfileVersionId]);

CREATE INDEX [IX_integration_ImportRun_3] ON [integration].[ImportRun] ([RequestedBy]);

CREATE INDEX [IX_integration_ImportOrderResult_2] ON [integration].[ImportOrderResult] ([OrderRevisionId]);

CREATE INDEX [IX_integration_ImportRow_1] ON [integration].[ImportRow] ([OrderResultId], [RunId]);

CREATE INDEX [IX_integration_ImportRow_3] ON [integration].[ImportRow] ([AppliedOrderLineId]);

CREATE INDEX [IX_integration_ImportError_1] ON [integration].[ImportError] ([RowId], [RunId]);

CREATE INDEX [IX_integration_ImportError_2] ON [integration].[ImportError] ([RunId]);

CREATE INDEX [IX_operations_SalesOrder_1] ON [operations].[SalesOrder] ([CurrentRevisionId], [Id]);

CREATE INDEX [IX_operations_SalesOrder_3] ON [operations].[SalesOrder] ([CustomerId]);

CREATE INDEX [IX_operations_OrderRevision_2] ON [operations].[OrderRevision] ([AcceptedBy]);

CREATE INDEX [IX_operations_OrderLineRevision_1] ON [operations].[OrderLineRevision] ([OrderRevisionId], [OrderId]);

CREATE INDEX [IX_operations_OrderLineRevision_2] ON [operations].[OrderLineRevision] ([OrderLineId], [OrderId]);

CREATE INDEX [IX_operations_OrderLineRevision_3] ON [operations].[OrderLineRevision] ([OrderId]);

CREATE INDEX [IX_operations_OrderLineRevision_4] ON [operations].[OrderLineRevision] ([MaterialId]);

CREATE INDEX [IX_operations_OrderLineRevision_5] ON [operations].[OrderLineRevision] ([DeliverySiteId]);

CREATE INDEX [IX_operations_OrderLineRevision_6] ON [operations].[OrderLineRevision] ([RequestedUnitId]);

CREATE INDEX [IX_operations_FulfillmentAllocation_1] ON [operations].[FulfillmentAllocation] ([OrderLineRevisionId], [OrderLineId]);

CREATE INDEX [IX_operations_FulfillmentAllocation_2] ON [operations].[FulfillmentAllocation] ([OrderLineId]);

CREATE INDEX [IX_operations_FulfillmentAllocation_3] ON [operations].[FulfillmentAllocation] ([WarehouseId]);

CREATE INDEX [IX_operations_FulfillmentAllocation_4] ON [operations].[FulfillmentAllocation] ([ReleasedBy]);

CREATE INDEX [IX_planning_DistanceReference_2] ON [planning].[DistanceReference] ([DestinationAddressId]);

CREATE INDEX [IX_planning_Trailer_1] ON [planning].[Trailer] ([CarrierId]);

CREATE INDEX [IX_planning_Driver_1] ON [planning].[Driver] ([CarrierId]);

CREATE INDEX [IX_planning_Driver_2] ON [planning].[Driver] ([UserId]);

CREATE INDEX [IX_planning_Trip_1] ON [planning].[Trip] ([CurrentRevisionId], [Id]);

CREATE INDEX [IX_planning_Trip_2] ON [planning].[Trip] ([OriginWarehouseId]);

CREATE INDEX [IX_planning_TripRevision_2] ON [planning].[TripRevision] ([OriginAddressId]);

CREATE INDEX [IX_planning_TripRevision_3] ON [planning].[TripRevision] ([PlannedTrailerId]);

CREATE INDEX [IX_planning_TripRevision_4] ON [planning].[TripRevision] ([PlannedDriverId]);

CREATE INDEX [IX_planning_TripRevision_5] ON [planning].[TripRevision] ([ApprovedBy]);

CREATE INDEX [IX_planning_TripStop_2] ON [planning].[TripStop] ([DeliverySiteId]);

CREATE INDEX [IX_planning_TripStop_3] ON [planning].[TripStop] ([AddressVersionId]);

CREATE INDEX [IX_planning_TripStop_4] ON [planning].[TripStop] ([DistanceFromPreviousId]);

CREATE INDEX [IX_planning_TripAllocation_2] ON [planning].[TripAllocation] ([AllocationId]);

CREATE INDEX [IX_warehouse_PickingTask_1] ON [warehouse].[PickingTask] ([WarehouseId]);

CREATE INDEX [IX_warehouse_PickingTask_2] ON [warehouse].[PickingTask] ([AssignedUserId]);

CREATE INDEX [IX_warehouse_PickingTaskLine_1] ON [warehouse].[PickingTaskLine] ([TaskId]);

CREATE INDEX [IX_warehouse_PickingTaskLine_2] ON [warehouse].[PickingTaskLine] ([AllocationId]);

CREATE INDEX [IX_warehouse_PickingTaskLine_3] ON [warehouse].[PickingTaskLine] ([SourceLocationId]);

CREATE INDEX [IX_warehouse_PickingTaskLine_4] ON [warehouse].[PickingTaskLine] ([LotId]);

CREATE INDEX [IX_warehouse_PickConfirmation_1] ON [warehouse].[PickConfirmation] ([TaskLineId]);

CREATE INDEX [IX_warehouse_PickConfirmation_2] ON [warehouse].[PickConfirmation] ([ActorUserId]);

CREATE INDEX [IX_warehouse_PickConfirmation_3] ON [warehouse].[PickConfirmation] ([OperationId]);

CREATE INDEX [IX_warehouse_PickReversal_2] ON [warehouse].[PickReversal] ([ActorUserId]);

CREATE INDEX [IX_warehouse_PickReversal_3] ON [warehouse].[PickReversal] ([OperationId]);

CREATE INDEX [IX_warehouse_PackingReceipt_1] ON [warehouse].[PackingReceipt] ([PickConfirmationId]);

CREATE INDEX [IX_warehouse_PackingReceipt_2] ON [warehouse].[PackingReceipt] ([PackingLocationId]);

CREATE INDEX [IX_warehouse_PackingReceipt_3] ON [warehouse].[PackingReceipt] ([ReceivedBy]);

CREATE INDEX [IX_warehouse_PackingReceipt_4] ON [warehouse].[PackingReceipt] ([OperationId]);

CREATE INDEX [IX_warehouse_ReceiptReversal_2] ON [warehouse].[ReceiptReversal] ([ActorUserId]);

CREATE INDEX [IX_warehouse_ReceiptReversal_3] ON [warehouse].[ReceiptReversal] ([OperationId]);

CREATE INDEX [IX_warehouse_HandlingUnit_1] ON [warehouse].[HandlingUnit] ([TypeId]);

CREATE INDEX [IX_warehouse_HandlingUnit_2] ON [warehouse].[HandlingUnit] ([WarehouseId]);

CREATE INDEX [IX_warehouse_HandlingUnit_3] ON [warehouse].[HandlingUnit] ([DeliverySiteId]);

CREATE INDEX [IX_warehouse_HandlingUnit_4] ON [warehouse].[HandlingUnit] ([CurrentLocationId]);

CREATE INDEX [IX_warehouse_HandlingUnit_5] ON [warehouse].[HandlingUnit] ([PackedBy]);

CREATE INDEX [IX_warehouse_HandlingUnitItem_1] ON [warehouse].[HandlingUnitItem] ([HandlingUnitId]);

CREATE INDEX [IX_warehouse_HandlingUnitItem_2] ON [warehouse].[HandlingUnitItem] ([ReceiptId]);

CREATE INDEX [IX_warehouse_HandlingUnitItem_3] ON [warehouse].[HandlingUnitItem] ([OperationId]);

CREATE INDEX [IX_warehouse_HandlingUnitItem_4] ON [warehouse].[HandlingUnitItem] ([PackedBy]);

CREATE INDEX [IX_warehouse_PackingReversal_2] ON [warehouse].[PackingReversal] ([ActorUserId]);

CREATE INDEX [IX_warehouse_PackingReversal_3] ON [warehouse].[PackingReversal] ([OperationId]);

CREATE INDEX [IX_warehouse_HandlingUnitMovement_1] ON [warehouse].[HandlingUnitMovement] ([HandlingUnitId]);

CREATE INDEX [IX_warehouse_HandlingUnitMovement_2] ON [warehouse].[HandlingUnitMovement] ([FromLocationId]);

CREATE INDEX [IX_warehouse_HandlingUnitMovement_3] ON [warehouse].[HandlingUnitMovement] ([ToLocationId]);

CREATE INDEX [IX_warehouse_HandlingUnitMovement_4] ON [warehouse].[HandlingUnitMovement] ([ActorUserId]);

CREATE INDEX [IX_warehouse_HandlingUnitMovement_5] ON [warehouse].[HandlingUnitMovement] ([OperationId]);

CREATE INDEX [IX_shipping_Shipment_1] ON [shipping].[Shipment] ([TripRevisionId], [TripId]);

CREATE INDEX [IX_shipping_Shipment_3] ON [shipping].[Shipment] ([TrailerId]);

CREATE INDEX [IX_shipping_Shipment_4] ON [shipping].[Shipment] ([DriverId]);

CREATE INDEX [IX_shipping_Shipment_5] ON [shipping].[Shipment] ([DockLocationId]);

CREATE INDEX [IX_shipping_ShipmentUnit_1] ON [shipping].[ShipmentUnit] ([ShipmentId], [TripRevisionId]);

CREATE INDEX [IX_shipping_ShipmentUnit_2] ON [shipping].[ShipmentUnit] ([StopId], [TripRevisionId]);

CREATE INDEX [IX_shipping_ShipmentUnit_3] ON [shipping].[ShipmentUnit] ([TripRevisionId]);

CREATE INDEX [IX_shipping_ShipmentUnit_4] ON [shipping].[ShipmentUnit] ([HandlingUnitId]);

CREATE INDEX [IX_shipping_ShipmentUnit_5] ON [shipping].[ShipmentUnit] ([AssignedBy]);

CREATE INDEX [IX_shipping_LoadEvent_1] ON [shipping].[LoadEvent] ([ShipmentUnitId]);

CREATE INDEX [IX_shipping_LoadEvent_2] ON [shipping].[LoadEvent] ([WarehouseLocationId]);

CREATE INDEX [IX_shipping_LoadEvent_3] ON [shipping].[LoadEvent] ([ActorUserId]);

CREATE INDEX [IX_shipping_LoadEvent_4] ON [shipping].[LoadEvent] ([OperationId]);

CREATE INDEX [IX_shipping_ShipmentClosure_2] ON [shipping].[ShipmentClosure] ([ClosedBy]);

CREATE INDEX [IX_shipping_ShipmentClosure_3] ON [shipping].[ShipmentClosure] ([OperationId]);

CREATE INDEX [IX_shipping_ShipmentClosure_4] ON [shipping].[ShipmentClosure] ([PartialApprovalId]);

CREATE INDEX [IX_quality_Incident_1] ON [quality].[Incident] ([TypeId]);

CREATE INDEX [IX_quality_Incident_2] ON [quality].[Incident] ([ImportRunId]);

CREATE INDEX [IX_quality_Incident_3] ON [quality].[Incident] ([OrderLineId]);

CREATE INDEX [IX_quality_Incident_4] ON [quality].[Incident] ([TaskLineId]);

CREATE INDEX [IX_quality_Incident_5] ON [quality].[Incident] ([HandlingUnitId]);

CREATE INDEX [IX_quality_Incident_6] ON [quality].[Incident] ([ShipmentId]);

CREATE INDEX [IX_quality_Incident_7] ON [quality].[Incident] ([TripId]);

CREATE INDEX [IX_quality_Incident_8] ON [quality].[Incident] ([ReportedBy]);

CREATE INDEX [IX_quality_IncidentAction_1] ON [quality].[IncidentAction] ([IncidentId]);

CREATE INDEX [IX_quality_IncidentAction_2] ON [quality].[IncidentAction] ([ActorUserId]);

CREATE INDEX [IX_quality_IncidentAction_3] ON [quality].[IncidentAction] ([OperationId]);

CREATE INDEX [IX_quality_Hold_1] ON [quality].[Hold] ([OrderLineId]);

CREATE INDEX [IX_quality_Hold_2] ON [quality].[Hold] ([HandlingUnitId]);

CREATE INDEX [IX_quality_Hold_3] ON [quality].[Hold] ([ShipmentId]);

CREATE INDEX [IX_quality_Hold_4] ON [quality].[Hold] ([IncidentId]);

CREATE INDEX [IX_quality_Hold_5] ON [quality].[Hold] ([PlacedBy]);

CREATE INDEX [IX_quality_Hold_6] ON [quality].[Hold] ([ReleasedBy]);

CREATE INDEX [IX_quality_Approval_1] ON [quality].[Approval] ([IncidentId]);

CREATE INDEX [IX_quality_Approval_2] ON [quality].[Approval] ([OrderLineId]);

CREATE INDEX [IX_quality_Approval_3] ON [quality].[Approval] ([HandlingUnitId]);

CREATE INDEX [IX_quality_Approval_4] ON [quality].[Approval] ([ShipmentId]);

CREATE INDEX [IX_quality_Approval_5] ON [quality].[Approval] ([TripId]);

CREATE INDEX [IX_quality_Approval_6] ON [quality].[Approval] ([RequestedBy]);

CREATE INDEX [IX_quality_Approval_7] ON [quality].[Approval] ([DecidedBy]);

CREATE INDEX [IX_quality_Approval_8] ON [quality].[Approval] ([ExecutedOperationId]);

CREATE INDEX [IX_audit_AuditEvent_1] ON [audit].[AuditEvent] ([OperationId]);

CREATE INDEX [IX_audit_AuditEvent_2] ON [audit].[AuditEvent] ([ActorUserId]);

CREATE INDEX [IX_planning_CapacityPool_2] ON [planning].[CapacityPool] ([CapacityUnitId]);

CREATE INDEX [IX_planning_CapacityDay_2] ON [planning].[CapacityDay] ([ChangedBy]);

CREATE INDEX [IX_planning_WorkStandardVersion_2] ON [planning].[WorkStandardVersion] ([MaterialId]);

CREATE INDEX [IX_planning_CapacityBooking_1] ON [planning].[CapacityBooking] ([CapacityDayId], [PoolId]);

CREATE INDEX [IX_planning_CapacityBooking_2] ON [planning].[CapacityBooking] ([WorkStandardVersionId], [PoolId]);

CREATE INDEX [IX_planning_CapacityBooking_3] ON [planning].[CapacityBooking] ([AllocationId]);

CREATE INDEX [IX_planning_CapacityBooking_4] ON [planning].[CapacityBooking] ([PoolId]);

CREATE INDEX [IX_planning_CapacityBooking_5] ON [planning].[CapacityBooking] ([RescheduledFromId]);

CREATE INDEX [IX_planning_CapacityBooking_6] ON [planning].[CapacityBooking] ([ApprovedBy]);

CREATE INDEX [IX_planning_CapacityBooking_7] ON [planning].[CapacityBooking] ([LastOperationId]);

CREATE INDEX [IX_planning_CapacityExecution_1] ON [planning].[CapacityExecution] ([BookingId], [PoolId]);

CREATE INDEX [IX_planning_CapacityExecution_2] ON [planning].[CapacityExecution] ([ActualCapacityDayId], [PoolId]);

CREATE INDEX [IX_planning_CapacityExecution_3] ON [planning].[CapacityExecution] ([PoolId]);

CREATE INDEX [IX_planning_CapacityExecution_4] ON [planning].[CapacityExecution] ([PickConfirmationId]);

CREATE INDEX [IX_planning_CapacityExecution_5] ON [planning].[CapacityExecution] ([HandlingUnitItemId]);

CREATE INDEX [IX_planning_CapacityExecution_6] ON [planning].[CapacityExecution] ([LoadEventId]);

CREATE INDEX [IX_planning_CapacityExecution_7] ON [planning].[CapacityExecution] ([OperationId]);
'');
EXEC(N''INSERT INTO platform.SchemaMigration (ApplicationCode,Version,ScriptChecksum,AppliedAtUtc,ApplicationVersion) VALUES (N''''PickingPackingEmbarques'''',N''''002'''',0x27a748d064a39209ff56884ac9999a0716bfe5045c7b2eef5b422c45eb48fb5c,SYSUTCDATETIME(),N''''0.2'''');'');

EXEC(N''-- Row-level integrity. Aggregate quantities, workflow and authorization belong to transactional backend services.

ALTER TABLE [security].[AppUser] WITH CHECK ADD CONSTRAINT [CK_security_AppUser_1] CHECK (LEN(LTRIM(RTRIM([Login]))) > 0);

ALTER TABLE [security].[Role] WITH CHECK ADD CONSTRAINT [CK_security_Role_2] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [security].[Permission] WITH CHECK ADD CONSTRAINT [CK_security_Permission_3] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [platform].[OperationRequest] WITH CHECK ADD CONSTRAINT [CK_platform_OperationRequest_4] CHECK ([ResultJson] IS NULL OR ISJSON([ResultJson]) = 1);

ALTER TABLE [catalog].[LogisticsPoint] WITH CHECK ADD CONSTRAINT [CK_catalog_LogisticsPoint_5] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_6] CHECK ([VersionNumber] > 0);

ALTER TABLE [catalog].[Warehouse] WITH CHECK ADD CONSTRAINT [CK_catalog_Warehouse_7] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [CK_catalog_Location_8] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[Customer] WITH CHECK ADD CONSTRAINT [CK_catalog_Customer_9] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[DeliverySite] WITH CHECK ADD CONSTRAINT [CK_catalog_DeliverySite_10] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[UnitOfMeasure] WITH CHECK ADD CONSTRAINT [CK_catalog_UnitOfMeasure_11] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[Material] WITH CHECK ADD CONSTRAINT [CK_catalog_Material_12] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [catalog].[MaterialUnitConversion] WITH CHECK ADD CONSTRAINT [CK_catalog_MaterialUnitConversion_13] CHECK ([FactorToBase] > 0);

ALTER TABLE [catalog].[MaterialUnitConversion] WITH CHECK ADD CONSTRAINT [CK_catalog_MaterialUnitConversion_14] CHECK ([VersionNumber] > 0);

ALTER TABLE [catalog].[HandlingUnitType] WITH CHECK ADD CONSTRAINT [CK_catalog_HandlingUnitType_15] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [integration].[SourceSystem] WITH CHECK ADD CONSTRAINT [CK_integration_SourceSystem_16] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [integration].[MappingProfileVersion] WITH CHECK ADD CONSTRAINT [CK_integration_MappingProfileVersion_17] CHECK ([VersionNumber] > 0);

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_18] CHECK ([AttemptNumber] > 0);

ALTER TABLE [integration].[ImportOrderResult] WITH CHECK ADD CONSTRAINT [CK_integration_ImportOrderResult_19] CHECK (LEN(LTRIM(RTRIM([ExternalOrderNumber]))) > 0);

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_20] CHECK ([RecordNumber] > 0);

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_21] CHECK ([PhysicalLineStart] > 0);

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_22] CHECK ([ParsedJson] IS NULL OR ISJSON([ParsedJson]) = 1);

ALTER TABLE [operations].[SalesOrder] WITH CHECK ADD CONSTRAINT [CK_operations_SalesOrder_23] CHECK (LEN(LTRIM(RTRIM([ExternalOrderNumber]))) > 0);

ALTER TABLE [operations].[OrderRevision] WITH CHECK ADD CONSTRAINT [CK_operations_OrderRevision_24] CHECK ([RevisionNumber] > 0);

ALTER TABLE [operations].[OrderLine] WITH CHECK ADD CONSTRAINT [CK_operations_OrderLine_25] CHECK (LEN(LTRIM(RTRIM([ExternalLineKey]))) > 0);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [CK_operations_OrderLineRevision_26] CHECK ([RequestedQuantity] > 0);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [CK_operations_OrderLineRevision_27] CHECK ([FactorToBase] > 0);

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [CK_operations_OrderLineRevision_28] CHECK ([RequiredBaseQuantity] > 0);

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [CK_operations_FulfillmentAllocation_29] CHECK ([AllocatedBaseQuantity] > 0);

ALTER TABLE [planning].[Carrier] WITH CHECK ADD CONSTRAINT [CK_planning_Carrier_30] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [planning].[Trailer] WITH CHECK ADD CONSTRAINT [CK_planning_Trailer_31] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [planning].[Driver] WITH CHECK ADD CONSTRAINT [CK_planning_Driver_32] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [planning].[Trip] WITH CHECK ADD CONSTRAINT [CK_planning_Trip_33] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [CK_planning_TripRevision_34] CHECK ([RevisionNumber] > 0);

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [CK_planning_TripStop_35] CHECK ([SequenceNumber] > 0);

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [CK_planning_TripAllocation_36] CHECK ([PlannedBaseQuantity] > 0);

ALTER TABLE [warehouse].[PickingTask] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickingTask_37] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickingTaskLine_38] CHECK ([PlannedBaseQuantity] > 0);

ALTER TABLE [warehouse].[PickConfirmation] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickConfirmation_39] CHECK ([BaseQuantity] > 0);

ALTER TABLE [warehouse].[PackingReceipt] WITH CHECK ADD CONSTRAINT [CK_warehouse_PackingReceipt_40] CHECK ([BaseQuantity] > 0);

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [CK_warehouse_HandlingUnit_41] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [warehouse].[HandlingUnitItem] WITH CHECK ADD CONSTRAINT [CK_warehouse_HandlingUnitItem_42] CHECK ([BaseQuantity] > 0);

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentClosure_43] CHECK ([ManifestJson] IS NULL OR ISJSON([ManifestJson]) = 1);

ALTER TABLE [quality].[IncidentType] WITH CHECK ADD CONSTRAINT [CK_quality_IncidentType_44] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_45] CHECK ([ReviewPayloadJson] IS NULL OR ISJSON([ReviewPayloadJson]) = 1);

ALTER TABLE [audit].[AuditEvent] WITH CHECK ADD CONSTRAINT [CK_audit_AuditEvent_46] CHECK ([BeforeJson] IS NULL OR ISJSON([BeforeJson]) = 1);

ALTER TABLE [audit].[AuditEvent] WITH CHECK ADD CONSTRAINT [CK_audit_AuditEvent_47] CHECK ([AfterJson] IS NULL OR ISJSON([AfterJson]) = 1);

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_48] CHECK (LEN(LTRIM(RTRIM([Code]))) > 0);

ALTER TABLE [planning].[WorkStandardVersion] WITH CHECK ADD CONSTRAINT [CK_planning_WorkStandardVersion_49] CHECK ([VersionNumber] > 0);

ALTER TABLE [planning].[WorkStandardVersion] WITH CHECK ADD CONSTRAINT [CK_planning_WorkStandardVersion_50] CHECK ([CapacityPerBaseUnit] > 0);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_51] CHECK ([PlannedBaseQuantity] > 0);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityExecution_52] CHECK ([BaseQuantity] > 0);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityExecution_53] CHECK ([UsedStandardCapacity] > 0);

ALTER TABLE [security].[AppUser] WITH CHECK ADD CONSTRAINT [CK_security_AppUser_54] CHECK (FailedLoginCount >= 0);

ALTER TABLE [platform].[OperationRequest] WITH CHECK ADD CONSTRAINT [CK_platform_OperationRequest_55] CHECK ([Outcome] IN (N''''SUCCEEDED'''',N''''REJECTED''''));

ALTER TABLE [platform].[OperationRequest] WITH CHECK ADD CONSTRAINT [CK_platform_OperationRequest_56] CHECK (ResponseCode BETWEEN 100 AND 599);

ALTER TABLE [catalog].[LogisticsPoint] WITH CHECK ADD CONSTRAINT [CK_catalog_LogisticsPoint_57] CHECK ([PointType] IN (N''''WAREHOUSE'''',N''''DELIVERY_SITE''''));

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [CK_catalog_Location_58] CHECK ([LocationType] IN (N''''ZONE'''',N''''AISLE'''',N''''BIN'''',N''''PACKING'''',N''''STAGING'''',N''''DOCK''''));

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [CK_catalog_Location_59] CHECK (ParentLocationId IS NULL OR ParentLocationId <> Id);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_60] CHECK (Latitude BETWEEN -90 AND 90);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_61] CHECK (Longitude BETWEEN -180 AND 180);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_62] CHECK (([Latitude] IS NULL AND [Longitude] IS NULL) OR ([Latitude] IS NOT NULL AND [Longitude] IS NOT NULL));

ALTER TABLE [catalog].[DeliveryWindow] WITH CHECK ADD CONSTRAINT [CK_catalog_DeliveryWindow_63] CHECK (WeekDay BETWEEN 1 AND 7 AND EndLocal > StartLocal AND (ValidTo IS NULL OR ValidTo >= ValidFrom));

ALTER TABLE [catalog].[UnitOfMeasure] WITH CHECK ADD CONSTRAINT [CK_catalog_UnitOfMeasure_64] CHECK (QuantityScale BETWEEN 0 AND 6);

ALTER TABLE [catalog].[MaterialLot] WITH CHECK ADD CONSTRAINT [CK_catalog_MaterialLot_65] CHECK (ManufacturedOn IS NULL OR ExpiresOn IS NULL OR ExpiresOn >= ManufacturedOn);

ALTER TABLE [integration].[MappingProfileVersion] WITH CHECK ADD CONSTRAINT [CK_integration_MappingProfileVersion_66] CHECK ([Mode] IN (N''''ORDER_SNAPSHOT''''));

ALTER TABLE [integration].[MappingField] WITH CHECK ADD CONSTRAINT [CK_integration_MappingField_67] CHECK (CASE WHEN [SourceColumnName] IS NULL THEN 0 ELSE 1 END + CASE WHEN [SourceColumnIndex] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ConstantValue] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [integration].[MappingField] WITH CHECK ADD CONSTRAINT [CK_integration_MappingField_68] CHECK (SourceColumnIndex IS NULL OR SourceColumnIndex >= 0);

ALTER TABLE [integration].[ImportedFile] WITH CHECK ADD CONSTRAINT [CK_integration_ImportedFile_69] CHECK (ByteLength >= 0);

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_70] CHECK ([Status] IN (N''''RECEIVED'''',N''''PROCESSING'''',N''''COMPLETED'''',N''''PARTIAL'''',N''''FAILED'''',N''''DUPLICATE''''));

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_71] CHECK (([LeaseToken] IS NULL AND [LeaseExpiresAtUtc] IS NULL) OR ([LeaseToken] IS NOT NULL AND [LeaseExpiresAtUtc] IS NOT NULL));

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_72] CHECK (FinishedAtUtc IS NULL OR (StartedAtUtc IS NOT NULL AND FinishedAtUtc >= StartedAtUtc));

ALTER TABLE [integration].[ImportOrderResult] WITH CHECK ADD CONSTRAINT [CK_integration_ImportOrderResult_73] CHECK ([Status] IN (N''''PENDING'''',N''''APPLIED'''',N''''REJECTED'''',N''''UNCHANGED''''));

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_74] CHECK ([Status] IN (N''''PENDING'''',N''''VALID'''',N''''INVALID'''',N''''APPLIED''''));

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_75] CHECK (PhysicalLineEnd >= PhysicalLineStart);

ALTER TABLE [integration].[ImportError] WITH CHECK ADD CONSTRAINT [CK_integration_ImportError_76] CHECK ([Severity] IN (N''''ERROR'''',N''''WARNING''''));

ALTER TABLE [operations].[SalesOrder] WITH CHECK ADD CONSTRAINT [CK_operations_SalesOrder_77] CHECK ([Status] IN (N''''CREATED'''',N''''RELEASED'''',N''''IN_PROGRESS'''',N''''COMPLETED'''',N''''CANCELLED''''));

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [CK_operations_OrderLineRevision_78] CHECK (RequiredBaseQuantity = CONVERT(decimal(19,6), RequestedQuantity * FactorToBase));

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [CK_operations_FulfillmentAllocation_79] CHECK ([Status] IN (N''''DRAFT'''',N''''RELEASED'''',N''''IN_PROGRESS'''',N''''COMPLETED'''',N''''CANCELLED''''));

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [CK_operations_FulfillmentAllocation_80] CHECK (([ReleasedAtUtc] IS NULL AND [ReleasedBy] IS NULL) OR ([ReleasedAtUtc] IS NOT NULL AND [ReleasedBy] IS NOT NULL));

ALTER TABLE [planning].[DistanceReference] WITH CHECK ADD CONSTRAINT [CK_planning_DistanceReference_81] CHECK (RoadDistanceKm >= 0 AND (ReferenceMinutes IS NULL OR ReferenceMinutes >= 0) AND (ValidUntil IS NULL OR ValidUntil >= MeasuredOn));

ALTER TABLE [planning].[Trip] WITH CHECK ADD CONSTRAINT [CK_planning_Trip_82] CHECK ([Status] IN (N''''DRAFT'''',N''''RELEASED'''',N''''LOADING'''',N''''CLOSED'''',N''''CANCELLED''''));

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [CK_planning_TripRevision_83] CHECK ([Status] IN (N''''DRAFT'''',N''''APPROVED'''',N''''SUPERSEDED''''));

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [CK_planning_TripRevision_84] CHECK (([ApprovedBy] IS NULL AND [ApprovedAtUtc] IS NULL) OR ([ApprovedBy] IS NOT NULL AND [ApprovedAtUtc] IS NOT NULL));

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [CK_planning_TripStop_85] CHECK (([WindowStartUtc] IS NULL AND [WindowEndUtc] IS NULL) OR ([WindowStartUtc] IS NOT NULL AND [WindowEndUtc] IS NOT NULL));

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [CK_planning_TripStop_86] CHECK (WindowEndUtc IS NULL OR WindowEndUtc > WindowStartUtc);

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [CK_planning_TripAllocation_87] CHECK ([Status] IN (N''''DRAFT'''',N''''RELEASED'''',N''''COMPLETED'''',N''''CANCELLED''''));

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [CK_planning_TripAllocation_88] CHECK (CancelledBaseQuantity >= 0 AND CancelledBaseQuantity <= PlannedBaseQuantity);

ALTER TABLE [warehouse].[PickingTask] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickingTask_89] CHECK ([Status] IN (N''''OPEN'''',N''''ASSIGNED'''',N''''IN_PROGRESS'''',N''''COMPLETED'''',N''''CANCELLED''''));

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickingTaskLine_90] CHECK ([Status] IN (N''''OPEN'''',N''''IN_PROGRESS'''',N''''COMPLETED'''',N''''CANCELLED''''));

ALTER TABLE [warehouse].[PickConfirmation] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickConfirmation_91] CHECK ([CaptureMethod] IN (N''''MANUAL'''',N''''CAMERA'''',N''''KEYBOARD_SCANNER''''));

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [CK_warehouse_HandlingUnit_92] CHECK ([Status] IN (N''''OPEN'''',N''''PACKED'''',N''''STAGED'''',N''''LOADED'''',N''''SHIPPED'''',N''''VOID''''));

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [CK_warehouse_HandlingUnit_93] CHECK (([PackedAtUtc] IS NULL AND [PackedBy] IS NULL) OR ([PackedAtUtc] IS NOT NULL AND [PackedBy] IS NOT NULL));

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [CK_shipping_Shipment_94] CHECK ([Status] IN (N''''OPEN'''',N''''LOADING'''',N''''CLOSED'''',N''''CANCELLED''''));

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [CK_shipping_Shipment_95] CHECK ((Status IN (''''OPEN'''',''''LOADING'''') AND ClosedAtUtc IS NULL AND CancelledAtUtc IS NULL) OR (Status=''''CLOSED'''' AND ClosedAtUtc IS NOT NULL AND CancelledAtUtc IS NULL) OR (Status=''''CANCELLED'''' AND CancelledAtUtc IS NOT NULL AND ClosedAtUtc IS NULL));

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [CK_shipping_Shipment_96] CHECK ((ClosedAtUtc IS NULL OR ClosedAtUtc >= OpenedAtUtc) AND (CancelledAtUtc IS NULL OR CancelledAtUtc >= OpenedAtUtc));

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentUnit_97] CHECK ([Status] IN (N''''ASSIGNED'''',N''''LOADED'''',N''''DISPATCHED'''',N''''RELEASED''''));

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentUnit_98] CHECK ((Status=''''RELEASED'''' AND ReleasedAtUtc IS NOT NULL AND ReleasedAtUtc >= AssignedAtUtc) OR (Status <> ''''RELEASED'''' AND ReleasedAtUtc IS NULL));

ALTER TABLE [shipping].[LoadEvent] WITH CHECK ADD CONSTRAINT [CK_shipping_LoadEvent_99] CHECK ([EventType] IN (N''''LOAD'''',N''''UNLOAD''''));

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentClosure_100] CHECK (IsPartial = 0 OR PartialApprovalId IS NOT NULL);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [CK_quality_Incident_101] CHECK (CASE WHEN [ImportRunId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [OrderLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [TaskLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [HandlingUnitId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ShipmentId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [TripId] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [CK_quality_Incident_102] CHECK ([Status] IN (N''''OPEN'''',N''''INVESTIGATING'''',N''''RESOLVED'''',N''''CANCELLED''''));

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [CK_quality_Hold_103] CHECK (CASE WHEN [OrderLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [HandlingUnitId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ShipmentId] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [CK_quality_Hold_104] CHECK ((ReleasedAtUtc IS NULL AND ReleasedBy IS NULL AND ReleaseReason IS NULL) OR (ReleasedAtUtc IS NOT NULL AND ReleasedBy IS NOT NULL AND ReleaseReason IS NOT NULL));

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_105] CHECK (CASE WHEN [OrderLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [HandlingUnitId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ShipmentId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [TripId] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_106] CHECK ([Decision] IN (N''''PENDING'''',N''''APPROVED'''',N''''REJECTED'''',N''''EXPIRED''''));

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_107] CHECK (([DecidedBy] IS NULL AND [DecidedAtUtc] IS NULL) OR ([DecidedBy] IS NOT NULL AND [DecidedAtUtc] IS NOT NULL));

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_108] CHECK (Decision NOT IN (''''APPROVED'''',''''REJECTED'''') OR DecidedBy IS NOT NULL);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_109] CHECK (ExecutedOperationId IS NULL OR Decision=''''APPROVED'''');

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_110] CHECK ([StageCode] IN (N''''PICKING'''',N''''PACKING'''',N''''LOADING''''));

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_111] CHECK ([CapacityBasis] IN (N''''BASE_QUANTITY'''',N''''STANDARD_MINUTES''''));

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_112] CHECK ((CapacityBasis=''''BASE_QUANTITY'''' AND CapacityUnitId IS NOT NULL) OR (CapacityBasis=''''STANDARD_MINUTES'''' AND CapacityUnitId IS NULL));

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_113] CHECK ([Status] IN (N''''OPEN'''',N''''CLOSED''''));

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_114] CHECK (BaseCapacity >= 0 AND ExtraCapacity >= 0 AND UnavailableCapacity >= 0 AND BaseCapacity + ExtraCapacity >= UnavailableCapacity);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_115] CHECK (([WindowStartUtc] IS NULL AND [WindowEndUtc] IS NULL) OR ([WindowStartUtc] IS NOT NULL AND [WindowEndUtc] IS NOT NULL));

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_116] CHECK (WindowEndUtc IS NULL OR WindowEndUtc > WindowStartUtc);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_117] CHECK (BaseCapacity + ExtraCapacity - UnavailableCapacity = 0 OR WindowStartUtc IS NOT NULL);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_118] CHECK ((Status=''''OPEN'''' AND ClosedAtUtc IS NULL) OR (Status=''''CLOSED'''' AND ClosedAtUtc IS NOT NULL));

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_119] CHECK ([Status] IN (N''''DRAFT'''',N''''COMMITTED'''',N''''COMPLETED'''',N''''CANCELLED''''));

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_120] CHECK (ReleasedBaseQuantity >= 0 AND ReleasedBaseQuantity <= PlannedBaseQuantity);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_121] CHECK (([ApprovedBy] IS NULL AND [ApprovedAtUtc] IS NULL) OR ([ApprovedBy] IS NOT NULL AND [ApprovedAtUtc] IS NOT NULL));

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_122] CHECK (Status NOT IN (''''COMMITTED'''',''''COMPLETED'''') OR ApprovedBy IS NOT NULL);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_123] CHECK (RescheduledFromId IS NULL OR RescheduledFromId <> Id);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityExecution_124] CHECK ((PickConfirmationId IS NOT NULL AND HandlingUnitItemId IS NULL AND LoadEventId IS NULL) OR (PickConfirmationId IS NULL AND HandlingUnitItemId IS NOT NULL));
'');
EXEC(N''INSERT INTO platform.SchemaMigration (ApplicationCode,Version,ScriptChecksum,AppliedAtUtc,ApplicationVersion) VALUES (N''''PickingPackingEmbarques'''',N''''003'''',0xf41ac156ae1ee89b69c86b04fa5ee74086a555e3b1c282a4431f86a027603270,SYSUTCDATETIME(),N''''0.2'''');'');

EXEC(N''-- Minimal reference data. No enabled accounts, credentials, orders or fictitious confirmations.
INSERT INTO [security].[Role] ([Code],[Name],[IsActive]) VALUES
(N''''ADMIN'''',N''''Administrador'''',1),(N''''SUPERVISOR'''',N''''Supervisor'''',1),
(N''''FORKLIFT'''',N''''Montacarguista'''',1),(N''''PACKING'''',N''''Packing'''',1),
(N''''SHIPPING'''',N''''Embarques'''',1),(N''''DRIVER'''',N''''Chofer: consulta previa a salida'''',1);
INSERT INTO [catalog].[UnitOfMeasure] ([Code],[Name],[QuantityScale],[IsActive]) VALUES
(N''''PZA'''',N''''Pieza'''',0,1),(N''''KG'''',N''''Kilogramo'''',3,1),(N''''M'''',N''''Metro'''',3,1);
INSERT INTO [catalog].[HandlingUnitType] ([Code],[Name],[IsActive]) VALUES
(N''''PALLET'''',N''''Tarima'''',1),(N''''BOX'''',N''''Caja'''',1);
'');
EXEC(N''INSERT INTO platform.SchemaMigration (ApplicationCode,Version,ScriptChecksum,AppliedAtUtc,ApplicationVersion) VALUES (N''''PickingPackingEmbarques'''',N''''004'''',0xfb3fff542a337ca31679d4768ab4f5cc34212d0acade2b65cd5994c6b7049438,SYSUTCDATETIME(),N''''0.2'''');'');

EXEC(N''-- Customer-facing identifier; preserve internal keys and external order numbers.
ALTER TABLE operations.SalesOrder ADD DisplayOrderId nvarchar(100) NULL;
EXEC(N''''UPDATE operations.SalesOrder SET DisplayOrderId=ExternalOrderNumber'''');
EXEC(N''''CREATE UNIQUE INDEX UX_SalesOrder_DisplayOrderId ON operations.SalesOrder(SourceSystemId,DisplayOrderId) WHERE DisplayOrderId IS NOT NULL'''');
'');
EXEC(N''INSERT INTO platform.SchemaMigration (ApplicationCode,Version,ScriptChecksum,AppliedAtUtc,ApplicationVersion) VALUES (N''''PickingPackingEmbarques'''',N''''005'''',0x62e8272b15833968af7f756488c0582f0c4148a3a356d4fd45f4133f29fc6987,SYSUTCDATETIME(),N''''0.2'''');'');

 COMMIT;
 SELECT DB_NAME() AS BaseCreada, COUNT(*) AS Tablas FROM sys.tables WHERE is_ms_shipped=0;
 PRINT N''Instalacion 0.2 terminada: 68 tablas y catalogos iniciales.'';
END TRY
BEGIN CATCH
 IF XACT_STATE() <> 0 ROLLBACK;
 THROW;
END CATCH;
');
 EXEC sys.sp_releaseapplock @Resource=N'PickingPackingEmbarques:install:4003f77415bd1f590f21b0fb7d9049f150ea58aec852247b0f9a5f91af62661e', @LockOwner='Session';
END TRY
BEGIN CATCH
 EXEC sys.sp_releaseapplock @Resource=N'PickingPackingEmbarques:install:4003f77415bd1f590f21b0fb7d9049f150ea58aec852247b0f9a5f91af62661e', @LockOwner='Session';
 THROW;
END CATCH;
