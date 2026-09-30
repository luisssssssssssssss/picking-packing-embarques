-- Row-level integrity. Aggregate quantities, workflow and authorization belong to transactional backend services.

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

ALTER TABLE [platform].[OperationRequest] WITH CHECK ADD CONSTRAINT [CK_platform_OperationRequest_55] CHECK ([Outcome] IN (N'SUCCEEDED',N'REJECTED'));

ALTER TABLE [platform].[OperationRequest] WITH CHECK ADD CONSTRAINT [CK_platform_OperationRequest_56] CHECK (ResponseCode BETWEEN 100 AND 599);

ALTER TABLE [catalog].[LogisticsPoint] WITH CHECK ADD CONSTRAINT [CK_catalog_LogisticsPoint_57] CHECK ([PointType] IN (N'WAREHOUSE',N'DELIVERY_SITE'));

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [CK_catalog_Location_58] CHECK ([LocationType] IN (N'ZONE',N'AISLE',N'BIN',N'PACKING',N'STAGING',N'DOCK'));

ALTER TABLE [catalog].[Location] WITH CHECK ADD CONSTRAINT [CK_catalog_Location_59] CHECK (ParentLocationId IS NULL OR ParentLocationId <> Id);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_60] CHECK (Latitude BETWEEN -90 AND 90);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_61] CHECK (Longitude BETWEEN -180 AND 180);

ALTER TABLE [catalog].[PointAddress] WITH CHECK ADD CONSTRAINT [CK_catalog_PointAddress_62] CHECK (([Latitude] IS NULL AND [Longitude] IS NULL) OR ([Latitude] IS NOT NULL AND [Longitude] IS NOT NULL));

ALTER TABLE [catalog].[DeliveryWindow] WITH CHECK ADD CONSTRAINT [CK_catalog_DeliveryWindow_63] CHECK (WeekDay BETWEEN 1 AND 7 AND EndLocal > StartLocal AND (ValidTo IS NULL OR ValidTo >= ValidFrom));

ALTER TABLE [catalog].[UnitOfMeasure] WITH CHECK ADD CONSTRAINT [CK_catalog_UnitOfMeasure_64] CHECK (QuantityScale BETWEEN 0 AND 6);

ALTER TABLE [catalog].[MaterialLot] WITH CHECK ADD CONSTRAINT [CK_catalog_MaterialLot_65] CHECK (ManufacturedOn IS NULL OR ExpiresOn IS NULL OR ExpiresOn >= ManufacturedOn);

ALTER TABLE [integration].[MappingProfileVersion] WITH CHECK ADD CONSTRAINT [CK_integration_MappingProfileVersion_66] CHECK ([Mode] IN (N'ORDER_SNAPSHOT'));

ALTER TABLE [integration].[MappingField] WITH CHECK ADD CONSTRAINT [CK_integration_MappingField_67] CHECK (CASE WHEN [SourceColumnName] IS NULL THEN 0 ELSE 1 END + CASE WHEN [SourceColumnIndex] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ConstantValue] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [integration].[MappingField] WITH CHECK ADD CONSTRAINT [CK_integration_MappingField_68] CHECK (SourceColumnIndex IS NULL OR SourceColumnIndex >= 0);

ALTER TABLE [integration].[ImportedFile] WITH CHECK ADD CONSTRAINT [CK_integration_ImportedFile_69] CHECK (ByteLength >= 0);

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_70] CHECK ([Status] IN (N'RECEIVED',N'PROCESSING',N'COMPLETED',N'PARTIAL',N'FAILED',N'DUPLICATE'));

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_71] CHECK (([LeaseToken] IS NULL AND [LeaseExpiresAtUtc] IS NULL) OR ([LeaseToken] IS NOT NULL AND [LeaseExpiresAtUtc] IS NOT NULL));

ALTER TABLE [integration].[ImportRun] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRun_72] CHECK (FinishedAtUtc IS NULL OR (StartedAtUtc IS NOT NULL AND FinishedAtUtc >= StartedAtUtc));

ALTER TABLE [integration].[ImportOrderResult] WITH CHECK ADD CONSTRAINT [CK_integration_ImportOrderResult_73] CHECK ([Status] IN (N'PENDING',N'APPLIED',N'REJECTED',N'UNCHANGED'));

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_74] CHECK ([Status] IN (N'PENDING',N'VALID',N'INVALID',N'APPLIED'));

ALTER TABLE [integration].[ImportRow] WITH CHECK ADD CONSTRAINT [CK_integration_ImportRow_75] CHECK (PhysicalLineEnd >= PhysicalLineStart);

ALTER TABLE [integration].[ImportError] WITH CHECK ADD CONSTRAINT [CK_integration_ImportError_76] CHECK ([Severity] IN (N'ERROR',N'WARNING'));

ALTER TABLE [operations].[SalesOrder] WITH CHECK ADD CONSTRAINT [CK_operations_SalesOrder_77] CHECK ([Status] IN (N'CREATED',N'RELEASED',N'IN_PROGRESS',N'COMPLETED',N'CANCELLED'));

