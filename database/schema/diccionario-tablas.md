# Diccionario de tablas y campos

Versión 0.2 · 27 de septiembre de 2026 · Propuesta sin SQL ejecutado.

Leer junto con [reglas e integridad](esquema-logico.md), [diagramas](../../docs/diagramas/modelo-datos.md) y [DBML](modelo-logico.dbml).

**68 tablas para el flujo completo, por entregas.** La entrega de una tabla indica su primer subconjunto; columnas con FK a módulos posteriores se agregan al implementar esos módulos. El modelo completo no se instala en la primera migración.

PK: clave primaria. FK: referencia. UQ: unicidad. NULL: dato no disponible/no aplicable cuando esté permitido. Id bigint estable autogenerada. Códigos externos en texto. Tipos y longitudes propuestos, pendientes de contrastar con el archivo real.

CreatedAtUtc común; UpdatedAtUtc y RowVersion en editables. Hechos históricos solo se anexan. Excepción: ImportRow completa su procesamiento bajo control de ImportRun, sin cambiar RawText. No hay borrado en cascada.

## security

### security.AppUser — Usuarios

Identidad de la aplicación, independiente del login de SQL Server.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Login | nvarchar(64) | No | — | — |
| DisplayName | nvarchar(240) | No | — | — |
| PasswordHash | nvarchar(512) | No | — | — |
| IsActive | bit | No | — | — |
| LockedUntilUtc | datetime2(3) | Sí | — | — |
| FailedLoginCount | int | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Login).

Reglas:

- Login normalizado y único; no reutilizar identidades de usuarios dados de baja.
- PasswordHash incluye algoritmo, sal y parámetros; nunca contraseña reversible. JWT y secretos de firma no se guardan aquí.

### security.Role — Roles

Agrupa capacidades sin programar permisos por nombre de persona.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

### security.Permission — Permisos

Operaciones autorizables, por ejemplo liberar planeación o cerrar embarque.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Description | nvarchar(240) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

### security.UserRole — Roles de usuario

Relación muchos a muchos.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| UserId | bigint | No | FK → security.AppUser.Id | — |
| RoleId | bigint | No | FK → security.Role.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (UserId, RoleId).

### security.RolePermission — Permisos de rol

Relación muchos a muchos.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| RoleId | bigint | No | FK → security.Role.Id | — |
| PermissionId | bigint | No | FK → security.Permission.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (RoleId, PermissionId).

### security.UserWarehouse — Acceso por almacén

Limita el ámbito operativo incluso si el rol permite la acción.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| UserId | bigint | No | FK → security.AppUser.Id | — |
| WarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (UserId, WarehouseId).

Reglas:

- Ausencia de asignación no significa acceso global. El acceso global debe ser un permiso explícito.

## platform

### platform.SchemaMigration — Versiones de esquema

Registro de migraciones aplicadas; no guarda credenciales ni ejecuta cambios por sí sola.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ApplicationCode | nvarchar(64) | No | — | Identificador fijo PickingPackingEmbarques; comprobar antes de modificar una instalación. |
| Version | nvarchar(64) | No | — | — |
| ScriptChecksum | binary(32) | No | — | — |
| AppliedAtUtc | datetime2(3) | No | — | — |
| ApplicationVersion | nvarchar(64) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (Version).

Reglas:

- Solo registrar como aplicada al completarse correctamente; discrepancia de checksum requiere revisión.
- La instalación debe reconocer la identidad de esta aplicación antes de modificar una base existente.
- CHECK ApplicationCode = PickingPackingEmbarques; una tabla con ese nombre no basta para reconocer otra aplicación.

### platform.OperationRequest — Comandos e idempotencia

Identifica confirmaciones y reintentos; comparte transacción con el cambio operativo y su auditoría.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| IdempotencyKey | uniqueidentifier | No | — | — |
| OperationCode | nvarchar(64) | No | — | — |
| RequestHash | binary(32) | No | — | — |
| Outcome | nvarchar(64) | No | — | SUCCEEDED o REJECTED |
| ResponseCode | int | No | — | — |
| ResultJson | nvarchar(max) | Sí | — | Resultado mínimo sin secretos |
| CompletedAtUtc | datetime2(3) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (ActorUserId, IdempotencyKey).

Reglas:

- Una misma clave con contenido distinto se rechaza.
- Se confirma registro, resultado y operación en una sola transacción; no dejar un IN_PROGRESS durable sin protocolo de recuperación.
- No purgar claves mientras se admitan reintentos de sus operaciones; definir retención antes del piloto.

## catalog

### catalog.LogisticsPoint — Puntos logísticos

Identidad de un origen o destino geográfico, independiente de cambios de dirección.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| PointType | nvarchar(64) | No | — | WAREHOUSE o DELIVERY_SITE |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- Cada punto se asocia con exactamente un almacén o destino y un tipo coherente; validar al darlo de alta.

### catalog.PointAddress — Versiones de dirección

Dirección y coordenadas inmutables para preservar rutas históricas.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| PointId | bigint | No | FK → catalog.LogisticsPoint.Id | — |
| VersionNumber | int | No | — | — |
| AddressText | nvarchar(1000) | No | — | — |
| City | nvarchar(240) | No | — | — |
| Region | nvarchar(240) | Sí | — | — |
| PostalCode | nvarchar(64) | Sí | — | — |
| CountryCode | nvarchar(2) | No | — | — |
| Latitude | decimal(9,6) | Sí | — | — |
| Longitude | decimal(9,6) | Sí | — | — |
| TimeZoneId | nvarchar(240) | No | — | — |
| ValidFromUtc | datetime2(3) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (PointId, VersionNumber); (Id, PointId).

Reglas:

- Latitud entre -90 y 90; longitud entre -180 y 180; ambas informadas o ambas nulas.
- La dirección vigente es la última versión efectiva por punto. Cambiar dirección crea otra versión, sin editar la anterior.

### catalog.Warehouse — Almacenes

Almacén de origen; la ubicación interna se maneja en Location.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| PointId | bigint | No | FK → catalog.LogisticsPoint.Id | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code); (PointId).

### catalog.Location — Ubicaciones internas

Jerarquía simple de zonas, pasillos, posiciones, packing, preembarque y andenes.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| WarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| ParentLocationId | bigint | Sí | FK → catalog.Location.Id | — |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| LocationType | nvarchar(64) | No | — | ZONE, AISLE, BIN, PACKING, STAGING, DOCK |
| AllowsPicking | bit | No | — | — |
| AllowsStorage | bit | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (WarehouseId, Code); (Id, WarehouseId).

Reglas:

- Padre del mismo almacén, sin ciclos y distinto de sí mismo.
- Andén se modela como Location tipo DOCK; no duplicar Dock y Location.
- Una ubicación con operaciones abiertas no puede desactivarse o moverse de almacén.

### catalog.Customer — Clientes

Cliente comercial; puede tener múltiples puntos de entrega.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

### catalog.DeliverySite — Destinos del cliente

Identifica una planta o sucursal concreta, no solo el nombre del cliente.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| CustomerId | bigint | No | FK → catalog.Customer.Id | — |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| PointId | bigint | No | FK → catalog.LogisticsPoint.Id | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (CustomerId, Code); (PointId); (Id, CustomerId).

### catalog.DeliveryWindow — Horarios de recepción

Ventanas semanales de referencia; la cita concreta se guarda en la parada.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| DeliverySiteId | bigint | No | FK → catalog.DeliverySite.Id | — |
| WeekDay | int | No | — | 1 a 7, lunes a domingo |
| StartLocal | time(0) | No | — | — |
| EndLocal | time(0) | No | — | — |
| ValidFrom | date | No | — | — |
| ValidTo | date | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (DeliverySiteId, WeekDay, StartLocal, ValidFrom).

Reglas:

