-- Foreign keys use NO ACTION: historical records are never cascade-deleted.

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
