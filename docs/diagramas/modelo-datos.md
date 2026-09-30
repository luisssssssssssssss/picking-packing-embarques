# Diagramas de relaciones

Versión 0.2 · 27 de septiembre de 2026. Propuesta lógica, pendiente de validación del negocio. El [diccionario completo](../../database/schema/diccionario-tablas.md) contiene todos los campos, obligatoriedad y claves. En estos diagramas se muestran PK y FKs; los límites mínimos de participación (por ejemplo, pedido liberado con líneas) también requieren reglas transaccionales.

## Recorrido de cantidades

```mermaid
flowchart LR
 O[Pedido y sus revisiones] --> L[Líneas de pedido]
 L --> A[Asignaciones por almacén]
 A --> P[Detalle de Picking]
 P --> C[Confirmaciones]
 C --> R[Recepciones de Packing]
 R --> H[Contenido de HU]
 H --> U[Unidad de manejo]
 A --> TA[Cantidad por parada]
 T[Viaje y revisión] --> S[Paradas]
 S --> TA
 U --> SU[HU asignada al embarque]
 S --> SU
 SU --> E[Carga y cierre]
```

## security

```mermaid
erDiagram
    security_AppUser {
        bigint Id PK
    }
    security_Role {
        bigint Id PK
    }
    security_Permission {
        bigint Id PK
    }
    security_UserRole {
        bigint Id PK
    }
    security_RolePermission {
        bigint Id PK
    }
    security_UserWarehouse {
        bigint Id PK
        bigint WarehouseId FK
    }
    catalog_Warehouse {
        bigint Id PK
    }
    security_AppUser ||--o{ security_UserRole : "UserId"
    security_Role ||--o{ security_UserRole : "RoleId"
    security_Role ||--o{ security_RolePermission : "RoleId"
    security_Permission ||--o{ security_RolePermission : "PermissionId"
    security_AppUser ||--o{ security_UserWarehouse : "UserId"
    catalog_Warehouse ||--o{ security_UserWarehouse : "WarehouseId"
```

## platform

```mermaid
erDiagram
    platform_SchemaMigration {
        bigint Id PK
    }
    platform_OperationRequest {
        bigint Id PK
    }
    security_AppUser {
        bigint Id PK
    }
    security_AppUser ||--o{ platform_OperationRequest : "ActorUserId"
```

## catalog

```mermaid
erDiagram
    catalog_LogisticsPoint {
        bigint Id PK
    }
    catalog_PointAddress {
        bigint Id PK
        bigint PointId FK
    }
    catalog_Warehouse {
        bigint Id PK
        bigint PointId FK
    }
    catalog_Location {
        bigint Id PK
        bigint WarehouseId FK
        bigint ParentLocationId FK
    }
    catalog_Customer {
        bigint Id PK
    }
    catalog_DeliverySite {
        bigint Id PK
        bigint CustomerId FK
        bigint PointId FK
    }
    catalog_DeliveryWindow {
        bigint Id PK
        bigint DeliverySiteId FK
    }
    catalog_UnitOfMeasure {
        bigint Id PK
    }
    catalog_Material {
        bigint Id PK
        bigint BaseUnitId FK
    }
    catalog_MaterialUnitConversion {
        bigint Id PK
        bigint MaterialId FK
        bigint FromUnitId FK
    }
    catalog_MaterialIdentifier {
        bigint Id PK
        bigint MaterialId FK
        bigint UnitId FK
    }
    catalog_MaterialLot {
        bigint Id PK
        bigint MaterialId FK
    }
    catalog_MaterialLocation {
        bigint Id PK
        bigint MaterialId FK
        bigint LocationId FK
    }
    catalog_HandlingUnitType {
        bigint Id PK
    }
    catalog_LogisticsPoint ||--o{ catalog_PointAddress : "PointId"
    catalog_LogisticsPoint ||--o| catalog_Warehouse : "PointId"
    catalog_Warehouse ||--o{ catalog_Location : "WarehouseId"
    catalog_Location |o--o{ catalog_Location : "ParentLocationId"
    catalog_Customer ||--o{ catalog_DeliverySite : "CustomerId"
    catalog_LogisticsPoint ||--o| catalog_DeliverySite : "PointId"
    catalog_DeliverySite ||--o{ catalog_DeliveryWindow : "DeliverySiteId"
    catalog_UnitOfMeasure ||--o{ catalog_Material : "BaseUnitId"
    catalog_Material ||--o{ catalog_MaterialUnitConversion : "MaterialId"
    catalog_UnitOfMeasure ||--o{ catalog_MaterialUnitConversion : "FromUnitId"
    catalog_Material ||--o{ catalog_MaterialIdentifier : "MaterialId"
    catalog_UnitOfMeasure ||--o{ catalog_MaterialIdentifier : "UnitId"
    catalog_Material ||--o{ catalog_MaterialLot : "MaterialId"
    catalog_Material ||--o{ catalog_MaterialLocation : "MaterialId"
    catalog_Location ||--o{ catalog_MaterialLocation : "LocationId"
```