- EndLocal > StartLocal. Horarios que cruzan medianoche se dividen en dos registros.
- Sin solapamientos de ventanas equivalentes durante su vigencia; festivos especiales quedan para extensión.

### catalog.UnitOfMeasure — Unidades de medida

No confundir PZA, KG, caja o tarima.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| QuantityScale | int | No | — | 0 a 6 decimales permitidos |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

### catalog.Material — Productos o materiales

Código estable y unidad base usada para conservar cantidades.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Description | nvarchar(240) | No | — | — |
| BaseUnitId | bigint | No | FK → catalog.UnitOfMeasure.Id | — |
| RequiresLot | bit | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- La unidad base no cambia cuando existe historia operativa; requiere migración de datos o material nuevo.
- RequiresLot es propuesta de catálogo a confirmar con el negocio; no implica FEFO automático.

### catalog.MaterialUnitConversion — Conversiones por producto

Una caja no contiene necesariamente la misma cantidad para todos los materiales.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| MaterialId | bigint | No | FK → catalog.Material.Id | — |
| FromUnitId | bigint | No | FK → catalog.UnitOfMeasure.Id | — |
| FactorToBase | decimal(28,12) | No | — | — |
| VersionNumber | int | No | — | — |
| ValidFromUtc | datetime2(3) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (MaterialId, FromUnitId, VersionNumber).

Reglas:

- Factor > 0; convertir siempre a la unidad base del material, sin cadenas ambiguas.
- La revisión de pedido conserva el factor usado. No recalcular historia con factores posteriores.
- Unidad base equivale a factor 1. No redondear silenciosamente fracciones inválidas.

### catalog.MaterialIdentifier — Códigos alternos de material

Permite códigos de barras u otros identificadores sin depender del dispositivo.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| MaterialId | bigint | No | FK → catalog.Material.Id | — |
| UnitId | bigint | No | FK → catalog.UnitOfMeasure.Id | — |
| Scheme | nvarchar(64) | No | — | — |
| Value | nvarchar(128) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Scheme, Value).

Reglas:

- No reutilizar un identificador para otro material; la captura manual sigue siendo válida.

### catalog.MaterialLot — Lotes

Un lote pertenece a un material. No se crea un lote ficticio para representar ausencia.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| MaterialId | bigint | No | FK → catalog.Material.Id | — |
| LotCode | nvarchar(64) | No | — | — |
| ManufacturedOn | date | Sí | — | — |
| ExpiresOn | date | Sí | — | — |
| IsBlocked | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (MaterialId, LotCode); (Id, MaterialId).

Reglas:

- Fecha de caducidad no anterior a fabricación, cuando ambas existen.
- La unicidad de lote por material debe confirmarse con el cliente; si cambia por fabricante, agregar ese ámbito antes de implementar.

### catalog.MaterialLocation — Ubicaciones permitidas o habituales

Relación muchos a muchos; NO representa existencias ni reservas.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| MaterialId | bigint | No | FK → catalog.Material.Id | — |
| LocationId | bigint | No | FK → catalog.Location.Id | — |
| IsPreferred | bit | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (MaterialId, LocationId).

Reglas:

- Permitir varias ubicaciones para un material y varios materiales por ubicación.
- Elegir ubicación preferente no garantiza que exista cantidad física.

### catalog.HandlingUnitType — Tipos de unidad de manejo

Por ejemplo caja o tarima; sin cálculo de estiba o volumetría.

Entrega 3. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

## integration

### integration.SourceSystem — Ámbito de datos de origen

Identifica la exportación, incluyendo sociedad/planta si son parte de la clave SAP. No es conexión a SAP.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Description | nvarchar(240) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- Dos pedidos con igual número de distintos ámbitos de origen no se mezclan.

### integration.MappingProfileVersion — Versiones de mapeo

Formato explícito e inmutable del CSV/TXT recibido.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| SourceSystemId | bigint | No | FK → integration.SourceSystem.Id | — |
| ProfileCode | nvarchar(64) | No | — | — |
| VersionNumber | int | No | — | — |
| Delimiter | nvarchar(8) | No | — | — |
| EncodingName | nvarchar(64) | No | — | — |
| HasHeader | bit | No | — | — |
| DateFormat | nvarchar(64) | No | — | — |
| DecimalSeparator | nvarchar(1) | No | — | — |
| SourceTimeZone | nvarchar(240) | No | — | — |
| Mode | nvarchar(64) | No | — | ORDER_SNAPSHOT inicial |
| DefinitionHash | binary(32) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (SourceSystemId, ProfileCode, VersionNumber).

Reglas:

- No adivinar fechas o separadores ambiguos.
- Propuesta inicial: archivo contiene pedidos completos; fragmentos/deltas requieren contrato explícito.
- Editar un mapeo genera una nueva versión.

### integration.MappingField — Correspondencia de columnas

Una columna o constante de origen alimenta un campo interno permitido.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ProfileVersionId | bigint | No | FK → integration.MappingProfileVersion.Id | — |
| TargetField | nvarchar(64) | No | — | — |
| SourceColumnName | nvarchar(240) | Sí | — | — |
| SourceColumnIndex | int | Sí | — | — |
| ConstantValue | nvarchar(240) | Sí | — | — |
| IsRequired | bit | No | — | — |
| TransformCode | nvarchar(64) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (ProfileVersionId, TargetField).

Reglas:

- Exactamente uno entre nombre, índice o constante. Índices positivos.
- Transformaciones de lista permitida; nunca ejecutar expresiones arbitrarias del archivo.

### integration.ImportedFile — Archivos originales

Contenido original inmutable y huella de bytes; nombre del archivo no es su identidad.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| SourceSystemId | bigint | No | FK → integration.SourceSystem.Id | — |
| ContentHash | binary(32) | No | — | — |
| ByteLength | bigint | No | — | — |
| OriginalFileName | nvarchar(240) | No | — | — |
| StorageKey | nvarchar(240) | No | — | Referencia controlada al archivo, no ruta proporcionada por el usuario |
| UploadedBy | bigint | No | FK → security.AppUser.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (SourceSystemId, ContentHash).

Reglas:

- Conservar bytes originales y hash; ruta física bajo control del backend.
- Tamaño > 0 y límites configurados antes de leer; archivos vacíos se rechazan y auditan sin importar.
- Respaldar también los archivos externos; restaurar solo SQL no los recupera.

### integration.ImportRun — Intentos de procesamiento

Registra cada intento, incluso si ya se recibió el mismo archivo.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| FileId | bigint | No | FK → integration.ImportedFile.Id | — |
| ProfileVersionId | bigint | No | FK → integration.MappingProfileVersion.Id | — |
| AttemptNumber | int | No | — | — |
| RequestedBy | bigint | No | FK → security.AppUser.Id | — |
| Status | nvarchar(64) | No | — | — |
| StartedAtUtc | datetime2(3) | Sí | — | — |
| FinishedAtUtc | datetime2(3) | Sí | — | — |
| LeaseToken | uniqueidentifier | Sí | — | — |
| LeaseExpiresAtUtc | datetime2(3) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (FileId, AttemptNumber); (Id, FileId).

Reglas:

- Perfil y archivo pertenecen al mismo SourceSystem.
- No aplicar dos intentos simultáneos sobre el mismo archivo. Lease con token de cercado para recuperar trabajos interrumpidos.
- Estados RECEIVED, PROCESSING, COMPLETED, PARTIAL, FAILED, DUPLICATE; DUPLICATE no vuelve a escribir pedidos.

### integration.ImportOrderResult — Resultado por pedido del archivo

Unidad atómica propuesta: aceptar todas las líneas de un pedido o rechazar ese pedido completo.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| RunId | bigint | No | FK → integration.ImportRun.Id | — |
| ExternalOrderNumber | nvarchar(64) | No | — | — |
| Status | nvarchar(64) | No | — | PENDING, APPLIED, REJECTED, UNCHANGED |
| OrderRevisionId | bigint | Sí | FK → operations.OrderRevision.Id | — |
| MessageCode | nvarchar(64) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (RunId, ExternalOrderNumber); (Id, RunId).

