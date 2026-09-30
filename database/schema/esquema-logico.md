# Esquema lógico de Picking, Packing, Planeación y Embarques

Versión 0.2 · 27 de septiembre de 2026 · **Propuesta de diseño para revisión**.

Este documento define el modelo; no crea bases, tablas ni procedimientos y no contiene credenciales. Conserva Microsoft SQL Server, Python/FastAPI y Flutter para Android/Windows. Se basa en AGENTS.md, el alcance acordado, la propuesta Digital_Warehouse_Management.pdf y la ampliación de planeación conversada.

No se puede certificar un esquema como definitivo sin muestra del archivo, reglas del negocio y pruebas de implementación. Aquí se hacen explícitas las decisiones, las invariantes y las condiciones que deberán verificarse. Diseñar para crecer no significa predecir cualquier requisito futuro ni eliminar la necesidad de migraciones.

## 1. Entregables y forma de lectura

1. [Diagrama general](../../docs/diagramas/modelo-general.svg): mapa visual de las relaciones principales.
2. [Diagramas por módulo](../../docs/diagramas/modelo-datos.md): relaciones con PK/FK en Mermaid.
3. [Diccionario de tablas](diccionario-tablas.md): 68 tablas, campos, tipos propuestos, NULL, claves y reglas.
4. [DBML editable](modelo-logico.dbml): modelo relacional para herramientas compatibles; no es SQL ejecutable.
5. [Modelo estructurado](modelo-logico.json): misma definición para futuras revisiones y verificaciones.
6. [Matriz de errores y aceptación](../../docs/pruebas/casos-modelo-datos.md): escenarios que debe superar la futura implementación.
7. [Decisiones y ampliaciones](decisiones-y-extensiones.md): acuerdos pendientes y relaciones para crecer.

DBML no representa todas las restricciones específicas de SQL Server. Las reglas de este documento y del diccionario forman parte del diseño aunque no aparezcan dibujadas. No convertir DBML a SQL y ejecutarlo sin implementar también CHECK, índices filtrados, permisos, transacciones y migraciones.

## 2. Qué representa el modelo

La unidad operativa distingue **demanda**, **planeación** y **ejecución**.

- Demanda: pedido, identidad de línea y revisiones de cantidades/producto/destino.
- Planeación: cuánto se surtirá desde cada almacén y cuánto viajará a cada parada.
- Ejecución: cantidades realmente confirmadas, recibidas, contenidas en HU y cargadas.
- Evidencia: archivo de origen, usuario, comando, evento, incidencia, autorización y auditoría.

Un pedido no se reduce a una fila con un estado. Puede tener varias líneas, algunas pendientes, otras empacadas y otras embarcadas en diferentes viajes.

El cliente comercial y su destino físico son entidades diferentes. El viaje y el tráiler también: la misma unidad física puede usarse en múltiples viajes a lo largo del tiempo.

**Alcance operativo propuesto:** una organización operadora, varios almacenes y destinos, un almacén de salida por viaje, varias paradas, artículos por cantidad y lote opcional. No se implementan aquí múltiples empresas aisladas, serialización individual, inventario integral, GPS, prueba de entrega, offline ni optimización de rutas. Se identifican puntos de extensión.

## 3. Módulos y entregas

| Módulo | Responsabilidad | Tablas |
| --- | --- | --- |
| security | Usuarios, roles, permisos y acceso a almacenes | 6 |
| platform | Versión de esquema e idempotencia de comandos | 2 |
| catalog | Puntos, direcciones, almacenes, ubicaciones, clientes, materiales y HU | 14 |
| integration | Formatos, archivos, intentos, staging y errores | 8 |
| operations | Pedido, revisiones, líneas y asignaciones de surtido | 5 |
| planning | Distancias, transportistas, unidades, choferes, viajes, paradas y cantidades | 8 |
| warehouse | Picking, recepción, HU, movimientos y reversiones | 10 |
| shipping | Asignaciones de carga, eventos y cierre | 4 |
| quality | Incidencias, bloqueos y autorizaciones | 5 |
| audit | Historial de acciones y resultados | 1 |
| **Total** | **Modelo completo propuesto, no primer incremento** | **63** |