## integration

```mermaid
erDiagram
    integration_SourceSystem {
        bigint Id PK
    }
    integration_MappingProfileVersion {
        bigint Id PK
        bigint SourceSystemId FK
    }
    integration_MappingField {
        bigint Id PK
        bigint ProfileVersionId FK
    }
    integration_ImportedFile {
        bigint Id PK
        bigint SourceSystemId FK
    }
    integration_ImportRun {
        bigint Id PK
        bigint FileId FK
        bigint ProfileVersionId FK
    }
    integration_ImportOrderResult {
        bigint Id PK
        bigint RunId FK
        bigint OrderRevisionId FK
    }
    integration_ImportRow {
        bigint Id PK
        bigint RunId FK
        bigint OrderResultId FK
        bigint AppliedOrderLineId FK
    }
    integration_ImportError {
        bigint Id PK
        bigint RunId FK
        bigint RowId FK
    }
    operations_OrderRevision {
        bigint Id PK
    }
    operations_OrderLine {
        bigint Id PK
    }
    integration_SourceSystem ||--o{ integration_MappingProfileVersion : "SourceSystemId"
    integration_MappingProfileVersion ||--o{ integration_MappingField : "ProfileVersionId"
    integration_SourceSystem ||--o{ integration_ImportedFile : "SourceSystemId"
    integration_ImportedFile ||--o{ integration_ImportRun : "FileId"
    integration_MappingProfileVersion ||--o{ integration_ImportRun : "ProfileVersionId"
    integration_ImportRun ||--o{ integration_ImportOrderResult : "RunId"
    operations_OrderRevision |o--o{ integration_ImportOrderResult : "OrderRevisionId"
    integration_ImportRun ||--o{ integration_ImportRow : "RunId"
    integration_ImportOrderResult |o--o{ integration_ImportRow : "OrderResultId"
    operations_OrderLine |o--o{ integration_ImportRow : "AppliedOrderLineId"
    integration_ImportRun ||--o{ integration_ImportError : "RunId"
    integration_ImportRow |o--o{ integration_ImportError : "RowId"
```

## operations