Reglas:

- APPLIED exige revisión vinculada. UNCHANGED referencia la revisión equivalente sin crear otra.
- Resultados y revisión operativa se confirman en la misma transacción; no perder el vínculo tras una caída.

### integration.ImportRow — Filas de staging

Preserva texto y valores interpretados, incluida la línea física de origen.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| RunId | bigint | No | FK → integration.ImportRun.Id | — |
| OrderResultId | bigint | Sí | FK → integration.ImportOrderResult.Id | — |
| RecordNumber | int | No | — | — |
| PhysicalLineStart | int | No | — | — |
| PhysicalLineEnd | int | No | — | — |
| RawText | nvarchar(max) | No | — | — |
| ParsedJson | nvarchar(max) | Sí | — | — |
| Status | nvarchar(64) | No | — | — |
| AppliedOrderLineId | bigint | Sí | FK → operations.OrderLine.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (RunId, RecordNumber); (Id, RunId).

Reglas:

- Conservar ceros iniciales en códigos. CSV entrecomillado puede ocupar varias líneas físicas.
- No usar número de fila como identidad de la línea del pedido.
- OrderResult debe pertenecer al mismo Run; AppliedOrderLine solo se informa al aplicar el pedido.

### integration.ImportError — Errores y advertencias

Puede haber varios errores por fila o errores generales del archivo.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| RunId | bigint | No | FK → integration.ImportRun.Id | — |
| RowId | bigint | Sí | FK → integration.ImportRow.Id | — |
| FieldName | nvarchar(64) | Sí | — | — |
| Severity | nvarchar(64) | No | — | ERROR o WARNING |
| ErrorCode | nvarchar(64) | No | — | — |
| Message | nvarchar(1000) | No | — | — |
| RawValue | nvarchar(240) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- La fila, cuando exista, debe pertenecer al mismo intento.
- Los valores se limitan y sanitizan; no exponer rutas internas o credenciales.

## operations

### operations.SalesOrder — Pedidos

Identidad permanente del pedido; sus requisitos se versionan.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| SourceSystemId | bigint | No | FK → integration.SourceSystem.Id | — |
| ExternalOrderNumber | nvarchar(64) | No | — | — |
| CustomerId | bigint | No | FK → catalog.Customer.Id | — |
| CurrentRevisionId | bigint | Sí | FK → operations.OrderRevision.Id | — |
| Status | nvarchar(64) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (SourceSystemId, ExternalOrderNumber).

Reglas:

- CurrentRevisionId debe ser revisión del mismo pedido mediante FK compuesta.
- Crear encabezado y revisión en una transacción; no publicar un pedido sin revisión vigente.
- Cliente inmutable tras liberar operaciones; el estado resumido no sustituye el avance por línea.

### operations.OrderRevision — Revisiones del pedido

Instantánea aceptada de los requisitos. Una importación no modifica silenciosamente lo que ya se está ejecutando.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OrderId | bigint | No | FK → operations.SalesOrder.Id | — |
| RevisionNumber | int | No | — | — |
| BusinessContentHash | binary(32) | No | — | — |
| ExternalRevision | nvarchar(64) | Sí | — | — |
| SourceAsOfUtc | datetime2(3) | Sí | — | — |
| ChangeReason | nvarchar(1000) | No | — | — |
| AcceptedBy | bigint | No | FK → security.AppUser.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (OrderId, RevisionNumber); (Id, OrderId).

Reglas:

- Hash de datos normalizados incluye líneas ordenadas, cantidades, destinos y fechas, no metadatos de carga.
- Si el origen no identifica su versión o fecha, un cambio no se acepta automáticamente solo por haber llegado después.
- Revisiones aceptadas inmutables. Hash igual a la revisión vigente implica UNCHANGED. Contenido igual a una revisión antigua requiere revisión manual, no retroceder automáticamente.

### operations.OrderLine — Identidad de línea de pedido

Distingue dos líneas del mismo producto. La clave externa no depende del material ni del orden de las filas.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OrderId | bigint | No | FK → operations.SalesOrder.Id | — |
| ExternalLineKey | nvarchar(128) | No | — | Incluye sublínea de origen si existe |
| IsClosed | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (OrderId, ExternalLineKey); (Id, OrderId).

Reglas:

- No asumir que material o lote identifica una línea.
- Una línea omitida en el archivo no se cancela automáticamente; exige semántica de snapshot y autorización.
- Publicar otra revisión o cambiar compromisos modifica también RowVersion de la línea; los servicios deben bloquear el agregado para mantener coherencia.

### operations.OrderLineRevision — Requisitos versionados por línea

Demanda comercial y destino concretos; distintas líneas pueden tener diferentes destinos.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OrderId | bigint | No | FK → operations.SalesOrder.Id | — |
| OrderRevisionId | bigint | No | FK → operations.OrderRevision.Id | — |
| OrderLineId | bigint | No | FK → operations.OrderLine.Id | — |
| MaterialId | bigint | No | FK → catalog.Material.Id | — |
| DeliverySiteId | bigint | No | FK → catalog.DeliverySite.Id | — |
| RequestedUnitId | bigint | No | FK → catalog.UnitOfMeasure.Id | — |
| RequestedQuantity | decimal(19,6) | No | — | — |
| FactorToBase | decimal(28,12) | No | — | — |
| RequiredBaseQuantity | decimal(19,6) | No | — | — |
| RequestedDate | date | No | — | — |
| Priority | int | No | — | — |
| IsCancelled | bit | No | — | — |
| MaterialCodeSnapshot | nvarchar(64) | No | — | — |
| MaterialDescriptionSnapshot | nvarchar(240) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (OrderRevisionId, OrderLineId); (Id, OrderLineId).

Reglas:

- Pedido de revisión y línea debe coincidir mediante FKs compuestas usando OrderId.
- Destino pertenece al cliente del pedido. Cantidades > 0; cancelación es explícita, no cantidad negativa.
- RequiredBaseQuantity = RequestedQuantity × FactorToBase, representable en la escala permitida.
- Material, destino y unidad base no cambian si existe ejecución. Una sustitución exige otra línea y tratamiento autorizado del pendiente.
- Para cambiar material o destino sin ejecución, primero cancelar todos los compromisos y tareas previos no ejecutados. Una revisión no redirige tareas existentes de forma implícita.

### operations.FulfillmentAllocation — Asignaciones de surtido

Divide la demanda entre almacenes. Es compromiso de surtido; los viajes se asignan por separado en TripAllocation. No equivale a reserva física.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OrderLineId | bigint | No | FK → operations.OrderLine.Id | — |
| OrderLineRevisionId | bigint | No | FK → operations.OrderLineRevision.Id | — |
| WarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| AllocatedBaseQuantity | decimal(19,6) | No | — | — |
| Status | nvarchar(64) | No | — | DRAFT, RELEASED, IN_PROGRESS, COMPLETED, CANCELLED |
| ReleasedAtUtc | datetime2(3) | Sí | — | — |
| ReleasedBy | bigint | Sí | FK → security.AppUser.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Reglas:

- FK compuesta asegura que la revisión corresponde a OrderLineId.
- Una línea puede dividirse entre almacenes. Una asignación tiene un almacén; sus cantidades pueden distribuirse entre varios viajes mediante TripAllocation.
- Suma de cantidades no canceladas, incluidas completadas, <= demanda vigente. Cantidad positiva.
- Liberar exige origen válido, destino, ubicación para cada tarea y plan aprobado cuando se exija ruta antes de Picking.
- No cancelar una asignación con ejecución neta; reducir/sustituir exige devolver o reasignar cantidades de forma controlada.
- Nuevas asignaciones usan la revisión vigente no cancelada. Las antiguas conservan su revisión solo si material, destino y unidad base permanecen compatibles y se respetan los límites vigentes.
- Las jornadas se distribuyen en CapacityBooking sin duplicar AllocatedBaseQuantity. Una cantidad puede tener capacidad de Picking, Packing y carga en días diferentes; no son tres demandas distintas.