Cada tabla pertenece a una entrega en el diccionario:

1. Catálogos mínimos, seguridad, importación, pedidos y trazabilidad.
2. Planeación y Picking, incluyendo controles de incidencias y excepciones.
3. Recepción de Packing, HU y preembarque.
4. Carga, cierre, consulta del chofer y consolidación de supervisión.

Las 68 tablas no se crean juntas. La entrega de una tabla indica su primera versión, no que todos sus campos finales se incorporen entonces. Los catálogos de tráiler, transportista y chofer se preparan en la entrega 2 para referenciarlos en el plan. Incident, Hold y Approval nacen con referencias a objetos de la entrega 2; las columnas/FKs a HU se agregan en la 3 y las de Shipment en la 4, actualizando sus CHECK de contexto. Nunca crear una FK hacia una tabla inexistente. La primera migración puede limitarse al control de versión; luego un incremento de catálogos/pedidos/importación. Cada conjunto se entrega con sus dependencias, pruebas y auditoría. No se crean tablas vacías de funciones futuras para aparentar cobertura.

## 4. Relaciones que evitan rediseños frecuentes

- Un cliente tiene varios destinos. Un destino mantiene su identidad aunque cambie de dirección.
- Un punto logístico tiene varias versiones de dirección; planes y distancias fijan la versión utilizada.
- Un almacén tiene muchas ubicaciones; un material admite varias ubicaciones y viceversa.
- Un pedido tiene muchas líneas. La misma referencia de material puede aparecer más de una vez.
- Una línea tiene revisiones, manteniendo su identidad externa estable.
- Una línea puede tener varias asignaciones de surtido, cada una en un almacén.
- Una asignación se distribuye entre varias paradas mediante TripAllocation, con cantidades explícitas.
- Un viaje tiene revisiones de plan y cada revisión muchas paradas. Visitar dos veces el mismo destino genera dos paradas.
- Una tarea tiene detalles; cada detalle refiere una asignación, ubicación y lote.
- Un detalle admite varias confirmaciones parciales. Una confirmación admite varias recepciones parciales.
- Una recepción puede alimentar varias HU. Una HU puede contener aportes de varias recepciones compatibles.
- Una HU pertenece a un destino y un almacén; su asignación a una parada es posterior.
- Una HU solo tiene una asignación activa de embarque. Su historia de asignaciones se conserva.
- Un viaje tiene un embarque en la primera versión. Embarque cerrado no significa entrega al cliente.

No hay columnas Producto1/Producto2, Cliente1/Cliente2 ni listas de IDs separadas por comas. Las relaciones muchos a muchos llevan tablas puente.

## 5. Convenciones y tipos