```mermaid
erDiagram
    operations_SalesOrder {
        bigint Id PK
        bigint SourceSystemId FK
        bigint CustomerId FK
        bigint CurrentRevisionId FK
    }
    operations_OrderRevision {
        bigint Id PK
        bigint OrderId FK
    }
    operations_OrderLine {
        bigint Id PK
        bigint OrderId FK
    }
    operations_OrderLineRevision {
        bigint Id PK
        bigint OrderId FK
        bigint OrderRevisionId FK
        bigint OrderLineId FK
        bigint MaterialId FK
        bigint DeliverySiteId FK
        bigint RequestedUnitId FK
    }
    operations_FulfillmentAllocation {
        bigint Id PK
        bigint OrderLineId FK
        bigint OrderLineRevisionId FK
        bigint WarehouseId FK
    }
    integration_SourceSystem {
        bigint Id PK
    }
    catalog_Customer {
        bigint Id PK
    }
    catalog_Material {
        bigint Id PK
    }
    catalog_DeliverySite {
        bigint Id PK
    }
    catalog_UnitOfMeasure {
        bigint Id PK
    }
    catalog_Warehouse {
        bigint Id PK
    }
    integration_SourceSystem ||--o{ operations_SalesOrder : "SourceSystemId"
    catalog_Customer ||--o{ operations_SalesOrder : "CustomerId"
    operations_OrderRevision |o--o{ operations_SalesOrder : "CurrentRevisionId"
    operations_SalesOrder ||--o{ operations_OrderRevision : "OrderId"
    operations_SalesOrder ||--o{ operations_OrderLine : "OrderId"
    operations_SalesOrder ||--o{ operations_OrderLineRevision : "OrderId"
    operations_OrderRevision ||--o{ operations_OrderLineRevision : "OrderRevisionId"
    operations_OrderLine ||--o{ operations_OrderLineRevision : "OrderLineId"
    catalog_Material ||--o{ operations_OrderLineRevision : "MaterialId"
    catalog_DeliverySite ||--o{ operations_OrderLineRevision : "DeliverySiteId"
    catalog_UnitOfMeasure ||--o{ operations_OrderLineRevision : "RequestedUnitId"
    operations_OrderLine ||--o{ operations_FulfillmentAllocation : "OrderLineId"
    operations_OrderLineRevision ||--o{ operations_FulfillmentAllocation : "OrderLineRevisionId"
    catalog_Warehouse ||--o{ operations_FulfillmentAllocation : "WarehouseId"
```

## planning

```mermaid
erDiagram
    planning_DistanceReference {
        bigint Id PK
        bigint OriginAddressId FK
        bigint DestinationAddressId FK
    }
    planning_Carrier {
        bigint Id PK
    }
    planning_Trailer {
        bigint Id PK
        bigint CarrierId FK
    }
    planning_Driver {
        bigint Id PK
        bigint CarrierId FK
    }
    planning_Trip {
        bigint Id PK
        bigint OriginWarehouseId FK
        bigint CurrentRevisionId FK
    }
    planning_TripRevision {
        bigint Id PK
        bigint TripId FK
        bigint OriginAddressId FK
        bigint PlannedTrailerId FK
        bigint PlannedDriverId FK
    }
    planning_TripStop {
        bigint Id PK
        bigint TripRevisionId FK
        bigint DeliverySiteId FK
        bigint AddressVersionId FK
        bigint DistanceFromPreviousId FK
    }
    planning_TripAllocation {
        bigint Id PK
        bigint StopId FK
        bigint AllocationId FK
    }
    catalog_PointAddress {
        bigint Id PK
    }
    catalog_Warehouse {
        bigint Id PK
    }
    catalog_DeliverySite {
        bigint Id PK
    }
    operations_FulfillmentAllocation {
        bigint Id PK
    }
    catalog_PointAddress ||--o{ planning_DistanceReference : "OriginAddressId"
    catalog_PointAddress ||--o{ planning_DistanceReference : "DestinationAddressId"
    planning_Carrier |o--o{ planning_Trailer : "CarrierId"
    planning_Carrier |o--o{ planning_Driver : "CarrierId"
    catalog_Warehouse ||--o{ planning_Trip : "OriginWarehouseId"
    planning_TripRevision |o--o{ planning_Trip : "CurrentRevisionId"
    planning_Trip ||--o{ planning_TripRevision : "TripId"
    catalog_PointAddress ||--o{ planning_TripRevision : "OriginAddressId"
    planning_Trailer |o--o{ planning_TripRevision : "PlannedTrailerId"
    planning_Driver |o--o{ planning_TripRevision : "PlannedDriverId"
    planning_TripRevision ||--o{ planning_TripStop : "TripRevisionId"
    catalog_DeliverySite ||--o{ planning_TripStop : "DeliverySiteId"
    catalog_PointAddress ||--o{ planning_TripStop : "AddressVersionId"
    planning_DistanceReference |o--o{ planning_TripStop : "DistanceFromPreviousId"
    planning_TripStop ||--o{ planning_TripAllocation : "StopId"
    operations_FulfillmentAllocation ||--o{ planning_TripAllocation : "AllocationId"
```