## planning

### planning.DistanceReference — Distancias entre puntos

Estimación direccional entre dos versiones de dirección, no atributo del cliente.

Entrega 2. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OriginAddressId | bigint | No | FK → catalog.PointAddress.Id | — |
| DestinationAddressId | bigint | No | FK → catalog.PointAddress.Id | — |
| RoadDistanceKm | decimal(12,3) | No | — | — |
| ReferenceMinutes | int | Sí | — | — |
| SourceDescription | nvarchar(240) | No | — | — |
| MeasuredOn | date | No | — | — |
| ValidUntil | date | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (OriginAddressId, DestinationAddressId, MeasuredOn, SourceDescription).

Reglas:

- Origen distinto del destino; km >= 0; minutos >= 0; vigencia coherente.
- A->B no implica B->A. Sin dato se muestra desconocido, nunca cero por defecto.
- No representa GPS, tráfico en vivo o ruta óptima. Cada tramo del viaje puede conservar la referencia usada.

### planning.Carrier — Transportistas

Empresa responsable del transporte, si el cliente requiere distinguirla.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

### planning.Trailer — Tráileres

Unidad física reutilizable en distintos viajes; un viaje no es el tráiler.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Registration | nvarchar(64) | No | — | — |
| RegistrationRegion | nvarchar(64) | No | — | — |
| CarrierId | bigint | Sí | FK → planning.Carrier.Id | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code); (RegistrationRegion, Registration).

Reglas:

- Sin capacidad automática de peso/volumen en la primera versión.

### planning.Driver — Choferes

Identidad del conductor; una cuenta opcional permite consultar solo sus viajes.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| DisplayName | nvarchar(240) | No | — | — |
| CarrierId | bigint | Sí | FK → planning.Carrier.Id | — |
| UserId | bigint | Sí | FK → security.AppUser.Id | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- UserId único cuando no es NULL. No almacenar documentos personales innecesarios.

### planning.Trip — Viajes

Identidad del recorrido; primera versión con un almacén de salida y varias paradas.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| OriginWarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| CurrentRevisionId | bigint | Sí | FK → planning.TripRevision.Id | — |
| Status | nvarchar(64) | No | — | DRAFT, RELEASED, LOADING, CLOSED, CANCELLED |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- FK compuesta garantiza que CurrentRevisionId corresponde al mismo viaje.
- Viajes con recogidas en varios almacenes durante el trayecto son ampliación futura; hoy se generan viajes separados.

### planning.TripRevision — Versiones del plan de viaje

Borrador editable hasta aprobación; después es una versión congelada.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| TripId | bigint | No | FK → planning.Trip.Id | — |
| RevisionNumber | int | No | — | — |
| OriginAddressId | bigint | No | FK → catalog.PointAddress.Id | — |
| PlannedDepartureUtc | datetime2(3) | Sí | — | — |
| PlannedTrailerId | bigint | Sí | FK → planning.Trailer.Id | — |
| PlannedDriverId | bigint | Sí | FK → planning.Driver.Id | — |
| Status | nvarchar(64) | No | — | DRAFT, APPROVED, SUPERSEDED |
| ApprovedBy | bigint | Sí | FK → security.AppUser.Id | — |
| ApprovedAtUtc | datetime2(3) | Sí | — | — |
| ChangeReason | nvarchar(1000) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (TripId, RevisionNumber); (Id, TripId).

Reglas:

- OriginAddress debe pertenecer al punto del almacén de origen.
- Aprobar requiere paradas coherentes y sin órdenes repetidos; no se ordena por kilómetros automáticamente.
- Después de iniciar carga, el plan queda congelado. Replanear antes exige nueva revisión y reasignación atómica de dependencias; nunca cambiar solo CurrentRevisionId.

### planning.TripStop — Paradas del viaje

Una visita concreta. Dos visitas al mismo cliente son dos paradas distintas.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| TripRevisionId | bigint | No | FK → planning.TripRevision.Id | — |
| SequenceNumber | int | No | — | — |
| DeliverySiteId | bigint | No | FK → catalog.DeliverySite.Id | — |
| AddressVersionId | bigint | No | FK → catalog.PointAddress.Id | — |
| WindowStartUtc | datetime2(3) | Sí | — | — |
| WindowEndUtc | datetime2(3) | Sí | — | — |
| DistanceFromPreviousId | bigint | Sí | FK → planning.DistanceReference.Id | — |
| Instructions | nvarchar(1000) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (TripRevisionId, SequenceNumber); (Id, TripRevisionId).

Reglas:

- Secuencia positiva, sin duplicados; al aprobar, orden consecutivo o normalizado.
- Dirección pertenece al destino. Ventana inicial < final; ambas nulas o ambas informadas.
- Distancia corresponde exactamente al tramo anterior, usando origen del viaje para la primera parada.
- Inmutable cuando su revisión está aprobada.

### planning.TripAllocation — Cantidades planeadas por parada

Relaciona cantidades de una asignación de surtido con una visita concreta. Permite parciales y nuevos viajes sin reescribir el origen del Picking.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable. |
| StopId | bigint | No | FK → planning.TripStop.Id | — |
| AllocationId | bigint | No | FK → operations.FulfillmentAllocation.Id | — |
| PlannedBaseQuantity | decimal(19,6) | No | — | — |
| CancelledBaseQuantity | decimal(19,6) | No | — | Inicia en cero; liberación de remanente explícita y auditada. |
| Status | nvarchar(64) | No | — | DRAFT, RELEASED, COMPLETED, CANCELLED |
| CreatedAtUtc | datetime2(3) | No | — | — |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | — |

Claves únicas: (StopId, AllocationId).

Reglas:

- PlannedBaseQuantity > 0; 0 <= CancelledBaseQuantity <= PlannedBaseQuantity. Compromiso neto = planeado - cancelado.
- Origen y destino coinciden con el almacén de la asignación y destino de su línea; no asumir que cualquier parada del mismo cliente es equivalente.
- Suma de compromisos netos por asignación, incluidos viajes completados, <= cantidad asignada. Asignaciones HU activas de esa parada no superan el compromiso neto.
- Replanear o liberar un parcial solo afecta remanente no cargado ni asignado a HU activa. Liberar primero la asignación de HU si corresponde; no alterar el material ya embarcado.
- El remanente cancelado de un viaje puede comprometerse en otra parada con un nuevo TripAllocation; Picking, recepción y contenido HU mantienen sus identidades.

### planning.CapacityPool — Capacidad operativa por almacén y proceso

Define el grupo de trabajo cuya capacidad se comparte entre pedidos. No es inventario, capacidad del tráiler ni producción industrial.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable. |
| WarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| Code | nvarchar(64) | No | — | — |
| StageCode | nvarchar(64) | No | — | PICKING, PACKING o LOADING |
| CapacityBasis | nvarchar(64) | No | — | BASE_QUANTITY o STANDARD_MINUTES |
| CapacityUnitId | bigint | Sí | FK → catalog.UnitOfMeasure.Id | Obligatoria solo en BASE_QUANTITY |
| TimeZoneId | nvarchar(240) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Versión de edición, no fecha. |

Claves únicas: (WarehouseId, Code); (WarehouseId, StageCode).

Reglas:

- Primera versión: un pool por almacén/proceso. Dos pedidos compiten por la misma capacidad; no asignar 600 a cada pedido.
- BASE_QUANTITY exige CapacityUnitId; STANDARD_MINUTES exige NULL. La base/unidad no se cambia tras tener historia.
- Productos en unidades incompatibles o con esfuerzo muy distinto requieren estándares en minutos; no sumar KG y PZA.
- Si el personal se comparte entre procesos, repartir explícitamente su tiempo/capacidad; no contabilizar la misma jornada completa en cada pool.

