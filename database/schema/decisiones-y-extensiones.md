# Decisiones pendientes y crecimiento del modelo

Versión 0.2 · 27 de septiembre de 2026. Acompaña al [esquema lógico](esquema-logico.md).

## Decisiones antes de implementar cada módulo

No hay muestra real de SAP y no se deben convertir estos supuestos en compromisos contractuales. Se propone una opción conservadora para diseñar y se indica cuándo necesita aprobación.

| ID | Decisión | Propuesta usada en el modelo | Validar antes de |
| --- | --- | --- | --- |
| D01 | Identidad de pedido y línea | Origen/sociedad + pedido; clave de línea estable con sublínea si existe | Importador operativo |
| D02 | Archivo completo o incremental | Snapshot completo por pedido; no cancelar omisiones automáticamente | Actualizaciones |
| D03 | Importación parcialmente válida | Aceptar/rechazar por pedido completo, no por fila aislada | Importador operativo |
| D04 | Revisión del origen y archivos tardíos | Cambios sin versión confiable requieren revisión manual | Actualizaciones |
| D05 | Fuente de catálogos | Alta/importación controlada; desconocidos producen error | Primera importación |
| D06 | Ubicación vs saldo disponible | Solo ubicación y cantidades del flujo; inventario físico pendiente de confirmación | Liberación de tareas |
| D07 | Unidad, decimales y conversión | Unidad base por material; cero tolerancia de exceso; escala explícita | Picking |
| D08 | Lotes, caducidad y seriales | Lote opcional por material; lote+material único; seriales futuros | Picking |
| D09 | Producto repetido en pedido | Permitido con claves de línea distintas | Importador |
| D10 | Destinos de un pedido | Destino por línea; cliente del encabezado coherente | Pedidos |
| D11 | HU mixtas | Materiales/lotes/líneas del mismo destino y almacén; una parada por asignación | Packing |
| D12 | Varias salidas por pedido | Sí, mediante cantidades asignadas a varios viajes | Planeación |
| D13 | Orígenes por viaje | Un almacén de salida; rutas con recogidas múltiples son ampliación | Planeación |
| D14 | Kilómetros y horarios | Referencia manual documentada; orden de paradas aprobado por supervisor | Planeación |
| D15 | Momento de planear el viaje | Puede planearse antes de Picking; obligatorio antes de asignar/cargar HU | Planeación |
| D16 | Liberación y excepciones | Permisos separados para liberar, corregir, bloquear y autorizar | Seguridad operativa |
| D17 | Parciales y faltantes | Bloquear cierre si no hay resolución explícita del remanente | Embarques |
| D18 | Sello, chofer y andén obligatorios | Campos previstos; obligatoriedad depende del proceso | Cierre |
| D19 | Correcciones después del cierre | No reapertura inicial; módulo posterior de ajustes/devoluciones | Piloto |
| D20 | Captura manual o lectores | Registrar método; ninguna regla depende únicamente de escáner | Apps operativas |
| D21 | Historial y retención | Hechos anexados, archivos originales preservados y auditoría sin secretos | Piloto |
| D22 | Volúmenes y concurrencia | Sin cifras inventadas; dimensionar con pedidos/día, líneas, archivos y usuarios | Índices y piloto |
| D23 | Múltiples empresas | Una organización operadora con varios almacenes | Si se requiere separación empresarial |
| D24 | Significado de fecha solicitada | Fecha de entrega propuesta; confirmar si el origen informa surtido, salida o entrega | Contrato de archivo |
| D25 | Cambios de dirección/catálogos | Versionar direcciones y conservar instantáneas de material; no editar historia | Catálogos |
| D26 | Autorización de carga fuera de secuencia | Caso excepcional con motivo y alcance; nunca bypass de identidad/cantidad | Carga |
| D27 | Disponibilidad de materiales en el piloto | Registrar faltantes sin simular inventario | Piloto |
| D28 | Restricciones físicas del transporte | Acomodo y seguridad validados por operación; sin motor de peso/volumetría | Propuesta al cliente |

La pregunta sobre inventario quedó abierta al preparar este diseño. Si se decide controlarlo desde el inicio, activar el diseño de inventario y definir entradas, salidas, ajustes y responsables antes de prometer reservas físicas.

## Tablas futuras y punto de relación

Las siguientes son **extensiones propuestas, no parte de las 68 tablas ni aprobadas para la primera versión**. Sus campos son orientativos. No hay filas genéricas reservadas para funciones todavía desconocidas.