## warehouse

```mermaid
erDiagram
    warehouse_PickingTask {
        bigint Id PK
        bigint WarehouseId FK
    }
    warehouse_PickingTaskLine {
        bigint Id PK
        bigint TaskId FK
        bigint AllocationId FK
        bigint SourceLocationId FK
        bigint LotId FK
    }
    warehouse_PickConfirmation {
        bigint Id PK
        bigint TaskLineId FK
    }
    warehouse_PickReversal {
        bigint Id PK
        bigint PickConfirmationId FK
    }
    warehouse_PackingReceipt {
        bigint Id PK
        bigint PickConfirmationId FK
        bigint PackingLocationId FK
    }
    warehouse_ReceiptReversal {
        bigint Id PK
        bigint ReceiptId FK
    }
    warehouse_HandlingUnit {
        bigint Id PK
        bigint TypeId FK
        bigint WarehouseId FK
        bigint DeliverySiteId FK
        bigint CurrentLocationId FK
    }
    warehouse_HandlingUnitItem {
        bigint Id PK
        bigint HandlingUnitId FK
        bigint ReceiptId FK
    }
    warehouse_PackingReversal {
        bigint Id PK
        bigint HandlingUnitItemId FK
    }
    warehouse_HandlingUnitMovement {
        bigint Id PK
        bigint HandlingUnitId FK
        bigint FromLocationId FK
        bigint ToLocationId FK
    }
    catalog_Warehouse {
        bigint Id PK
    }
    operations_FulfillmentAllocation {
        bigint Id PK
    }
    catalog_Location {
        bigint Id PK
    }
    catalog_MaterialLot {
        bigint Id PK
    }
    catalog_HandlingUnitType {
        bigint Id PK
    }
    catalog_DeliverySite {
        bigint Id PK
    }
    catalog_Warehouse ||--o{ warehouse_PickingTask : "WarehouseId"
    warehouse_PickingTask ||--o{ warehouse_PickingTaskLine : "TaskId"
    operations_FulfillmentAllocation ||--o{ warehouse_PickingTaskLine : "AllocationId"
    catalog_Location ||--o{ warehouse_PickingTaskLine : "SourceLocationId"
    catalog_MaterialLot |o--o{ warehouse_PickingTaskLine : "LotId"
    warehouse_PickingTaskLine ||--o{ warehouse_PickConfirmation : "TaskLineId"
    warehouse_PickConfirmation ||--o| warehouse_PickReversal : "PickConfirmationId"
    warehouse_PickConfirmation ||--o{ warehouse_PackingReceipt : "PickConfirmationId"
    catalog_Location ||--o{ warehouse_PackingReceipt : "PackingLocationId"
    warehouse_PackingReceipt ||--o| warehouse_ReceiptReversal : "ReceiptId"
    catalog_HandlingUnitType ||--o{ warehouse_HandlingUnit : "TypeId"
    catalog_Warehouse ||--o{ warehouse_HandlingUnit : "WarehouseId"
    catalog_DeliverySite ||--o{ warehouse_HandlingUnit : "DeliverySiteId"
    catalog_Location |o--o{ warehouse_HandlingUnit : "CurrentLocationId"
    warehouse_HandlingUnit ||--o{ warehouse_HandlingUnitItem : "HandlingUnitId"
    warehouse_PackingReceipt ||--o{ warehouse_HandlingUnitItem : "ReceiptId"
    warehouse_HandlingUnitItem ||--o| warehouse_PackingReversal : "HandlingUnitItemId"
    warehouse_HandlingUnit ||--o{ warehouse_HandlingUnitMovement : "HandlingUnitId"
    catalog_Location |o--o{ warehouse_HandlingUnitMovement : "FromLocationId"
    catalog_Location ||--o{ warehouse_HandlingUnitMovement : "ToLocationId"
```