### planning.CapacityDay — Calendario y capacidad efectiva

Una jornada local con capacidad propia. Fines de semana, festivos, ausencias y horas extra se representan explícitamente.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable. |
| PoolId | bigint | No | FK → planning.CapacityPool.Id | — |
| WorkDate | date | No | — | — |
| WindowStartUtc | datetime2(3) | Sí | — | — |
| WindowEndUtc | datetime2(3) | Sí | — | — |
| BaseCapacity | decimal(19,6) | No | — | — |
| ExtraCapacity | decimal(19,6) | No | — | — |
| UnavailableCapacity | decimal(19,6) | No | — | — |
| Status | nvarchar(64) | No | — | OPEN o CLOSED |
| ClosedAtUtc | datetime2(3) | Sí | — | — |
| ChangeReason | nvarchar(1000) | No | — | — |
| ChangedBy | bigint | No | FK → security.AppUser.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Versión de edición, no fecha. |

Claves únicas: (PoolId, WorkDate); (Id, PoolId).

Reglas:

- Capacidad efectiva = BaseCapacity + ExtraCapacity - UnavailableCapacity. Componentes no negativos; indisponible no supera base más extra.
- Capacidad efectiva positiva requiere inicio y fin y fin > inicio; fecha local de inicio coincide con WorkDate. Calendario faltante es desconocido, no ilimitado.
- Un día no laborable conserva fila con capacidad cero. No trasladar capacidad no usada al siguiente día.
- Cambios de capacidad requieren permiso, motivo, RowVersion y auditoría. Si bajan por debajo de compromisos existentes, mostrar sobrecarga y replanear antes de aprobar más trabajo.
- CLOSED exige ClosedAtUtc; OPEN exige NULL. Cerrar no marca pedidos completos ni borra reservas pendientes.
- La capacidad es una restricción de planeación, no motivo para ocultar ejecución física ya ocurrida. Desviaciones se registran y revisan.

### planning.WorkStandardVersion — Esfuerzo por producto y proceso

Factor congelado para convertir cantidad base de material en unidades de capacidad.

Entrega 2. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable. |
| PoolId | bigint | No | FK → planning.CapacityPool.Id | — |
| MaterialId | bigint | No | FK → catalog.Material.Id | — |
| VersionNumber | int | No | — | — |
| CapacityPerBaseUnit | decimal(28,12) | No | — | — |
| ValidFromUtc | datetime2(3) | No | — | — |
| Description | nvarchar(240) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en servidor. |

Claves únicas: (PoolId, MaterialId, VersionNumber); (Id, PoolId).

Reglas:

- Factor > 0 y versión positiva. En BASE_QUANTITY exige unidad base del material igual a la unidad del pool y factor 1.
- En STANDARD_MINUTES el factor expresa minutos estándar por unidad base, no duración real medida.
- Nueva productividad crea otra versión; reservas existentes conservan el factor aprobado. Usar siempre conversiones decimales sin redondeo oculto.
- Capacidad diaria disponible y estándar deben usar la misma unidad de carga de trabajo.

### planning.CapacityBooking — Programación de cantidad por jornada

Reserva una porción de una asignación de surtido para una jornada y proceso, manteniendo la identidad del pedido.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable. |
| AllocationId | bigint | No | FK → operations.FulfillmentAllocation.Id | — |
| PoolId | bigint | No | FK → planning.CapacityPool.Id | — |
| CapacityDayId | bigint | No | FK → planning.CapacityDay.Id | — |
| WorkStandardVersionId | bigint | No | FK → planning.WorkStandardVersion.Id | — |
| PlannedBaseQuantity | decimal(19,6) | No | — | — |
| ReleasedBaseQuantity | decimal(19,6) | No | — | — |
| RescheduledFromId | bigint | Sí | FK → planning.CapacityBooking.Id | — |
| Status | nvarchar(64) | No | — | DRAFT, COMMITTED, COMPLETED, CANCELLED |
| ApprovedBy | bigint | Sí | FK → security.AppUser.Id | — |
| ApprovedAtUtc | datetime2(3) | Sí | — | — |
| ReleaseReason | nvarchar(1000) | Sí | — | — |
| LastOperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Versión de edición, no fecha. |

Claves únicas: (Id, PoolId).

Reglas:

- FKs compuestas aseguran mismo pool para día y estándar. Material y almacén deben corresponder a la asignación.
- PlannedBaseQuantity > 0; 0 <= ReleasedBaseQuantity <= PlannedBaseQuantity. Tras aprobar, no editar cantidad original: liberar pendiente y crear otra reserva.
- DRAFT no consume capacidad. Aprobar exige fecha abierta, cupo, elegibilidad y comprobación atómica de todas las reservas afectadas.
- Por asignación y proceso, suma de cantidades planeadas menos liberadas de reservas COMMITTED/COMPLETED <= cantidad asignada. No sumar procesos diferentes entre sí.
- COMPLETED conserva su cantidad y consumo histórico. CANCELLED exige liberar toda la cantidad y no tener ejecución buena neta.
- No liberar cantidad ejecutada buena ni moverla de fecha. Reprogramar solo el restante, con liberación y nueva reserva en la misma transacción.
- RescheduledFromId apunta a una reserva anterior de la misma asignación y proceso; sin ciclos; suma de cantidades iniciales de hijas no supera lo liberado del origen.
- Un faltante semanal sigue siendo el mismo OrderLine/Allocation. No crear un nuevo pedido ni volver a sumar su demanda.
- La fecha de esta reserva es operativa. No sustituye la fecha solicitada del pedido ni la fecha prometida de entrega al cliente.

### planning.CapacityExecution — Consumo de capacidad vinculado a hechos

Relaciona trabajo registrado con la reserva y con el día real de ejecución, aunque haya ocurrido después de lo planeado.

Entrega 2. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable. |
| BookingId | bigint | No | FK → planning.CapacityBooking.Id | — |
| PoolId | bigint | No | FK → planning.CapacityPool.Id | — |
| ActualCapacityDayId | bigint | No | FK → planning.CapacityDay.Id | — |
| PickConfirmationId | bigint | Sí | FK → warehouse.PickConfirmation.Id | — |
| HandlingUnitItemId | bigint | Sí | FK → warehouse.HandlingUnitItem.Id | Agregar esta columna y FK en entrega 3 |
| LoadEventId | bigint | Sí | FK → shipping.LoadEvent.Id | Agregar esta columna y FK en entrega 4 |
| BaseQuantity | decimal(19,6) | No | — | — |
| UsedStandardCapacity | decimal(19,6) | No | — | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en servidor. |

Reglas:

- FKs compuestas aseguran mismo pool en reserva y jornada real. El día real corresponde al momento del hecho, no se retrofecha para ocultar atraso.
- Contexto PICKING: solo PickConfirmationId. PACKING: solo HandlingUnitItemId. LOADING: LoadEventId de tipo LOAD y HandlingUnitItemId. Validar CHECK de combinación y proceso del pool.
- El hecho pertenece a la misma asignación/material/almacén; en carga, el aporte HU debe estar dentro de la HU del LoadEvent.
- BaseQuantity > 0; suma de enlaces a un hecho (o aporte dentro de LOAD) no supera su cantidad. Un hecho puede dividirse entre reservas compatibles sin contabilizarse dos veces.
- UsedStandardCapacity = BaseQuantity por factor congelado de la reserva. Es carga estándar consumida, no medición automática de minutos de operario.
- La ejecución buena se deriva del hecho y sus reversiones. Una reversión de negocio no devuelve tiempo de trabajo consumido; reempaque/retrabajo consume capacidad adicional.
- La ejecución reduce cantidad pendiente de su reserva y se carga a ActualCapacityDayId. No sumar reserva original completa más todo lo ejecutado.
- Insertar junto con el hecho operativo y resultado idempotente. Un reintento no crea otro enlace ni vuelve a consumir cupo.
- No editar/borrar el consumo histórico. Si se corrige atribución de tiempo o capacidad, definir ajuste auditable específico antes de implementarlo.