ALTER TABLE [operations].[OrderLineRevision] WITH CHECK ADD CONSTRAINT [CK_operations_OrderLineRevision_78] CHECK (RequiredBaseQuantity = CONVERT(decimal(19,6), RequestedQuantity * FactorToBase));

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [CK_operations_FulfillmentAllocation_79] CHECK ([Status] IN (N'DRAFT',N'RELEASED',N'IN_PROGRESS',N'COMPLETED',N'CANCELLED'));

ALTER TABLE [operations].[FulfillmentAllocation] WITH CHECK ADD CONSTRAINT [CK_operations_FulfillmentAllocation_80] CHECK (([ReleasedAtUtc] IS NULL AND [ReleasedBy] IS NULL) OR ([ReleasedAtUtc] IS NOT NULL AND [ReleasedBy] IS NOT NULL));

ALTER TABLE [planning].[DistanceReference] WITH CHECK ADD CONSTRAINT [CK_planning_DistanceReference_81] CHECK (RoadDistanceKm >= 0 AND (ReferenceMinutes IS NULL OR ReferenceMinutes >= 0) AND (ValidUntil IS NULL OR ValidUntil >= MeasuredOn));

ALTER TABLE [planning].[Trip] WITH CHECK ADD CONSTRAINT [CK_planning_Trip_82] CHECK ([Status] IN (N'DRAFT',N'RELEASED',N'LOADING',N'CLOSED',N'CANCELLED'));

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [CK_planning_TripRevision_83] CHECK ([Status] IN (N'DRAFT',N'APPROVED',N'SUPERSEDED'));

ALTER TABLE [planning].[TripRevision] WITH CHECK ADD CONSTRAINT [CK_planning_TripRevision_84] CHECK (([ApprovedBy] IS NULL AND [ApprovedAtUtc] IS NULL) OR ([ApprovedBy] IS NOT NULL AND [ApprovedAtUtc] IS NOT NULL));

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [CK_planning_TripStop_85] CHECK (([WindowStartUtc] IS NULL AND [WindowEndUtc] IS NULL) OR ([WindowStartUtc] IS NOT NULL AND [WindowEndUtc] IS NOT NULL));

ALTER TABLE [planning].[TripStop] WITH CHECK ADD CONSTRAINT [CK_planning_TripStop_86] CHECK (WindowEndUtc IS NULL OR WindowEndUtc > WindowStartUtc);

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [CK_planning_TripAllocation_87] CHECK ([Status] IN (N'DRAFT',N'RELEASED',N'COMPLETED',N'CANCELLED'));

ALTER TABLE [planning].[TripAllocation] WITH CHECK ADD CONSTRAINT [CK_planning_TripAllocation_88] CHECK (CancelledBaseQuantity >= 0 AND CancelledBaseQuantity <= PlannedBaseQuantity);

ALTER TABLE [warehouse].[PickingTask] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickingTask_89] CHECK ([Status] IN (N'OPEN',N'ASSIGNED',N'IN_PROGRESS',N'COMPLETED',N'CANCELLED'));

ALTER TABLE [warehouse].[PickingTaskLine] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickingTaskLine_90] CHECK ([Status] IN (N'OPEN',N'IN_PROGRESS',N'COMPLETED',N'CANCELLED'));

ALTER TABLE [warehouse].[PickConfirmation] WITH CHECK ADD CONSTRAINT [CK_warehouse_PickConfirmation_91] CHECK ([CaptureMethod] IN (N'MANUAL',N'CAMERA',N'KEYBOARD_SCANNER'));

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [CK_warehouse_HandlingUnit_92] CHECK ([Status] IN (N'OPEN',N'PACKED',N'STAGED',N'LOADED',N'SHIPPED',N'VOID'));

ALTER TABLE [warehouse].[HandlingUnit] WITH CHECK ADD CONSTRAINT [CK_warehouse_HandlingUnit_93] CHECK (([PackedAtUtc] IS NULL AND [PackedBy] IS NULL) OR ([PackedAtUtc] IS NOT NULL AND [PackedBy] IS NOT NULL));

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [CK_shipping_Shipment_94] CHECK ([Status] IN (N'OPEN',N'LOADING',N'CLOSED',N'CANCELLED'));

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [CK_shipping_Shipment_95] CHECK ((Status IN ('OPEN','LOADING') AND ClosedAtUtc IS NULL AND CancelledAtUtc IS NULL) OR (Status='CLOSED' AND ClosedAtUtc IS NOT NULL AND CancelledAtUtc IS NULL) OR (Status='CANCELLED' AND CancelledAtUtc IS NOT NULL AND ClosedAtUtc IS NULL));

ALTER TABLE [shipping].[Shipment] WITH CHECK ADD CONSTRAINT [CK_shipping_Shipment_96] CHECK ((ClosedAtUtc IS NULL OR ClosedAtUtc >= OpenedAtUtc) AND (CancelledAtUtc IS NULL OR CancelledAtUtc >= OpenedAtUtc));

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentUnit_97] CHECK ([Status] IN (N'ASSIGNED',N'LOADED',N'DISPATCHED',N'RELEASED'));