## shipping

```mermaid
erDiagram
    shipping_Shipment {
        bigint Id PK
        bigint TripId FK
        bigint TripRevisionId FK
        bigint TrailerId FK
        bigint DriverId FK
        bigint DockLocationId FK
    }
    shipping_ShipmentUnit {
        bigint Id PK
        bigint ShipmentId FK
        bigint TripRevisionId FK
        bigint StopId FK
        bigint HandlingUnitId FK
    }
    shipping_LoadEvent {
        bigint Id PK
        bigint ShipmentUnitId FK
        bigint WarehouseLocationId FK
    }
    shipping_ShipmentClosure {
        bigint Id PK
        bigint ShipmentId FK
        bigint PartialApprovalId FK
    }
    planning_Trip {
        bigint Id PK
    }
    planning_TripRevision {
        bigint Id PK
    }
    planning_Trailer {
        bigint Id PK
    }
    planning_Driver {
        bigint Id PK
    }
    catalog_Location {
        bigint Id PK
    }
    planning_TripStop {
        bigint Id PK
    }
    warehouse_HandlingUnit {
        bigint Id PK
    }
    quality_Approval {
        bigint Id PK
    }
    planning_Trip ||--o| shipping_Shipment : "TripId"
    planning_TripRevision ||--o{ shipping_Shipment : "TripRevisionId"
    planning_Trailer ||--o{ shipping_Shipment : "TrailerId"
    planning_Driver |o--o{ shipping_Shipment : "DriverId"
    catalog_Location |o--o{ shipping_Shipment : "DockLocationId"
    shipping_Shipment ||--o{ shipping_ShipmentUnit : "ShipmentId"
    planning_TripRevision ||--o{ shipping_ShipmentUnit : "TripRevisionId"
    planning_TripStop ||--o{ shipping_ShipmentUnit : "StopId"
    warehouse_HandlingUnit ||--o{ shipping_ShipmentUnit : "HandlingUnitId"
    shipping_ShipmentUnit ||--o{ shipping_LoadEvent : "ShipmentUnitId"
    catalog_Location ||--o{ shipping_LoadEvent : "WarehouseLocationId"
    shipping_Shipment ||--o| shipping_ShipmentClosure : "ShipmentId"
    quality_Approval |o--o{ shipping_ShipmentClosure : "PartialApprovalId"
```

## quality

```mermaid
erDiagram
    quality_IncidentType {
        bigint Id PK
    }
    quality_Incident {
        bigint Id PK
        bigint TypeId FK
        bigint ImportRunId FK
        bigint OrderLineId FK
        bigint TaskLineId FK
        bigint HandlingUnitId FK
        bigint ShipmentId FK
        bigint TripId FK
    }
    quality_IncidentAction {
        bigint Id PK
        bigint IncidentId FK
    }
    quality_Hold {
        bigint Id PK
        bigint OrderLineId FK
        bigint HandlingUnitId FK
        bigint ShipmentId FK
        bigint IncidentId FK
    }
    quality_Approval {
        bigint Id PK
        bigint IncidentId FK
        bigint OrderLineId FK
        bigint HandlingUnitId FK
        bigint ShipmentId FK
        bigint TripId FK
    }
    integration_ImportRun {
        bigint Id PK
    }
    operations_OrderLine {
        bigint Id PK
    }
    warehouse_PickingTaskLine {
        bigint Id PK
    }
    warehouse_HandlingUnit {
        bigint Id PK
    }
    shipping_Shipment {
        bigint Id PK
    }
    planning_Trip {
        bigint Id PK
    }
    quality_IncidentType ||--o{ quality_Incident : "TypeId"
    integration_ImportRun |o--o{ quality_Incident : "ImportRunId"
    operations_OrderLine |o--o{ quality_Incident : "OrderLineId"
    warehouse_PickingTaskLine |o--o{ quality_Incident : "TaskLineId"
    warehouse_HandlingUnit |o--o{ quality_Incident : "HandlingUnitId"
    shipping_Shipment |o--o{ quality_Incident : "ShipmentId"
    planning_Trip |o--o{ quality_Incident : "TripId"
    quality_Incident ||--o{ quality_IncidentAction : "IncidentId"
    operations_OrderLine |o--o{ quality_Hold : "OrderLineId"
    warehouse_HandlingUnit |o--o{ quality_Hold : "HandlingUnitId"
    shipping_Shipment |o--o{ quality_Hold : "ShipmentId"
    quality_Incident |o--o{ quality_Hold : "IncidentId"
    quality_Incident |o--o{ quality_Approval : "IncidentId"
    operations_OrderLine |o--o{ quality_Approval : "OrderLineId"
    warehouse_HandlingUnit |o--o{ quality_Approval : "HandlingUnitId"
    shipping_Shipment |o--o{ quality_Approval : "ShipmentId"
    planning_Trip |o--o{ quality_Approval : "TripId"
```