## warehouse

### warehouse.PickingTask — Tareas de Picking

Trabajo asignable dentro de un único almacén.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| WarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| Code | nvarchar(64) | No | — | — |
| AssignedUserId | bigint | Sí | FK → security.AppUser.Id | — |
| Status | nvarchar(64) | No | — | OPEN, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED |
| StartedAtUtc | datetime2(3) | Sí | — | — |
| CompletedAtUtc | datetime2(3) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- Cambiar operador no cambia confirmaciones previas; reasignaciones quedan auditadas.
- Completar requiere que todas las líneas estén satisfechas o su remanente haya sido tratado explícitamente.

### warehouse.PickingTaskLine — Detalle de Picking

Indica asignación de surtido, posición y lote concretos. Separar por origen o lote cuando se divida el surtido.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| TaskId | bigint | No | FK → warehouse.PickingTask.Id | — |
| AllocationId | bigint | No | FK → operations.FulfillmentAllocation.Id | — |
| SourceLocationId | bigint | No | FK → catalog.Location.Id | — |
| LotId | bigint | Sí | FK → catalog.MaterialLot.Id | — |
| PlannedBaseQuantity | decimal(19,6) | No | — | — |
| Status | nvarchar(64) | No | — | OPEN, IN_PROGRESS, COMPLETED, CANCELLED |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Reglas:

- Tarea, ubicación y asignación pertenecen al mismo almacén; ubicación habilitada para Picking.
- Lote pertenece al material del requisito; obligatorio cuando lo exige Material.
- Total de líneas activas/completadas por asignación <= cantidad asignada; positivas.
- Origen/lote/asignación no se editan tras confirmar; corregir requiere reversión y línea nueva.
- CANCELLED solo si no existe confirmación neta; cambiar cantidades nunca puede dejarlas por debajo de lo ya confirmado.

### warehouse.PickConfirmation — Confirmaciones de Picking

Hecho registrado e inmutable; cada confirmación aporta una cantidad.

Entrega 2. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| TaskLineId | bigint | No | FK → warehouse.PickingTaskLine.Id | — |
| BaseQuantity | decimal(19,6) | No | — | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| CaptureMethod | nvarchar(64) | No | — | MANUAL, CAMERA, KEYBOARD_SCANNER |
| ObservedLocationCode | nvarchar(64) | Sí | — | — |
| ObservedMaterialCode | nvarchar(128) | Sí | — | — |
| OccurredAtUtc | datetime2(3) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- Cantidad > 0; suma neta por línea <= planeada; respetar escala de unidad base.
- Validar material, ubicación, lote, usuario, estado y bloqueos en el servidor.
- Tiempo efectivo oficial es del servidor; datos capturados no garantizan detección física.

### warehouse.PickReversal — Reversiones de Picking

Reversión completa de una confirmación, conservando el original.

Entrega 2. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| PickConfirmationId | bigint | No | FK → warehouse.PickConfirmation.Id | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| Reason | nvarchar(1000) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (PickConfirmationId).

Reglas:

- Solo si no tiene recepción neta en Packing. Una reversión parcial se representa revirtiendo y registrando la parte correcta, todo en una transacción.
- No reversar una reversión ni editar cantidades originales.

### warehouse.PackingReceipt — Recepción para Packing

Cantidad efectivamente recibida desde una confirmación de Picking; admite recepciones parciales.

Entrega 3. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| PickConfirmationId | bigint | No | FK → warehouse.PickConfirmation.Id | — |
| PackingLocationId | bigint | No | FK → catalog.Location.Id | — |
| BaseQuantity | decimal(19,6) | No | — | — |
| ReceivedBy | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| ReceivedAtUtc | datetime2(3) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- Cantidad > 0; recepciones netas <= confirmación de Picking no revertida.
- Puesto PACKING del mismo almacén. Daños/faltantes generan incidencia, no recepción ficticia.

### warehouse.ReceiptReversal — Reversiones de recepción

Corrige una recepción sin borrar su rastro.

Entrega 3. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ReceiptId | bigint | No | FK → warehouse.PackingReceipt.Id | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| Reason | nvarchar(1000) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (ReceiptId).

Reglas:

- Reversión completa y solo si la recepción no tiene contenido neto en HU.

### warehouse.HandlingUnit — Unidades de manejo

Contenedor operativo identificado de forma única, con material trazable.

Entrega 3. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| TypeId | bigint | No | FK → catalog.HandlingUnitType.Id | — |
| WarehouseId | bigint | No | FK → catalog.Warehouse.Id | — |
| DeliverySiteId | bigint | No | FK → catalog.DeliverySite.Id | — |
| CurrentLocationId | bigint | Sí | FK → catalog.Location.Id | — |
| Status | nvarchar(64) | No | — | OPEN, PACKED, STAGED, LOADED, SHIPPED, VOID |
| PackedAtUtc | datetime2(3) | Sí | — | — |
| PackedBy | bigint | Sí | FK → security.AppUser.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

Reglas:

- Código global en esta base, único para siempre; no reutilizar una HU embarcada.
- Una HU puede mezclar líneas/materiales del mismo destino y almacén; no destinos distintos en la primera versión.
- Location del mismo almacén; requerida antes de cargar, nula cuando esté en tráiler. La asignación de carga registra dónde está entonces.
- El contenido se calcula desde HandlingUnitItem menos PackingReversal. Congelado después de confirmar Packing hasta reapertura autorizada; no modificar HU cargada/embarcada.

### warehouse.HandlingUnitItem — Contenido trazable de HU

Cada aporte proviene de una recepción; permite dividir una recepción entre varias HU.

Entrega 3. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| HandlingUnitId | bigint | No | FK → warehouse.HandlingUnit.Id | — |
| ReceiptId | bigint | No | FK → warehouse.PackingReceipt.Id | — |
| BaseQuantity | decimal(19,6) | No | — | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| PackedBy | bigint | No | FK → security.AppUser.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- Cantidad positiva; aportes no revertidos por recepción <= recepción neta.
- Almacén y destino de HU deben coincidir con el pedido/recepción. Material y lote se derivan de la cadena, sin duplicarlos de forma contradictoria.
- Admite varios aportes de la misma recepción; cada uno tiene identidad propia y puede revertirse una sola vez.

### warehouse.PackingReversal — Reversiones de contenido

Retira completamente un aporte de HU; permite reempacar manteniendo el origen.

Entrega 3. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| HandlingUnitItemId | bigint | No | FK → warehouse.HandlingUnitItem.Id | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| Reason | nvarchar(1000) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (HandlingUnitItemId).

Reglas:

- Reversión completa; HU abierta, sin asignación activa de embarque y con autorización si se reabrió.
- Para dividir/cambiar de HU, revertir el aporte y crear los nuevos aportes en una sola transacción; conservar cantidad.

### warehouse.HandlingUnitMovement — Movimientos de HU

Historial dentro del almacén; no pretende ser un kardex completo de existencias.

Entrega 3. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| HandlingUnitId | bigint | No | FK → warehouse.HandlingUnit.Id | — |
| FromLocationId | bigint | Sí | FK → catalog.Location.Id | — |
| ToLocationId | bigint | No | FK → catalog.Location.Id | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| MovedAtUtc | datetime2(3) | No | — | — |
| Reason | nvarchar(1000) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- Ubicaciones del mismo almacén; From coincide con posición actual. Solo la colocación inicial puede tener origen nulo.
- No mover a ubicación inactiva, a sí misma o HU cargada. Tipo STAGING para pasar a preembarque.
- Guardar evento y actualizar CurrentLocation en la misma transacción. Carga/descarga se registra en LoadEvent, no como traslado a un almacén ficticio.