- PK internas bigint estables, autogeneradas. No usar número de pedido, matrícula ni posición de pantalla como PK.
- Claves externas se guardan como texto para conservar ceros y prefijos. Su ámbito de unicidad es explícito.
- Nombres técnicos en inglés; descripciones y documentación en español.
- Texto Unicode nvarchar. Tamaños propuestos se validarán contra muestras antes de crear tablas.
- Cantidades decimal(19,6), factores decimal(28,12), distancias decimal(12,3). No usar float para cantidades operativas.
- Unidad base por material; cada revisión conserva unidad solicitada, factor y cantidad base. Verificar rango, escala y conversión exacta antes de aceptar; no truncar ni redondear automáticamente.
- Cero no representa dato desconocido. Fecha, distancia, lote o conductor desconocidos usan NULL cuando el proceso lo permite.
- Fechas de eventos datetime2(3) en UTC, generadas por el servidor. Fecha requerida es date con significado de negocio por confirmar. Ventanas semanales usan hora local y zona del destino; citas concretas se guardan en UTC.
- RowVersion detecta edición concurrente; **no contiene fecha ni es una PK**. Su comprobación no reemplaza el control de sumas entre filas. [Microsoft: rowversion](https://learn.microsoft.com/en-us/sql/t-sql/data-types/rowversion-transact-sql?view=sql-server-ver17).
- CHECK para valores locales y estados permitidos. Catálogos cerrados de estados se amplían por migración revisada, no por texto libre.
- Normalizar códigos antes de aplicar UQ: espacios exteriores, mayúsculas/minúsculas y collation acordadas. No eliminar ceros o caracteres significativos.
- Registros históricos no se borran para corregirlos. Catálogos usados se desactivan; hechos se revierten o reciben otra versión.
- No CASCADE DELETE en pedidos, ejecución, cargas, incidencias o auditoría. FKs con NO ACTION; borrado de staging solo bajo retención controlada y sin perder trazabilidad.
- CreatedAtUtc común. UpdatedAtUtc y RowVersion en objetos editables. Los nombres de todos los campos y sus nullabilidades están en el diccionario.

La instalación mantendrá una sola identidad de aplicación y su versión; las credenciales/servidor/base siguen en configuración privada del backend. El esquema no contiene una tabla de contraseñas SQL.

## 6. Invariantes de cantidades

Todas las comparaciones se realizan en unidad base, por identidad de línea, asignación, detalle o recepción según corresponda. Para sumar productos diferentes se necesita agrupación por material/unidad; no sumar PZA y KG en un mismo total físico.

Definiciones:

- Demanda vigente: RequiredBaseQuantity de la revisión vigente de una línea, o cero si se cancela válidamente.
- Asignado: suma de AllocatedBaseQuantity en asignaciones no canceladas, **incluidas las completadas**.
- Picking neto: suma de confirmaciones sin PickReversal.
- Recibido neto: suma de PackingReceipt sin ReceiptReversal.
- Empacado neto: suma de HandlingUnitItem sin PackingReversal.
- Compromiso de viaje: PlannedBaseQuantity menos CancelledBaseQuantity.
- HU comprometida en viaje: contenido neto de HU con ShipmentUnit ASSIGNED, LOADED o DISPATCHED y sin liberar.

Reglas obligatorias:

1. Por línea, 0 <= asignado <= demanda vigente.
2. Por asignación, total de cantidades planeadas de detalles de Picking no cancelados <= cantidad asignada.
3. Por detalle, 0 <= Picking neto <= cantidad planeada.
4. Por confirmación, recibido neto <= cantidad confirmada no revertida.
5. Por recepción, empacado neto <= recibido neto.
6. Por asignación, suma de compromisos de viaje, **incluidos los ya completados**, <= cantidad asignada.
7. Por combinación asignación/parada, contenido de HU comprometido <= compromiso neto de TripAllocation.
8. El material, lote, destino y almacén se mantienen compatibles en toda la cadena.
9. Una HU SHIPPED mantiene código, contenido, asignación y vínculo de cierre; no se vuelve a usar para un nuevo embarque.
10. Ninguna reducción, cancelación o revisión puede dejar un límite por debajo de sus cantidades consumidas o comprometidas.

Los disponibles para cada paso son **diferencias calculadas** entre cantidades del mismo ámbito. No persistir cantidades restantes en múltiples tablas independientes sin mecanismo transaccional de conciliación. Las vistas de avance serán derivadas; una caché futura tendrá reconciliación explícita.

No existe todavía inventario físico autoritativo por ubicación. Picking conoce lo pedido y lo confirmado, no el saldo total del almacén.

## 7. Importación, identidad y actualización

1. Recibir el archivo bajo un nombre/ruta internos, limitar tamaño y comprobar codificación.
2. Conservar bytes y hash SHA-256 en ImportedFile. Nombre cambiado no evita la detección del mismo contenido.
3. Registrar intento con el perfil y versión exactos. ImportRow conserva registro lógico, líneas físicas, texto y valores interpretados.
4. Validar estructura y datos antes de escribir operación. Código desconocido se rechaza o queda pendiente; no crear catálogos silenciosamente.
5. Agrupar por pedido. Propuesta: aplicar cada pedido completo en una transacción; un pedido inválido no impide procesar otro válido del archivo.
6. Clave del pedido = SourceSystem + ExternalOrderNumber. Clave de línea = pedido + ExternalLineKey estable, incluida sublínea si el origen la usa.
7. Si no existe clave estable de línea y el material se repite, detener la aplicación del pedido; no inferir identidad por número de fila.
8. Comparar contenido normalizado con la revisión vigente. Igual implica UNCHANGED. Distinto exige evaluar la versión del origen y las operaciones iniciadas.
9. Sin número/fecha confiable de versión del origen, cualquier actualización distinta requiere revisión manual. Archivo recién recibido no significa información más nueva.
10. Revisión aceptada y vínculos de resultado se confirman juntos. Un reintento consulta resultados aplicados y no repite cantidades.
11. Un archivo duplicado genera intento DUPLICATE. Un intento fallido puede reintentarse de forma autorizada, conservando perfil/versiones y aplicando solo pedidos pendientes.
12. No interpretar filas omitidas como cancelación hasta acordar si el archivo es snapshot completo o delta.

Excepción controlada a solo-anexado: durante el procesamiento se completan ParsedJson, Status y AppliedOrderLineId de ImportRow bajo el bloqueo/lease del intento. RawText y números de línea son inmutables. Tras terminar, no modificar el intento para ocultar errores; registrar otro intento.

Los cambios a material/destino/unidad de una línea ejecutada se rechazan y requieren una línea nueva con tratamiento del remanente. Cambios de cantidad deben respetar todos los compromisos existentes. Una autorización no permite saltar la conservación de cantidades.

## 8. Planeación, rutas y distancias

La asignación de surtido decide **almacén y cantidad**. TripAllocation decide **cantidad, viaje y parada**. Separarlas permite conservar la trazabilidad física aunque el pendiente viaje otro día.

Distancia se identifica por origen y destino versionados. Puede faltar; no se transforma NULL en cero. Un viaje usa origen -> primera parada -> segunda parada y así sucesivamente, no la suma de todas las distancias desde el almacén.

Las distancias son referencias con fuente y vigencia. No son cálculo automático de rutas, GPS o ETA garantizada. El supervisor aprueba el orden teniendo en cuenta requisitos reales.

Aprobar un plan congela su revisión y paradas. Cambiar el orden antes de cargar requiere:

- Nueva revisión con paradas nuevas y comprobadas.
- Identificar todas las cantidades aún comprometidas en el plan anterior.
- Liberar compromisos no consumidos y crear los correspondientes en el nuevo plan.
- Reasignar HU no cargadas con autorización y validación, conservando su historia.
- Actualizar la revisión vigente y auditar la transición en una transacción.
- Rechazar el cambio si cualquier embarque ya inició carga, hasta definir un flujo formal de corrección.

El orden inverso de carga se deriva de la secuencia aprobada de paradas. No se guarda un segundo orden independiente que pueda contradecirla. Una excepción requiere aprobación explícita; el acomodo físico y la seguridad no se calculan automáticamente.

## 9. HU, reempaque y movimientos

Una HU identifica contenido trazable, no un recipiente físico reutilizable indefinidamente. Si el negocio necesita una tarima retornable como activo, se agrega otro catálogo de activos sin reciclar el código de la HU.

Propuesta inicial: se permite mezclar materiales/lotes/líneas del mismo destino y almacén. Al asignar la HU a un viaje, todos sus aportes deben tener cantidades disponibles en el compromiso de esa parada. No mezclar visitas diferentes a un mismo destino en una HU que deba descargarse separadamente.

La cantidad y el origen de un aporte confirmado no se editan. Para reempacar:

1. HU sin cargar ni asignación activa; reabrir si estaba empacada, con permiso y motivo.
2. Revertir por completo los aportes que cambiarán.
3. Crear los aportes correctos en la misma HU u otras HU.
4. Comprobar conservación de cantidades y compatibilidad de destino/almacén.
5. Confirmar todo en una transacción y volver a liberar el Packing.

Una corrección parcial usa reversión completa más nuevos aportes válidos. No hay cantidades negativas de operación; las reversiones están tipadas y solo pueden referir el original una vez.

CurrentLocationId es una proyección transaccional de ubicación vigente, con historial de movimientos. Al cargar pasa a NULL y la ubicación se identifica por ShipmentUnit/Shipment/Trailer. No inventar una ubicación de almacén para el tráiler. Una descarga correctiva antes del cierre registra LoadEvent UNLOAD y posición de destino.

## 10. Embarque, cierre y parciales

Al asignar HU: validar destino/parada, cantidad comprometida, almacén, HU empacada/liberada y ausencia de otra asignación activa.

Al cargar: verificar estado, ubicación vigente, ausencia de bloqueos, orden de carga y permisos. Insertar LoadEvent y cambiar estados de HU/asignación en la misma transacción.

Al descargar por corrección: exigir embarque abierto, motivo y ubicación válida. No borrar el evento LOAD. Descargar no autoriza automáticamente a cambiar el destino o contenido.

Al cerrar: bloquear el embarque y sus asignaciones, comprobar todas las HU, su contenido, pendientes y bloqueos, guardar instantánea del manifiesto y actualizar estados juntos. Ningún operador puede cargar mientras otro cierra.

Para cierre parcial autorizado:

- Lo cargado conserva su destino, cantidades e historia.
- HU no cargadas se liberan explícitamente de la asignación.
- TripAllocation libera únicamente la cantidad no consumida, aumentando CancelledBaseQuantity.
- Ese remanente puede comprometerse en otro viaje sin reescribir Picking o Packing.
- Ningún pendiente desaparece ni se declara embarcado automáticamente.
- Approval se consume con el cierre, con versión y parámetros aprobados.

El criterio exacto para admitir parciales y sello obligatorio queda pendiente de negocio. Por defecto, bloquear el cierre que incumpla el plan. No se propone reapertura después de cierre; devoluciones o ajustes posteriores necesitan su módulo.

## 11. Estados, bloqueos e incidencias

No mezclar todos los fenómenos en una sola columna de estado.

- Etapa: avance de tarea, HU o embarque.
- Condición: bloqueo activo, daño, faltante u otra incidencia.
- Completitud: ninguna/parcial/completa, calculada a partir de cantidades.

Por eso SHORTAGE o DAMAGED son incidencias; HOLD se representa como bloqueo independiente; PARTIAL se calcula o se registra en un cierre autorizado. Una HU empacada puede seguir empacada y a la vez bloqueada.

Transiciones base:

| Objeto | Recorrido normal | Cancelación/corrección |
| --- | --- | --- |
| Pedido | CREATED -> RELEASED -> IN_PROGRESS -> COMPLETED | CANCELLED solo al resolver todo compromiso; progreso mixto se consulta por línea |
| Asignación | DRAFT -> RELEASED -> IN_PROGRESS -> COMPLETED | CANCELLED si ejecución neta cero y compromisos liberados |
| Tarea | OPEN -> ASSIGNED -> IN_PROGRESS -> COMPLETED | Cancelar únicamente pendiente sin ejecución; reasignación con auditoría |
| HU | OPEN -> PACKED -> STAGED -> LOADED -> SHIPPED | Reapertura autorizada antes de asignar/cargar; VOID si vacía y sin compromisos |
| Viaje | DRAFT -> RELEASED -> LOADING -> CLOSED | Cancelar antes de carga con liberación de dependencias |
| Embarque | OPEN -> LOADING -> CLOSED | CANCELLED solo sin HU comprometida |
| Asignación de HU | ASSIGNED -> LOADED -> DISPATCHED | UNLOAD vuelve a ASSIGNED; RELEASED conserva historia |
| Incidencia | OPEN -> INVESTIGATING -> RESOLVED | CANCELLED con motivo |
| Autorización | PENDING -> APPROVED/REJECTED/EXPIRED | Aprobada se consume una vez por operación |

Estados resumidos de pedido se actualizan junto con el agregado o se calculan, nunca solo por el último evento recibido. Las transiciones tendrán pruebas de cada salto permitido y prohibido.

Un bloqueo de línea afecta la carga de toda HU que la contenga. Resolver la incidencia no libera el bloqueo por sí solo. Hay que indicar quién puede liberar y con qué evidencia.

## 12. Integridad, concurrencia y reintentos

Tres capas complementarias:

| Capa | Responsabilidad |
| --- | --- |
| SQL Server | PK, FK simples/compuestas, NOT NULL, UQ, CHECK locales, unicidad filtrada y atomicidad |
| Servicio Python/FastAPI | Permisos, compatibilidad de contexto, estados, sumas entre tablas, versiones y orden de operaciones |
| Flutter | Ayuda de captura y mensajes; vuelve a consultar el resultado real, sin decidir reglas críticas |

Un CHECK local no demuestra que la suma de muchas confirmaciones esté bajo el límite de otra tabla. Esas reglas requieren transacción y serialización del ámbito afectado. SQL Server documenta que concurrencia, aislamiento y bloqueos deben tratarse explícitamente. [Microsoft: guía de bloqueos y versiones](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide?view=sql-server-ver17).

Patrón de una confirmación:

1. Validar usuario y estructura del comando.
2. Iniciar transacción y adquirir el ámbito de idempotencia.
3. Serializar el agregado afectado; por ejemplo línea/asignación para nuevas reservas de trabajo, detalle para Picking, recepción para Packing, HU para asignación/carga.
4. Releer cantidades, permisos/alcance y bloqueos dentro de la misma operación.
5. Validar versión esperada y reglas de transición.
6. Insertar hechos, actualizar proyecciones y registrar auditoría y resultado idempotente.
7. Confirmar y devolver resultado.
8. Si se pierde la respuesta, consultar o repetir la misma clave y obtener el resultado ya confirmado.

Para acciones que afectan varios agregados, definir orden global de bloqueo y ordenar IDs: línea -> asignación -> tarea/detalle -> confirmación/recepción -> HU -> viaje/embarque. Cierre y carga deben seguir el mismo protocolo, con estrategia específica de adquisición sin ciclos; validar con pruebas de competencia, no asumir que basta enumerar tablas. No usar NOLOCK para tomar decisiones de cantidad.

Idempotencia evita repetir un mismo comando; no evita que dos claves distintas excedan un límite. Ambos controles son necesarios. RowVersion evita sobreescrituras pero no serializa por sí sola inserciones hijas: tocar/bloquear el agregado cuando cambian cantidades o compromisos.

Deadlock o conflicto de versión: rollback completo, reintento acotado y mismos parámetros/clave cuando sea seguro. No repetir operaciones externas dentro de una transacción SQL. Las notificaciones/integraciones futuras requerirán patrón de salida transaccional.

Unicidad activa de HU, chofer asociado y tráiler ocupado se documenta con índices filtrados. Las FKs no crean automáticamente todos los índices de consulta necesarios. [Microsoft: índices filtrados](https://learn.microsoft.com/en-us/sql/relational-databases/indexes/create-filtered-indexes?view=sql-server-ver17), [Microsoft: claves primarias y foráneas](https://learn.microsoft.com/en-us/sql/relational-databases/tables/primary-and-foreign-key-constraints?view=sql-server-ver17).

## 13. Compatibilidades que deben verificarse en transacción

Además de las FKs compuestas listadas en el diccionario:

- DeliverySite.CustomerId coincide con SalesOrder.CustomerId.
- Cada PointAddress corresponde al punto del almacén o destino vinculado.
- MaterialLot.MaterialId coincide con el material de la línea.
- Tarea, origen, asignación, puesto de Packing, HU y andén comparten almacén.
- La conversión pertenece al material y unidad utilizados.
- Todo contenido HU comparte su destino.
- Todo aporte asignado a una parada tiene compromiso suficiente en TripAllocation.
- El perfil de importación pertenece al mismo origen que el archivo.
- Una revisión nueva de pedido incluye todas las líneas activas según el contrato de snapshot; cancelaciones explícitas preservan identidad.
- Caducidad/bloqueo de lote y permisos de usuario se evalúan al liberar/confirmar, según la política acordada.
- ParentLocationId no crea ciclos; unicidad no detecta un ciclo de varios niveles.

Estas reglas no están mágicamente impuestas por el dibujo. Deben implementarse en los servicios compartidos y proteger el acceso SQL directo con una cuenta operativa de mínimos privilegios.

## 14. Índices y consultas previstas

Además de PK/UQ, proponer índices sobre FKs usadas en navegación y filtros reales:

- Pedidos por origen/número y líneas por pedido.
- Revisiones por pedido/número; requisitos por material/destino/fecha.
- Asignaciones por línea/estado y almacén/estado.
- Tareas por almacén/operador/estado; detalles por tarea/asignación.
- Confirmaciones por detalle; recepciones por confirmación; contenido por recepción y HU.
- Reversiones con UQ al original.
- Paradas por revisión/orden; compromisos por asignación/parada.
- HU por almacén/estado/ubicación; asignaciones de HU por embarque/parada/estado.
- Incidencias por contexto/estado; bloqueos activos por cada objeto.
- Intentos por archivo/estado; errores por intento/fila.
- Auditoría por objeto/fecha y correlación, evitando indexar JSON completo.

No indexar cada campo ni crear stored procedures por rutina. Confirmar índices con volúmenes, planes y consultas reales. El tablero consultará vistas de avance por pedido, HU, viaje e incidencias; no necesita una tabla Dashboard con totales editables.

## 15. Seguridad, historia y recuperación

- Cuenta de instalación distinta de cuenta operativa cuando el entorno lo permita.
- Autorización en FastAPI por operación y almacén; el chofer solo ve sus viajes y el orden antes de salida.
- Contraseñas de aplicación con hash apropiado; credenciales SQL y firma de tokens fuera de tablas/repositorio.
- Historial de hechos sin UPDATE/DELETE desde el rol operativo; correcciones mediante tablas de reversión.
- Auditoría no puede declararse inviolable frente a un administrador de SQL. Una exigencia de evidencia contra manipulación necesitaría controles adicionales.
- Respaldos de SQL y archivos originales, retención y restauración ensayada. Un esquema no garantiza continuidad por sí mismo.
- No guardar PII innecesaria de conductores. Definir acceso y plazos de conservación de datos.
- Timestamps del servidor, correlación del comando y usuario en las acciones críticas.
- Migraciones incrementales, checksum y comprobación de compatibilidad; prueba de actualización sobre una copia y procedimiento de recuperación. No borrar/recrear producción para instalar una versión.
- Cambiar instancia o nombre en configuración no traslada datos.

## 16. Ejemplo de conservación

Ejemplo ficticio de una línea de **100 PZA**:

1. Se asignan 60 al almacén A y 40 al B: comprometido de surtido = 100.
2. Desde A, se planean 30 en un viaje y 30 en otro. Desde B, 40 en un tercero.
3. Se confirman 60 en A y se reciben 60 en Packing.
4. Se empacan 30 y 30 en HU separadas, ambas trazables a sus recepciones.
5. Una HU se carga al primer viaje y la otra al segundo, consumiendo 30 de cada compromiso.
6. Los 40 de B siguen pendientes; el pedido no se marca completamente embarcado.
7. Repetir la confirmación de 60 con la misma clave devuelve el resultado anterior.
8. Confirmar otros 60 con una clave nueva se rechaza por exceder el límite.
9. Si en el primer viaje solo salen 20, debe existir separación física y documental de HU, liberación autorizada de 10 del plan y otro compromiso para el remanente. No se cambia el manifiesto para simular que salieron 30.

## 17. Revisión antes de generar SQL

La validación estructural realizada verifica nombres de tablas/campos, existencia y tipos de FKs, destinos únicos de referencias compuestas y representación coherente en los archivos. El archivo DBML fue analizado correctamente con @dbml/core 10.2.0 usando dbmlv2: 68 tablas. Se revisó visualmente el diagrama general. **No equivale a probar restricciones en SQL Server ni concurrencia real.**

Antes de aprobar DDL:

1. Resolver las decisiones bloqueantes del documento de decisiones.
2. Revisar el modelo entre las dos personas usando los escenarios.
3. Generar una primera migración pequeña, con CHECK/índices/FKs y permisos explícitos.
4. Ejecutar pruebas de integridad y competencia en una base desechable.
5. Comprobar reversión/corrección, reintento, restauración y migración sin pérdida.
6. Ajustar con datos reales y aprobación del negocio, sin cambiar el stack.

El diseño queda listo para esa revisión, no marcado como aprobado por el cliente.


Actualización 0.2: las tablas de capacidad diaria complementan este diseño; consultar [capacidad diaria](capacidad-diaria.md). La implementación inicial SQL está en database/migrations; las reglas agregadas de operación siguen pendientes en el backend.
