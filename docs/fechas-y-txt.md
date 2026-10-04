# Fechas y archivo TXT de prueba

## Consultar fechas

Las listas administrativas permiten ordenar de más recientes a más antiguas, invertir el orden y marcar Fecha exacta. Todas las fechas quita la búsqueda por día. El filtro se conserva al actualizar.

- Hoy: la lista consulta todas las fechas programadas. Los indicadores superiores siguen referidos a hoy; no cambian con el filtro.
- Pedidos: fecha solicitada de entrega.
- Calendario y preparación: fecha programada.
- Tarimas e historial de empaque: fecha real de creación de la tarima en SQL (una tarima por confirmación de empaque en esta demo), no el día programado.
- Viajes: apertura del viaje; su lista de tarimas muestra fecha de empaque.
- Destinos: fecha de alta, no de entrega.
- Ver historial: fecha real de acción. Se consulta el historial completo de la demo, sin el anterior límite de 80 registros. El resumen de actividad conserva las últimas ocho acciones y lo indica.

Los registros sin fecha quedan al final y no coinciden con una búsqueda exacta. Los horarios reales se presentan en CDMX, UTC−06 para esta demo. Ordenar la consulta no cambia el orden obligatorio de carga. El operador conserva su flujo y no tiene selector de fecha.

## Importar TXT

En Pedidos, pulsar Importar CSV o TXT y seleccionar:
samples/txt/entregas_domingo_a_miercoles.txt

Texto UTF-8, encabezado y ocho columnas separadas por |. CSV sigue usando comas. No es todavía el contrato definitivo de SAP.

| Entrega solicitada | Producto | Piezas |
|---|---|---:|
| Domingo 4 de octubre de 2026 | Coca-Cola | 120 |
| Lunes 5 de octubre de 2026 | Sabritas | 240 |
| Martes 6 de octubre de 2026 | Ruffles | 180 |
| Miércoles 7 de octubre de 2026 | Coca-Cola | 360 |

Total: 900 piezas, cuatro pedidos con códigos DEMO-TXT-. Usa los catálogos ficticios existentes.

Importar no programa, recoge, empaca ni embarca automáticamente. Las fechas son de entrega solicitada: el planificador admite todos los días, incluidos domingos; la demo no retroprograma desde la fecha de entrega ni garantiza cumplimiento. Un pedido importado tarde conserva su fecha solicitada.

El archivo se probó en una base SQL aislada; no se importó automáticamente a la base de trabajo. Reimportarlo no duplica pedidos.

## Validación

44 pruebas backend (incluye importación TXT real, fechas domingo-miércoles y duplicado) y 16 pruebas de interfaz aprobadas. Las pruebas de fecha cubren ambos órdenes, día exacto, cruce UTC/CDMX, fechas vacías, actualización y limpieza del filtro. Se revisó captura del supervisor con SQL local.