## shipping

### shipping.Shipment — Embarques

Ejecución física del plan aprobado, desde un almacén. Un viaje inicial tiene un solo embarque.

Entrega 4. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| TripId | bigint | No | FK → planning.Trip.Id | — |
| TripRevisionId | bigint | No | FK → planning.TripRevision.Id | — |
| TrailerId | bigint | No | FK → planning.Trailer.Id | — |
| DriverId | bigint | Sí | FK → planning.Driver.Id | — |
| DockLocationId | bigint | Sí | FK → catalog.Location.Id | — |
| Status | nvarchar(64) | No | — | OPEN, LOADING, CLOSED, CANCELLED |
| SealNumber | nvarchar(64) | Sí | — | — |
| OpenedAtUtc | datetime2(3) | No | — | — |
| ClosedAtUtc | datetime2(3) | Sí | — | — |
| CancelledAtUtc | datetime2(3) | Sí | — | Solo embarque cancelado. Junto a ClosedAtUtc define ocupación activa de tráiler. |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (TripId); (Id, TripRevisionId).

Reglas:

- Revisión pertenece al viaje y está aprobada. Andén DOCK del almacén de salida.
- Tráiler no puede estar en dos embarques OPEN/LOADING; unicidad de ocupación y control transaccional.
- Requisito de sello/chofer/andén se confirma con el negocio; no exigirlo inventando reglas.
- Cierre congela asignaciones, contenido y plan. No reapertura inicial; una corrección posterior requiere proceso específico.
- OPEN/LOADING: ClosedAtUtc y CancelledAtUtc nulos. CLOSED: solo ClosedAtUtc informado. CANCELLED: solo CancelledAtUtc informado; sin HU activa/cargada. CHECK local vincula fechas y estados.
- Un embarque cancelado no se reutiliza: una nueva salida tendrá otro Trip y otro Shipment en esta primera versión.

### shipping.ShipmentUnit — Asignación de HU a embarque

Conserva asignaciones previas sin permitir doble asignación activa.

Entrega 4. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ShipmentId | bigint | No | FK → shipping.Shipment.Id | — |
| TripRevisionId | bigint | No | FK → planning.TripRevision.Id | — |
| StopId | bigint | No | FK → planning.TripStop.Id | — |
| HandlingUnitId | bigint | No | FK → warehouse.HandlingUnit.Id | — |
| Status | nvarchar(64) | No | — | ASSIGNED, LOADED, DISPATCHED, RELEASED |
| AssignedBy | bigint | No | FK → security.AppUser.Id | — |
| AssignedAtUtc | datetime2(3) | No | — | — |
| ReleasedAtUtc | datetime2(3) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Reglas:

- FKs compuestas garantizan misma revisión para embarque y parada.
- HU única entre filas con ReleasedAtUtc NULL. Una HU DISPATCHED conserva NULL para impedir reutilización.
- HU empacada/liberada, mismo almacén y destino; cada aporte debe tener compromiso suficiente en TripAllocation para esa parada.
- RELEASED exige fecha y HU no cargada; asignar a otro viaje requiere registrar liberación y validar plan nuevamente.

### shipping.LoadEvent — Carga y descarga correctiva

Hechos que cambian la ubicación entre el almacén y el tráiler; descarga aquí es antes de salida, no entrega al cliente.

Entrega 4. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ShipmentUnitId | bigint | No | FK → shipping.ShipmentUnit.Id | — |
| EventType | nvarchar(64) | No | — | LOAD, UNLOAD |
| WarehouseLocationId | bigint | No | FK → catalog.Location.Id | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| OccurredAtUtc | datetime2(3) | No | — | — |
| Reason | nvarchar(1000) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- LOAD exige ASSIGNED y ubicación real coincidente; UNLOAD exige LOADED y destino válido del mismo almacén.
- No repetir LOAD sin UNLOAD, ni descargar un embarque cerrado. La transacción actualiza HU y ShipmentUnit.
- Carga inversa según secuencia de paradas, con excepciones autorizadas; sin optimización física automática.

### shipping.ShipmentClosure — Acta de cierre

Instantánea histórica de lo que se declaró cargado al cerrar.

Entrega 4. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| ShipmentId | bigint | No | FK → shipping.Shipment.Id | — |
| ClosedBy | bigint | No | FK → security.AppUser.Id | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| ClosedAtUtc | datetime2(3) | No | — | — |
| ManifestJson | nvarchar(max) | No | — | Instantánea exportable de HU, contenido, destinos, conductor, unidad y sello |
| ManifestHash | binary(32) | No | — | — |
| IsPartial | bit | No | — | — |
| PartialApprovalId | bigint | Sí | FK → quality.Approval.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Claves únicas: (ShipmentId).

Reglas:

- ManifestJson es copia histórica; relaciones operativas siguen siendo la fuente de integridad.
- No cerrar con HU asignadas sin cargar, incidencias/bloqueos impeditivos o pendientes sin resolución.
- Cierre parcial, si se autoriza, conserva remanente en otro plan; no marca entregado lo que no salió.
- CLOSED/SHIPPED significa salida del almacén, no entrega confirmada al cliente.

## quality

### quality.IncidentType — Tipos de incidencia

Catálogo de causas operativas.

Entrega 1. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| Code | nvarchar(64) | No | — | — |
| Name | nvarchar(240) | No | — | — |
| DefaultSeverity | nvarchar(64) | No | — | — |
| IsActive | bit | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Claves únicas: (Code).

### quality.Incident — Incidencias

Una incidencia tiene un objeto principal con FK real; otros datos se obtienen siguiendo sus relaciones.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| TypeId | bigint | No | FK → quality.IncidentType.Id | — |
| ImportRunId | bigint | Sí | FK → integration.ImportRun.Id | — |
| OrderLineId | bigint | Sí | FK → operations.OrderLine.Id | — |
| TaskLineId | bigint | Sí | FK → warehouse.PickingTaskLine.Id | — |
| HandlingUnitId | bigint | Sí | FK → warehouse.HandlingUnit.Id | Agregar esta columna y FK en la entrega 3, cuando exista la tabla destino. |
| ShipmentId | bigint | Sí | FK → shipping.Shipment.Id | Agregar esta columna y FK en la entrega 4, cuando exista la tabla destino. |
| TripId | bigint | Sí | FK → planning.Trip.Id | — |
| ReportedBy | bigint | No | FK → security.AppUser.Id | — |
| Severity | nvarchar(64) | No | — | — |
| Status | nvarchar(64) | No | — | OPEN, INVESTIGATING, RESOLVED, CANCELLED |
| Description | nvarchar(1000) | No | — | — |
| ResolvedAtUtc | datetime2(3) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Reglas:

- Exactamente uno de los seis FKs de contexto informado. Evita EntityType/EntityId sin integridad referencial.
- Resolver una incidencia no elimina un bloqueo automáticamente ni corrige cantidades por sí solo.

### quality.IncidentAction — Seguimiento de incidencias

Comentarios, diagnóstico y resolución conservados cronológicamente.

Entrega 2. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| IncidentId | bigint | No | FK → quality.Incident.Id | — |
| ActorUserId | bigint | No | FK → security.AppUser.Id | — |
| ActionCode | nvarchar(64) | No | — | — |
| Comment | nvarchar(1000) | No | — | — |
| OperationId | bigint | No | FK → platform.OperationRequest.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

### quality.Hold — Bloqueos operativos

