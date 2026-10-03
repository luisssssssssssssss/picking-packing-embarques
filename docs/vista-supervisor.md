# Supervisión diaria · demo de escritorio

Abrir **Iniciar Supervisor.cmd**, o pulsar **Supervisor** desde la vista del montacarguista. La sección **Hoy** se consulta sin capturar códigos.

## Lo que muestra

- Plan del día: piezas programadas y empacadas de esas tareas.
- Por recoger y listo para empacar: pendientes de hoy más atrasos; no incluye tareas futuras.
- Lista ordenada con pendientes primero, producto, destino, cantidad, siguiente paso y cuenta asignada.
- Pedidos con fecha de entrega de hoy o vencida que aún no se programaron.
- Capacidad reservada del día para picking; no es capacidad de packing.
- Últimas ocho confirmaciones operativas, tomadas de auditoría con fecha real.
- Actualización de lectura cada 10 segundos mientras la ventana esté visible y no haya otra operación o diálogo abierto. Si falla, se conservan los datos y se marca SIN ACTUALIZAR.

El calendario de esta demo usa Ciudad de México, UTC−06, para la operación de 2026. No depende de la zona del equipo. Antes de operar en otras zonas o manejar fechas históricas con cambio de horario, configurar zonas IANA con su base de reglas.

## Límites que no deben confundirse con funcionalidades terminadas

No hay saldos físicos de inventario: no se afirma que se pueda cumplir un pedido por tener capacidad. Tampoco hay sesiones individuales de operarios ni detección de presencia; la cuenta actual es compartida. La última confirmación prueba una acción guardada, no que alguien siga trabajando ahora. Asignación no significa ejecución.

Los atrasos se muestran para actuar; esta vista no los reprograma automáticamente. El empaque mostrado es el avance acumulado de las tareas del día programado, no la suma de eventos ocurridos ese día. Los indicadores pueden reflejar operaciones adelantadas en el simulador.

Para evaluar cumplimiento real faltan saldos disponibles por producto/ubicación, reservas, entradas/salidas y cuentas individuales. La app móvil sigue fuera de este incremento.

## Por qué existen 68 tablas

El diseño separa información que tiene vidas diferentes:

| Área | Tablas | Qué conserva |
|---|---:|---|
| Catálogos | 14 | Productos, clientes, destinos y ubicaciones |
| Planeación | 13 | Capacidades, calendario, rutas y viajes |
| Pedidos | 5 | Lo solicitado, sus revisiones y repartos |
| Almacén | 10 | Recogidas, empaques, unidades de manejo y movimientos |
| Embarques | 4 | Carga y cierre de salida |
| Importación | 8 | Archivo, procesamiento, validación y errores |
| Seguridad | 6 | Usuarios, roles y permisos |
| Calidad | 5 | Incidencias y seguimiento |
| Plataforma y auditoría | 3 | Operaciones, reintentos e historial |

Un pedido de 1,000 piezas puede planearse como 600 hoy y 400 mañana, empacarse en varias tarimas y salir en viajes diferentes. Separar registros permite conocer el pendiente sin sobrescribir la historia. No son 68 pantallas ni 68 pasos para el usuario.

El diseño anticipó más escenarios de los que utiliza la demo. No todas las tablas tienen uso activo y 68 no es una garantía de calidad. Conviene revisar las tablas todavía no utilizadas contra el proceso real antes de ampliar el modelo. Este cambio no agregó tablas ni migraciones.

## Cambios y verificación

Creados: servicio de resumen diario, panel de supervisión, pruebas de ambos y acceso Iniciar Supervisor.cmd.
Modificados: consultas de lectura, ventana administrativa, entrada desde operador y lanzador.
Pruebas: 41 backend (incluyen SQL en bases aisladas) y 13 interfaz, 54 aprobadas.
Se revisó visualmente la captura docs/pruebas/capturas/demo-supervisor.png.
Las mejoras se integran en main junto con la vista del montacarguista.

## Mejoras de acceso y seguimiento

- Botón principal para regresar a la pantalla del montacarguista.
- Filtro inicial Solo pendientes; opciones Listo para empacar y Todas las tareas. Se conserva al refrescar.
- Tarimas por llevar a salida, sin viaje y por cargar, considerando todos los días. Las cargadas y embarcadas no cuentan como pendientes.
- Validación de este incremento: 5 pruebas del resumen y 14 de interfaz aprobadas, más captura con SQL local.
