# Matriz de casos del esquema de datos

Versión 0.1 · 27 de septiembre de 2026. Estos son **criterios de aceptación para pruebas futuras**, no pruebas SQL ejecutadas. Cada caso requiere preparar datos, ejecutar la acción, comprobar el resultado y verificar que los datos prohibidos no se persistieron.

Para concurrencia usar conexiones SQL independientes y barreras de sincronización, no llamadas secuenciales. Repetir idempotencia con la misma clave y competencia con claves distintas. Para transacciones simular fallos antes y después de commit y revisar también auditoría/resultado.

| Caso | Área | Condición | Resultado esperado | Protección propuesta |
| --- | --- | --- | --- | --- |
| C001 | Importación | Mismo archivo con nombre distinto | Hash por origen detecta repetición; registra intento DUPLICATE, cero pedidos nuevos. | UQ ImportedFile + servicio |
| C002 | Importación | Mismo nombre, contenido distinto | Conservar ambos contenidos; evaluar claves y revisiones antes de aplicar. | ImportRun + revisiones |
| C003 | Importación | Archivo vacío o demasiado grande | Rechazar con motivo antes de procesar; no éxito falso. | Servicio + auditoría |
| C004 | Importación | Codificación o fecha ambigua | Error de formato con perfil explícito; no adivinar. | MappingProfileVersion |
| C005 | Importación | Columnas faltantes o repetidas | Rechazar estructura; informar campos y conservar original. | ImportError |
| C006 | Importación | Texto entrecomillado con saltos de línea | Mantener registro lógico y líneas físicas de inicio/fin correctos. | ImportRow |
| C007 | Importación | Cantidad negativa, cero o fuera de rango | Rechazar pedido; no truncar, desbordar ni cambiar signo. | Validación + CHECK |
| C008 | Importación | Código con ceros iniciales | Conservar identidad como texto. | Tipos nvarchar |
| C009 | Importación | Producto repetido en líneas distintas | Aceptar si las claves externas son diferentes. | UQ por pedido/línea |
| C010 | Importación | Una clave de línea duplicada con datos distintos | Rechazar el pedido completo. | Validación de grupo |
| C011 | Importación | Falta identificador estable de línea | Bloquear aplicación hasta resolver contrato; no usar fila como clave. | D01 |
| C012 | Importación | Un pedido válido y otro inválido | Aplicar el primero y rechazar el segundo; informar PARTIAL. | Transacción por pedido |
| C013 | Importación | Una fila inválida de un pedido | No crear un pedido incompleto silenciosamente. | ImportOrderResult |
| C014 | Importación | Archivo antiguo llega después del nuevo | No retroceder automáticamente una revisión. | Versión/fecha de origen + aprobación |
| C015 | Importación | Hash de negocio igual a revisión vigente | Resultado UNCHANGED; no agregar cantidades. | OrderRevision |
| C016 | Importación | Material o destino desconocido | Registrar error sin crear catálogo implícito. | FK + servicio |
| C017 | Importación | Caída al aplicar un pedido | Pedido/revisión/resultado todo confirmado o todo revertido. | Transacción |
| C018 | Importación | Dos trabajadores procesan el mismo archivo | Uno adquiere control; token vencido no puede continuar escribiendo. | Lease + cercado + UQ |
| C019 | Importación | Reintento tras aplicar algunos pedidos | Reconocer aplicados y procesar pendientes sin duplicarlos. | Resultados + idempotencia de importación |
| C020 | Catálogos | Destino de otro cliente | Rechazar relación antes de publicar pedido. | Compatibilidad transaccional |
| C021 | Catálogos | Ubicación padre de otro almacén | FK compuesta impide enlace. | FK Location |
| C022 | Catálogos | Ciclo A->B->C->A de ubicaciones | Rechazar actualización. | Servicio dentro de transacción |
| C023 | Catálogos | Desactivar ubicación con trabajo abierto | Impedir hasta resolver dependencias. | Servicio + permisos |
| C024 | Catálogos | Cambiar dirección tras aprobar viaje | Crear nueva versión; viaje existente conserva dirección antigua. | PointAddress |
| C025 | Catálogos | Mismo lote asociado a otro producto | Rechazar Picking incoherente. | MaterialLot + servicio |
| C026 | Catálogos | Cambiar unidad base con historia | Bloquear edición directa. | Material + migración |
| C027 | Cantidades | Fracción en unidad indivisible PZA | Rechazar por escala; no redondear. | UnitOfMeasure |
| C028 | Cantidades | Conversión de caja diferente por material | Aplicar factor correspondiente y conservarlo en revisión. | MaterialUnitConversion |
| C029 | Cantidades | 100 requeridos y 60+50 asignados | Rechazar exceso por línea. | Transacción sobre línea |
| C030 | Cantidades | Disminuir pedido por debajo de asignado/ejecutado | Rechazar revisión hasta resolver compromisos. | Revisión + invariantes |
| C031 | Planeación | Mismo cliente con dos plantas | Mantener destinos y direcciones separados. | DeliverySite |
| C032 | Planeación | Dos visitas al mismo destino | Permitir StopId diferentes con secuencias distintas. | TripStop |
| C033 | Planeación | Dos paradas con igual secuencia | Impedir duplicidad. | UQ revisión/secuencia |
| C034 | Planeación | Sin distancia entre dos puntos | Mostrar desconocida; no tratar como cero. | NULL explícito |
| C035 | Planeación | Distancia B->A diferente de A->B | Conservar ambas referencias direccionales. | DistanceReference |
| C036 | Planeación | Dirección modificada con distancia antigua | No reutilizar tramo de otras versiones sin validación. | Referencias a PointAddress |
| C037 | Planeación | Distribuir 60 entre viajes de 30 y 40 | Rechazar compromiso total de 70. | TripAllocation + transacción |
| C038 | Planeación | Asignación de almacén A en viaje que sale de B | Rechazar incompatibilidad. | Servicio |
| C039 | Planeación | Cambiar orden de ruta con HU comprometidas | Nueva revisión y migración atómica de remanentes; mantener historia. | Plan versionado |
| C040 | Planeación | Cambiar ruta cuando ya inició carga | Rechazar hasta definir procedimiento autorizado específico. | Estado congelado |
| C041 | Picking | Dos operadores confirman 60 sobre pendiente 100 | Solo una combinación <=100 se confirma; la otra recibe conflicto. | Bloqueo agregado + suma |
| C042 | Picking | Repetir misma clave de confirmación | Devolver mismo resultado; una sola confirmación. | OperationRequest UQ |
| C043 | Picking | Reusar clave con cantidad distinta | Rechazar por hash diferente. | Idempotencia |
| C044 | Picking | Respuesta perdida después del commit | Consultar/reintentar devuelve éxito original; no duplicar. | Resultado persistido |
| C045 | Picking | Usuario sin acceso al almacén | Rechazar aunque tenga rol de Picking. | UserWarehouse + Permission |
| C046 | Picking | Ubicación/material/lote distinto al asignado | Rechazar y permitir registrar incidencia. | Servicio |
| C047 | Picking | Cancelar detalle con cantidad confirmada | Rechazar hasta corregir dependencias. | Estado + neto |
| C048 | Picking | Revertir confirmación ya recibida en Packing | Rechazar hasta reversar recepción sin dependencias. | Regla de reversión |
| C049 | Packing | Recibir 120 cuando se confirmaron 100 | Rechazar exceso por confirmación. | Transacción |
| C050 | Packing | Empacar la misma recepción en dos HU simultáneas | La suma confirmada nunca excede lo recibido. | Bloqueo recepción |
| C051 | Packing | Mezclar destinos en una HU | Rechazar aporte incompatible. | HU + trazabilidad de recepción |
| C052 | Packing | Dividir una recepción en varias HU | Aceptar conservando cantidades y origen. | HandlingUnitItem |
| C053 | Packing | Reempacar una HU ya cargada | Rechazar; no alterar carga histórica. | Estado + asignación |
| C054 | Packing | Reempacar 30 como 10 y 20 | Reversión del original y nuevos aportes atómicos. | PackingReversal |
| C055 | Packing | Revertir dos veces el mismo aporte | Impedir segundo registro. | UQ de reversión |
| C056 | Packing | Revertir recepción con contenido HU vigente | Rechazar mientras exista cantidad empacada neta. | Conservación |
| C057 | Preembarque | Mover HU entre almacenes como movimiento interno | Rechazar; requiere transferencia futura. | Compatibilidad de Warehouse |
| C058 | Preembarque | Dos movimientos simultáneos de la misma HU | Uno falla por origen/versión; una ubicación vigente. | RowVersion + transacción |
| C059 | Carga | Asignar una HU a dos embarques | Solo una asignación activa. | UQ filtrado HU |
| C060 | Carga | Dos embarques abiertos sobre mismo tráiler | Rechazar el segundo. | UQ filtrado Trailer |
| C061 | Carga | Parada de una revisión diferente a la del embarque | Rechazar referencia. | FKs compuestas |
| C062 | Carga | HU del mismo destino pero sin cantidad comprometida en esa parada | Rechazar; destino igual no basta. | TripAllocation |
| C063 | Carga | Cargar HU inexistente, vacía, sin empacar o bloqueada | Rechazar y conservar incidencia si corresponde. | FK + estado + contenido + Hold |
| C064 | Carga | Repetir LOAD con otra clave cuando ya está cargada | Rechazar por estado; no segundo evento válido. | Serialización HU |
| C065 | Carga | UNLOAD antes de cierre | Registrar evento y ubicación destino; conservar LOAD previo. | LoadEvent |
| C066 | Carga | LOAD mientras otro usuario cierra el embarque | Una operación espera y revalida; no se carga después del cierre. | Protocolo transaccional común |
| C067 | Carga | Cargar fuera del orden aprobado | Bloquear salvo excepción válida del negocio. | Plan + Approval |
| C068 | Cierre | Cerrar con HU asignada sin cargar | Bloquear o resolver parcial explícitamente. | Criterio de cierre |
| C069 | Cierre | Parcial con 20 cargados y 10 pendientes | Cerrar 20 autorizados y liberar/replanear 10, sin marcarlos SHIPPED. | TripAllocation + Approval + manifiesto |
| C070 | Cierre | Repetir cierre tras perder respuesta | Misma acta; ninguna duplicación. | UQ ShipmentClosure + OperationRequest |
| C071 | Cierre | Descargar o editar contenido después de cierre | Rechazar; devolución/ajuste es proceso posterior. | Estados congelados |
| C072 | Calidad | Bloquear una línea dentro de HU mixta | Bloquear carga de HU hasta resolver o separar correctamente. | Hold transitivo |
| C073 | Calidad | Resolver incidencia sin liberar bloqueo | Bloqueo permanece activo. | Separación Incident/Hold |
| C074 | Calidad | Autorización vencida o con parámetros cambiados | Rechazar ejecución. | Hash + versión + caducidad |
| C075 | Calidad | Consumir aprobación dos veces | Solo una operación la utiliza. | Transacción + unicidad |
| C076 | Auditoría | Cambio operativo confirmado sin auditoría | Prueba debe fallar; ambos se guardan en la misma transacción. | Atomicidad |
| C077 | Auditoría | Borrar usuario/catálogo con hechos históricos | Impedir borrado; permitir desactivación. | FK NO ACTION |
| C078 | Seguridad | Guardar token/clave SQL en auditoría o manifiesto | Rechazar o redactar; pruebas de ausencia de secretos. | Control de payload |
| C079 | Recuperación | Deadlock o conflicto de edición | Rollback total y reintento acotado sin duplicar hechos. | Transacción + idempotencia |
| C080 | Recuperación | Respaldo SQL sin archivos originales | Detectar restauración incompleta; probar recuperación de ambos. | Procedimiento de respaldo |
| C081 | Migración | Mismo número de migración con checksum distinto | Detener actualización y exigir revisión. | SchemaMigration |
| C082 | Migración | Agregar relación obligatoria a datos existentes | Primero columna compatible/backfill/validación, luego NOT NULL/FK. | Migración expandir-validar-restringir |
| C083 | Consulta | Pedido en varias etapas simultáneas | Mostrar avance por cantidades/línea; no sobrescribir por último evento. | Vistas de avance |
| C084 | Consulta | Chofer consulta viaje de otro conductor | Rechazar aunque conozca el ID. | Permisos y relación Driver/User |
| C085 | Consulta | Pedido cerrado en almacén | No mostrarlo como entregado al cliente. | Definición de SHIPPED |

## Ejemplos obligatorios de conjunto

- Pedido de 100 PZA dividido 60/40 entre dos almacenes; la asignación de 60 repartida 30/30 entre dos viajes.
- Una línea con dos lotes: dos detalles de Picking, recepción y HU trazables al lote correcto.
- Dos líneas del mismo material y lote que no se mezclan por compartir código.
- Un viaje con paradas A, B, A; ambas visitas A son distintas para asignación y carga.
- Tres paradas A, B, C con carga C, B, A; demostrar excepción bloqueada/autorizada según regla acordada.
- Archivo válido, duplicado por bytes, modificado equivalente, actualización legítima y actualización antigua.
- Ciclo completo de corrección: Picking, recepción, Packing, reversión bloqueada por dependencia, corrección desde la última etapa hacia atrás.
- Parcial real con HU separadas físicamente: el manifiesto incluye solo lo cargado y el remanente sigue visible.

## Evidencia pendiente

Al implementarse registrar para cada caso: versión de migración/API, datos ficticios usados, resultado, consultas de invariantes, fallos observados y corrección. La revisión de documentos no sustituye estas pruebas ni la validación del negocio.