Bloquea una línea, una HU o un embarque sin confundir condición con etapa del proceso.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OrderLineId | bigint | Sí | FK → operations.OrderLine.Id | — |
| HandlingUnitId | bigint | Sí | FK → warehouse.HandlingUnit.Id | Agregar esta columna y FK en la entrega 3, cuando exista la tabla destino. |
| ShipmentId | bigint | Sí | FK → shipping.Shipment.Id | Agregar esta columna y FK en la entrega 4, cuando exista la tabla destino. |
| IncidentId | bigint | Sí | FK → quality.Incident.Id | — |
| Reason | nvarchar(1000) | No | — | — |
| PlacedBy | bigint | No | FK → security.AppUser.Id | — |
| ReleasedAtUtc | datetime2(3) | Sí | — | — |
| ReleasedBy | bigint | Sí | FK → security.AppUser.Id | — |
| ReleaseReason | nvarchar(1000) | Sí | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Reglas:

- Exactamente uno de los tres objetos informado; puede haber varios bloqueos simultáneos.
- Liberación exige usuario, motivo y fecha juntos. No borrar el bloqueo.
- Un bloqueo de línea se propaga a sus asignaciones, Picking y HU; HU mixta bloquea su carga completa hasta resolver/separar.

### quality.Approval — Autorizaciones de excepción

Autorización concreta y consumible, no permiso general para saltarse validaciones.

Entrega 2. Editable con control de versión y restricciones de estado.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| IncidentId | bigint | Sí | FK → quality.Incident.Id | — |
| OrderLineId | bigint | Sí | FK → operations.OrderLine.Id | — |
| HandlingUnitId | bigint | Sí | FK → warehouse.HandlingUnit.Id | Agregar esta columna y FK en la entrega 3, cuando exista la tabla destino. |
| ShipmentId | bigint | Sí | FK → shipping.Shipment.Id | Agregar esta columna y FK en la entrega 4, cuando exista la tabla destino. |
| TripId | bigint | Sí | FK → planning.Trip.Id | — |
| ActionCode | nvarchar(64) | No | — | — |
| PayloadHash | binary(32) | No | — | — |
| ReviewPayloadJson | nvarchar(max) | No | — | Instantánea legible de los parámetros sujetos a aprobación; esquema estricto por ActionCode, sin secretos. |
| ExpectedVersion | binary(8) | No | — | — |
| RequestedBy | bigint | No | FK → security.AppUser.Id | — |
| DecidedBy | bigint | Sí | FK → security.AppUser.Id | — |
| Decision | nvarchar(64) | No | — | PENDING, APPROVED, REJECTED, EXPIRED |
| DecidedAtUtc | datetime2(3) | Sí | — | — |
| ExpiresAtUtc | datetime2(3) | Sí | — | — |
| Reason | nvarchar(1000) | No | — | — |
| ExecutedOperationId | bigint | Sí | FK → platform.OperationRequest.Id | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |
| UpdatedAtUtc | datetime2(3) | No | — | — |
| RowVersion | rowversion | No | — | Control de edición concurrente; no es fecha. |

Reglas:

- Exactamente uno de OrderLine, HU, Shipment o Trip; Incident es contexto adicional opcional.
- Versión y hash fijan objeto y parámetros aprobados; cualquier cambio invalida la autorización.
- Ejecutar solo APPROVED, vigente, permiso actual y no consumida; ExecutedOperationId único cuando no nulo.
- Separación solicitante/aprobador se valida con el negocio; nunca asumir que toda excepción puede aprobarla cualquier supervisor.
- ReviewPayloadJson y PayloadHash coinciden mediante serialización canónica; la aplicación muestra exactamente estos parámetros al aprobador.

## audit

### audit.AuditEvent — Auditoría

Registro de acciones y resultados para investigación; no sustituye las tablas operativas.

Entrega 1. Histórico; no modificar hechos confirmados.

| Campo | Tipo propuesto SQL Server | NULL | Clave / referencia | Significado |
| --- | --- | --- | --- | --- |
| Id | bigint | No | PK | Identificador interno estable; identity propuesto. |
| OperationId | bigint | Sí | FK → platform.OperationRequest.Id | — |
| ActorUserId | bigint | Sí | FK → security.AppUser.Id | — |
| ActionCode | nvarchar(64) | No | — | — |
| EntityType | nvarchar(64) | No | — | — |
| EntityKey | nvarchar(128) | No | — | — |
| Outcome | nvarchar(64) | No | — | — |
| BeforeJson | nvarchar(max) | Sí | — | — |
| AfterJson | nvarchar(max) | Sí | — | — |
| Reason | nvarchar(1000) | Sí | — | — |
| CorrelationId | uniqueidentifier | No | — | — |
| OccurredAtUtc | datetime2(3) | No | — | — |
| CreatedAtUtc | datetime2(3) | No | — | Momento de registro en el servidor. |

Reglas:

- EntityType/EntityKey es referencia descriptiva de auditoría, no FK ni fuente para decidir una operación.
- Acciones exitosas y auditoría se confirman juntas. Intentos fallidos se registran después del rollback en un registro separado.
- Sin contraseñas, tokens ni cadenas de conexión. Acceso restringido y retención por acordar.
- Solo anexar con cuenta operativa. No afirmar inmutabilidad absoluta frente a administradores de SQL Server.

## Referencias compuestas obligatorias

Impedir enlaces entre pedidos, revisiones, intentos o almacenes diferentes. Una FK compuesta opcional aún no está establecida si su primer campo es NULL; los demás campos conservan sus FKs independientes.

| Tabla y columnas | Destino único |
| --- | --- |
| operations.SalesOrder (CurrentRevisionId, Id) | operations.OrderRevision (Id, OrderId) |
| operations.OrderLineRevision (OrderRevisionId, OrderId) | operations.OrderRevision (Id, OrderId) |
| operations.OrderLineRevision (OrderLineId, OrderId) | operations.OrderLine (Id, OrderId) |
| operations.FulfillmentAllocation (OrderLineRevisionId, OrderLineId) | operations.OrderLineRevision (Id, OrderLineId) |
| planning.Trip (CurrentRevisionId, Id) | planning.TripRevision (Id, TripId) |
| shipping.Shipment (TripRevisionId, TripId) | planning.TripRevision (Id, TripId) |
| shipping.ShipmentUnit (ShipmentId, TripRevisionId) | shipping.Shipment (Id, TripRevisionId) |
| shipping.ShipmentUnit (StopId, TripRevisionId) | planning.TripStop (Id, TripRevisionId) |
| integration.ImportRow (OrderResultId, RunId) | integration.ImportOrderResult (Id, RunId) |
| integration.ImportError (RowId, RunId) | integration.ImportRow (Id, RunId) |
| catalog.Location (ParentLocationId, WarehouseId) | catalog.Location (Id, WarehouseId) |
| planning.CapacityBooking (CapacityDayId, PoolId) | planning.CapacityDay (Id, PoolId) |
| planning.CapacityBooking (WorkStandardVersionId, PoolId) | planning.WorkStandardVersion (Id, PoolId) |
| planning.CapacityExecution (BookingId, PoolId) | planning.CapacityBooking (Id, PoolId) |
| planning.CapacityExecution (ActualCapacityDayId, PoolId) | planning.CapacityDay (Id, PoolId) |

## Unicidad condicionada

Requiere índices únicos filtrados y CHECK de estado. No reemplazar por UNIQUE simple sobre una columna nullable.

| Tabla | Columnas | Filtro lógico |
| --- | --- | --- |
| planning.Driver | UserId | UserId IS NOT NULL |
| quality.Approval | ExecutedOperationId | ExecutedOperationId IS NOT NULL |
| shipping.ShipmentUnit | HandlingUnitId | ReleasedAtUtc IS NULL |
| shipping.Shipment | TrailerId | ClosedAtUtc IS NULL AND CancelledAtUtc IS NULL |
| planning.CapacityExecution | BookingId, PickConfirmationId | PickConfirmationId IS NOT NULL |
| planning.CapacityExecution | BookingId, HandlingUnitItemId | HandlingUnitItemId IS NOT NULL AND LoadEventId IS NULL |
| planning.CapacityExecution | BookingId, LoadEventId, HandlingUnitItemId | LoadEventId IS NOT NULL |