ALTER TABLE [shipping].[ShipmentUnit] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentUnit_98] CHECK ((Status='RELEASED' AND ReleasedAtUtc IS NOT NULL AND ReleasedAtUtc >= AssignedAtUtc) OR (Status <> 'RELEASED' AND ReleasedAtUtc IS NULL));

ALTER TABLE [shipping].[LoadEvent] WITH CHECK ADD CONSTRAINT [CK_shipping_LoadEvent_99] CHECK ([EventType] IN (N'LOAD',N'UNLOAD'));

ALTER TABLE [shipping].[ShipmentClosure] WITH CHECK ADD CONSTRAINT [CK_shipping_ShipmentClosure_100] CHECK (IsPartial = 0 OR PartialApprovalId IS NOT NULL);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [CK_quality_Incident_101] CHECK (CASE WHEN [ImportRunId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [OrderLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [TaskLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [HandlingUnitId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ShipmentId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [TripId] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [quality].[Incident] WITH CHECK ADD CONSTRAINT [CK_quality_Incident_102] CHECK ([Status] IN (N'OPEN',N'INVESTIGATING',N'RESOLVED',N'CANCELLED'));

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [CK_quality_Hold_103] CHECK (CASE WHEN [OrderLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [HandlingUnitId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ShipmentId] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [quality].[Hold] WITH CHECK ADD CONSTRAINT [CK_quality_Hold_104] CHECK ((ReleasedAtUtc IS NULL AND ReleasedBy IS NULL AND ReleaseReason IS NULL) OR (ReleasedAtUtc IS NOT NULL AND ReleasedBy IS NOT NULL AND ReleaseReason IS NOT NULL));

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_105] CHECK (CASE WHEN [OrderLineId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [HandlingUnitId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [ShipmentId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [TripId] IS NULL THEN 0 ELSE 1 END = 1);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_106] CHECK ([Decision] IN (N'PENDING',N'APPROVED',N'REJECTED',N'EXPIRED'));

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_107] CHECK (([DecidedBy] IS NULL AND [DecidedAtUtc] IS NULL) OR ([DecidedBy] IS NOT NULL AND [DecidedAtUtc] IS NOT NULL));

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_108] CHECK (Decision NOT IN ('APPROVED','REJECTED') OR DecidedBy IS NOT NULL);

ALTER TABLE [quality].[Approval] WITH CHECK ADD CONSTRAINT [CK_quality_Approval_109] CHECK (ExecutedOperationId IS NULL OR Decision='APPROVED');

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_110] CHECK ([StageCode] IN (N'PICKING',N'PACKING',N'LOADING'));

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_111] CHECK ([CapacityBasis] IN (N'BASE_QUANTITY',N'STANDARD_MINUTES'));

ALTER TABLE [planning].[CapacityPool] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityPool_112] CHECK ((CapacityBasis='BASE_QUANTITY' AND CapacityUnitId IS NOT NULL) OR (CapacityBasis='STANDARD_MINUTES' AND CapacityUnitId IS NULL));

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_113] CHECK ([Status] IN (N'OPEN',N'CLOSED'));

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_114] CHECK (BaseCapacity >= 0 AND ExtraCapacity >= 0 AND UnavailableCapacity >= 0 AND BaseCapacity + ExtraCapacity >= UnavailableCapacity);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_115] CHECK (([WindowStartUtc] IS NULL AND [WindowEndUtc] IS NULL) OR ([WindowStartUtc] IS NOT NULL AND [WindowEndUtc] IS NOT NULL));

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_116] CHECK (WindowEndUtc IS NULL OR WindowEndUtc > WindowStartUtc);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_117] CHECK (BaseCapacity + ExtraCapacity - UnavailableCapacity = 0 OR WindowStartUtc IS NOT NULL);

ALTER TABLE [planning].[CapacityDay] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityDay_118] CHECK ((Status='OPEN' AND ClosedAtUtc IS NULL) OR (Status='CLOSED' AND ClosedAtUtc IS NOT NULL));

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_119] CHECK ([Status] IN (N'DRAFT',N'COMMITTED',N'COMPLETED',N'CANCELLED'));

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_120] CHECK (ReleasedBaseQuantity >= 0 AND ReleasedBaseQuantity <= PlannedBaseQuantity);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_121] CHECK (([ApprovedBy] IS NULL AND [ApprovedAtUtc] IS NULL) OR ([ApprovedBy] IS NOT NULL AND [ApprovedAtUtc] IS NOT NULL));

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_122] CHECK (Status NOT IN ('COMMITTED','COMPLETED') OR ApprovedBy IS NOT NULL);

ALTER TABLE [planning].[CapacityBooking] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityBooking_123] CHECK (RescheduledFromId IS NULL OR RescheduledFromId <> Id);

ALTER TABLE [planning].[CapacityExecution] WITH CHECK ADD CONSTRAINT [CK_planning_CapacityExecution_124] CHECK ((PickConfirmationId IS NOT NULL AND HandlingUnitItemId IS NULL AND LoadEventId IS NULL) OR (PickConfirmationId IS NULL AND HandlingUnitItemId IS NOT NULL));