| Extensión | Tablas sugeridas y campos centrales | Relación con el núcleo | Condición previa |
| --- | --- | --- | --- |
| Existencias físicas | StockPosition(Id, MaterialId, LocationId, LotId?, StockStatus); StockMovement(Id, PositionId, QuantityDelta, Reason, OperationId, ReversalOfId?) | Material, Location, MaterialLot, OperationRequest | Fuente de saldos iniciales y registro de TODOS los movimientos |
| Reservas reales | StockReservation(Id, PositionId, PickingTaskLineId, ReservedQty, ConsumedQty, ReleasedQty) | Posición física y detalle de Picking | Reserva/consumo/liberación atómicos; saldo negativo prohibido o política explícita |
| Recepción de mercancía | GoodsReceipt y GoodsReceiptLine con material, lote, ubicación y cantidad | Catálogos y StockMovement | Definir documentos de entrada y aceptación de cantidades |
| Inventarios cíclicos | InventoryCount y InventoryCountLine con esperado, contado y diferencia autorizada | StockPosition, AppUser, Approval | Corte de movimientos, recuentos y aprobación |
| Series individuales | MaterialSerial y UnitSerialAssignment | Material, MaterialLot, HandlingUnitItem | Decidir unicidad de serie y movimientos por pieza |
| Activos retornables | ReturnableAsset y AssetAssignment | HandlingUnit | Separar tarima física reutilizable de HU operativa |
| HU anidadas | HandlingUnitContainment(ParentHuId, ChildHuId, vigencia) | HandlingUnit | Evitar ciclos, doble pertenencia y doble conteo de cantidades |
| Traslados entre almacenes | TransferOrder, TransferLine, TransferReceipt | Warehouse, Location, HU; StockMovement si se activa | Recepción en destino y propiedad del stock en tránsito |
| Devoluciones | ReturnAuthorization, ReturnLine, ReturnReceipt | ShipmentClosure, ShipmentUnit, HandlingUnitItem | No reabrir ni borrar el embarque original; inspección de retorno |
| Entrega al cliente | DeliveryConfirmation y DeliveryException | TripStop, ShipmentUnit | Ampliación expresa del alcance fuera del almacén |
| GPS | TripPosition con fuente y hora | Trip | Conectividad, dispositivos y retención acordadas |
| Impresión | LabelTemplateVersion y PrintJob | HandlingUnit y AppUser | Equipos reales, reimpresiones auditadas y formatos |
| Evidencias adjuntas | Attachment y tablas de vínculo tipadas IncidentAttachment, ShipmentAttachment | Incident, Shipment | Almacenamiento, acceso, límites y respaldo |
| Alias externos | MaterialExternalCode, CustomerExternalCode, LocationExternalCode | SourceSystem y catálogo específico | Códigos distintos entre sistemas/sociedades |
| Ventanas extraordinarias | DeliveryCalendarException | DeliverySite | Festivos, cierres temporales y manejo de zona horaria |
| Recogidas en múltiples orígenes | TripLeg y PickupStop, relaciones con órdenes de traslado | TripRevision, LogisticsPoint | Rediseñar alcance de carga/descarga por tramo; no basta un campo adicional |
| Múltiples empresas | Company, CompanyWarehouse y ámbitos de unicidad/permisos revisados | Todo agregado propietario | Migrar claves e índices; probar aislamiento, no añadir CompanyId superficialmente |
| Integraciones automáticas | OutboxMessage e IntegrationDeliveryAttempt | OperationRequest | Publicación transaccional y entrega idempotente; no acceso directo a SAP por defecto |
| Offline | Device, SyncCommand, SyncConflict | AppUser y OperationRequest | Política de conflicto y compatibilidad de versiones antes de habilitarlo |

### Condiciones mínimas si se activa inventario

StockPosition tendría clave lógica material + ubicación + lote opcional + condición física. La unicidad del lote nulo necesita tratamiento explícito; no utilizar lote ficticio «SIN LOTE» para eludir reglas.

Movimientos tipados explican cada entrada/salida; las transferencias generan dos lados balanceados dentro de una transacción. Los saldos se derivan del libro de movimientos o de una proyección reconciliable, nunca de un saldo editable sin soporte.

Reserva disponible = existencia utilizable menos reservas vigentes. Consumir una reserva y registrar la salida se hace junto con Picking. Una anulación no devuelve existencias físicamente por sí sola: exige confirmar dónde quedó el material. El momento del decremento (Picking, staging o salida) debe acordarse antes de implementar, para no descontar dos veces.

Deberán existir saldo inicial, recepción, ajustes autorizados, daños/bloqueos, liberación de reserva, transferencia y conciliación. Solo añadir una columna Stock a Material sería insuficiente.

## Cómo agregar una tabla sin romper lo existente

1. Identificar qué hecho nuevo representa y quién lo posee.
2. Referenciar PK estables del núcleo con FKs reales; si una relación es muchos a muchos, crear tabla puente.
3. Definir identidad, unidad, nulabilidad, estado y política histórica antes de agregar campos.
4. Añadir una migración numerada y revisable. Crear primero objetos/columnas compatibles y opcionales.
5. Poblar/validar datos existentes antes de hacer obligatoria una nueva relación.
6. Ajustar servicios/API y compatibilidad de la app durante la transición.
7. Probar invariantes nuevas y antiguas, actualización y recuperación.
8. Añadir índices según consultas reales y actualizar diagramas/diccionario.

Evitar una tabla universal Entidad/Atributo/Valor para cantidades, estados, lotes y relaciones críticas. JSON queda reservado a staging, auditoría, parámetros de aprobación e instantáneas del manifiesto; no oculta las relaciones operativas.

No todas las ampliaciones son puramente aditivas: múltiples empresas, offline y recogidas en distintos almacenes pueden exigir migraciones y cambios de reglas. Esa limitación debe reconocerse desde ahora.


Actualización 0.2: las tablas de capacidad diaria complementan este diseño; consultar [capacidad diaria](capacidad-diaria.md). La implementación inicial SQL está en database/migrations; las reglas agregadas de operación siguen pendientes en el backend.
