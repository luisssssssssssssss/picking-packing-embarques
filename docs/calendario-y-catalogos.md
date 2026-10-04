# Calendario y catálogos familiares · 3 de octubre de 2026

## Calendario del montacarguista

Abre en hoy, con fecha de Ciudad de México. No admite seleccionar ayer.
Hoy incluye tareas pendientes de días anteriores. Los días futuros son solo consulta: se ocultan confirmación, cantidad e incidencias. El endpoint del operador valida también la fecha antes de guardar, dentro de la transacción.
La pantalla cambia el mínimo de fecha al avanzar el día; los reintentos conservan su identidad para no duplicar movimientos.

El calendario muestra tareas PROGRAMADAS, no todas las entregas solicitadas en un archivo. Importar no planea automáticamente. Los atrasos se atienden desde hoy sin cambiar su fecha original.

## Dos almacenes independientes

- Almacén cuarto de Víctor: conserva el identificador del antiguo almacén demo y sus operaciones.
- Almacén cuarto de Huicho: nuevo almacén con ubicaciones y capacidad propias.

Coca-Cola, Sabritas y Ruffles se surten de Víctor; Doritos, agua Ciel y Gansito, de Huicho. La planeación toma la ubicación preferida del producto; no mueve tareas históricas a otro almacén. Cada almacén tiene su reserva de capacidad: 600 por almacén si se usa ese valor.
Packing y movimientos conservan el almacén de la tarea. Los viajes se preparan por almacén; no se mezclan tarimas de ambos. Se conserva un solo tráiler demo, por lo que debe cerrarse el viaje abierto antes del siguiente.

Todavía NO hay control de saldos físicos ni reservas de inventario. Dos almacenes independientes no implica que ya haya existencias capturadas.

## Nuevos clientes y destinos

La Ralde: 7 km. Oxxo: 1 km (última distancia mencionada). Salma: 20 km.
Para el ejemplo se registran esas distancias desde ambos almacenes, como datos ficticios; no se calculan por mapa. Los destinos anteriores se conservan. Las distancias y nombres de viajes ya creados no se reescriben.

## TXT legible

Usar samples/txt/pedidos_legibles.txt desde Pedidos → Importar CSV o TXT.
Se muestran primero QuienPidio, Producto, CantidadSolicitada, UnidadMedida, Destino, Almacen y FechaRequeridaEntrega. Al final quedan los identificadores necesarios para importar.
Los nombres se validan contra los códigos y la ubicación preferida. Cambiar solo el nombre no cambia el producto o el almacén: se registra error.

Contiene seis pedidos y 900 piezas, con entregas solicitadas del domingo 4 al miércoles 7 de octubre.
El archivo anterior sigue siendo compatible. Las fechas de entrega no son las fechas de preparación: el planificador trabaja todos los días, incluidos sábados y domingos.

Los catálogos se crean al iniciar la demo, sin borrar pedidos existentes. El TXT nuevo no se importa automáticamente en la base de trabajo.

## Verificación

47 pruebas backend y 17 de interfaz. Incluyen rechazo de día pasado, consulta futura sin confirmación, rechazo en servidor de picking futuro, importación legible, nombres inconsistentes, dos almacenes, rechazo de mezcla de tarimas y recorrido de 900 piezas en viajes separados. Captura visual del calendario del operador revisada.