## audit

```mermaid
erDiagram
    audit_AuditEvent {
        bigint Id PK
    }

```

Las relaciones a usuarios y comandos se omiten en módulos operativos para facilitar la lectura; están completas en DBML y en el diccionario. La cardinalidad muchos del gráfico permite historia; las claves únicas y filtros del diccionario restringen relaciones específicas a uno vigente.


Actualización 0.2: las tablas de capacidad diaria complementan este diseño; consultar [capacidad diaria](../../database/schema/capacidad-diaria.md). La implementación inicial SQL está en database/migrations; las reglas agregadas de operación siguen pendientes en el backend.


## Capacidad diaria — ampliación 0.2

```mermaid
erDiagram
    Warehouse ||--o{ CapacityPool : dispone
    CapacityPool ||--o{ CapacityDay : calendario
    CapacityPool ||--o{ WorkStandardVersion : estandares
    Material ||--o{ WorkStandardVersion : consumo
    FulfillmentAllocation ||--o{ CapacityBooking : reserva
    CapacityDay ||--o{ CapacityBooking : planifica
    WorkStandardVersion ||--o{ CapacityBooking : cuantifica
    CapacityBooking o|--o{ CapacityBooking : reprogramacion
    CapacityBooking ||--o{ CapacityExecution : evidencia
    CapacityDay ||--o{ CapacityExecution : fecha_real
    PickConfirmation o|--o{ CapacityExecution : picking
    HandlingUnitItem o|--o{ CapacityExecution : packing_o_carga
    LoadEvent o|--o{ CapacityExecution : carga
    CapacityPool {
        bigint Id PK
        bigint WarehouseId FK
        nvarchar StageCode
        nvarchar CapacityBasis
    }
    CapacityDay {
        bigint Id PK
        bigint PoolId FK
        date WorkDate
        decimal BaseCapacity
        decimal ExtraCapacity
        decimal UnavailableCapacity
    }
    WorkStandardVersion {
        bigint Id PK
        bigint PoolId FK
        bigint MaterialId FK
        decimal CapacityPerBaseUnit
    }
    CapacityBooking {
        bigint Id PK
        bigint AllocationId FK
        bigint PoolId FK
        bigint CapacityDayId FK
        bigint WorkStandardVersionId FK
        bigint RescheduledFromId FK
        decimal PlannedBaseQuantity
        decimal ReleasedBaseQuantity
    }
    CapacityExecution {
        bigint Id PK
        bigint BookingId FK
        bigint PoolId FK
        bigint ActualCapacityDayId FK
        bigint PickConfirmationId FK
        bigint HandlingUnitItemId FK
        bigint LoadEventId FK
        decimal BaseQuantity
    }
```

Las relaciones compuestas conservan el mismo PoolId en día, estándar, reserva y ejecución.
En ejecución se exige picking solo, contenido de HU solo, o contenido de HU junto con evento de carga.
