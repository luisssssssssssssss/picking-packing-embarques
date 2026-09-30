# Demo de escritorio — Python + FastAPI + SQL Server

Versión inicial funcional, 29 de septiembre de 2026. PySide6 se incorpora por la solicitud expresa de realizar también la interfaz de PC en Python. No se necesita Visual Studio/C++ para ejecutar esta demo.

## Abrir

Doble clic en **Iniciar Demo.cmd**, en la raíz del proyecto. Abre la aplicación nativa usando el entorno Python preparado.

Se generó también dist/AlmacenDemo/AlmacenDemo.exe, pero Windows bloqueó el binario reconstruido por su política de control de aplicaciones. El acceso de doble clic utiliza Python; no se modificaron esas políticas. La distribución como ejecutable firmado queda pendiente.

SQL Server debe estar encendido. Se utiliza backend/.env y una base cuyo nombre termina en _Dev o _Test. La aplicación se mantiene dentro del repositorio: necesita su configuración local y samples/csv/demo_escritorio.csv. No mover solamente el EXE, pues depende de su carpeta _internal.

El lanzador crea una API FastAPI en una dirección 127.0.0.1 y puerto libre. Usa un token aleatorio por sesión, sin contraseñas SQL en la interfaz. Al cerrar, termina su propio proceso API. Se puede volver a abrir y conservar el avance.

Si falla el inicio: ejecutar el diagnóstico de conexión y revisar .local/desktop-api.log. Nunca compartir backend/.env ni .local.

## Lo que encontrarás preparado

- Tres pedidos ficticios: 1,000, 350 y 250 piezas, para destinos A, B y C.
- Capacidad de picking de 600 piezas al día; cinco tareas repartidas en tres días laborables: 600, 600 y 400.
- 450 piezas recogidas, 300 empacadas en tres tarimas.
- Un viaje abierto con tres paradas; la tarima de la última parada ya está cargada.
- Evidencia de importación, planeación y movimientos guardada en las tablas existentes.

El escenario permite ver estados diferentes y continuar operándolo. No se reemplazan datos cuando se vuelve a abrir la aplicación.

## Recorrido simplificado

1. **Inicio:** un botón indica la siguiente acción pendiente. Abre la confirmación con el producto, tienda y cantidad completos; el usuario confirma cada movimiento.
2. **Pedidos:** crear un pedido con listas de productos y tiendas, 24 piezas sugeridas y fecha de mañana. El backend genera el CSV y lo pasa por el importador existente. También permite importar el ejemplo completo o seleccionar otro CSV.
3. En la misma sección se organiza la demanda por capacidad: 600 piezas/día sugeridas, fecha inicial editable y calendario de cantidades. Los días ya creados conservan su capacidad.
4. **Preparar productos:** recoger cantidades completas o parciales, empacar lo recogido y enviar la tarima al área de salida. La app completa los códigos para la simulación; esto no equivale a haber realizado un escaneo físico. El backend sigue validando códigos y cantidades.
5. **Destinos:** agregar o editar nombre y kilómetros desde el almacén. Los ejemplos iniciales son Oxxo Centro (5 km), Universidad (12 km) y Las Torres (25 km); son ubicaciones y distancias ficticias.
6. **Viajes:** revisar la propuesta de entrega por kilómetros de menor a mayor antes de crear el viaje. Ante empates se usa nombre y después identificador. La app selecciona automáticamente la siguiente tarima pendiente de la última parada. Se confirma la carga sin teclear códigos.
7. Al cargar todas las tarimas, **cerrar embarque** con sello sugerido. El resumen muestra productos, tiendas y piezas. Registra salida del almacén, no entrega al cliente.
8. **Ver historial:** acciones descritas en lenguaje cotidiano e incidencias.

Los productos son Coca-Cola 600 ml, Sabritas Original 45 g y Ruffles Queso 50 g. Una botella o bolsa cuenta como una pieza. Los códigos DEMO originales se conservan internamente. Se actualizaron solo las etiquetas ficticias originales del catálogo; los documentos históricos no se reescriben.

**Distancias:** se guardan referencias nuevas al editar kilómetros. Cada viaje nuevo conserva una copia de nombre, kilómetros y referencia dentro de las instrucciones de parada. Esta copia indica expresamente que la distancia parte del almacén, por lo que no se utiliza la columna de distancia desde la parada anterior. Se reutiliza el esquema actual, sin modificar migraciones aplicadas.

La distancia del almacén a cada tienda no permite calcular por sí sola los kilómetros entre tiendas ni la distancia total del viaje. No se implementa optimización vial. Los viajes anteriores conservan su secuencia y muestran sus distancias antiguas como tramos. La propuesta se invalida si las distancias cambian antes de confirmarla.

Las acciones se confirman mediante FastAPI. El panel vuelve a consultar SQL después de cada operación.

## Contrato de CSV de esta demo

NumeroPedido, LineaPedido, CodigoCliente, CodigoDestino, CodigoMaterial, CantidadSolicitada, UnidadMedida, FechaRequeridaEntrega.

UTF-8, separador coma, fechas YYYY-MM-DD, cantidades enteras positivas en PZA. Máximo 500 filas y 1 MB. Los catálogos permitidos están prefijados DEMO-. El backend interpreta el archivo; la interfaz solo permite seleccionarlo/previsualizarlo y enviarlo.

Se conserva el archivo recibido bajo .local/imports y se registra SHA-256. Cualquier error rechaza todos los pedidos de ese archivo y registra el diagnóstico. Esta política deliberada de todo o nada podrá evolucionar al recibir el archivo real.

## Qué demuestra y qué queda pendiente

Implementado: importación real a SQL, duplicados, planeación agregada de picking, cantidades parciales, HU, staging, viaje con varias paradas, carga inversa, cierre, manifiesto, incidencias y auditoría. Los comandos usan transacción y bloqueo; el mismo identificador no duplica una operación.

Es una simulación: un almacén, tres productos sin control de lote, un tráiler y un coordinador local. Se asume material disponible, no se administra inventario físico. Las distancias iniciales son ficticias; el usuario puede registrar otras. El orden se propone por distancia desde almacén, sin optimización vial.

El picking utiliza el día planeado como fecha simulada de ejecución; los registros técnicos y otras acciones conservan hora del sistema. No usar este reloj como evidencia de operación real.

Pendiente: login y permisos individuales por rol, inventario, escáner real, bloqueos y reversas, actualización de pedidos, reprogramación manual con liberación de reservas, capacidad de packing/carga, calendarios de festivos, edición de rutas, cierre parcial con autorización y despliegue compartido. La interfaz completa códigos para las confirmaciones de la demo. No incluye SAP directo, móvil, web ni offline.

La autenticación de esta demo es un token local para el coordinador DEMO, no un sistema de usuarios listo para producción. No exponer el puerto API en la red.

## Otra computadora

1. Tener SQL Server, ODBC Driver 18, Python 3.14 y una copia actualizada del repositorio.
2. Crear backend/.venv e instalar backend/requirements.txt y frontend/requirements.txt.
3. Preparar backend/.env propio y ejecutar python -m backend.app.init_database desde la raíz.
4. Abrir con python desktop_launcher.py. Esto prepara catálogos ficticios y actualiza las etiquetas originales del ejemplo sin borrar operaciones.
5. Desde la app importar samples/csv/demo_escritorio.csv y avanzar. Opcional: python -m scripts.preparar_demo deja el escenario parcialmente avanzado, solo si aún no hay pedidos DEMO.

Git y el ZIP anterior de la base no sincronizan datos ni incluyen automáticamente esta app. Consulta la guía breve en docs/inicio-companero.md para preparar otra PC.

## Pruebas y compilación

```powershell
$env:RUN_SQL_INTEGRATION='1'
& backend/.venv/Scripts/python.exe -m unittest discover -s backend/tests -v
Remove-Item Env:RUN_SQL_INTEGRATION
& backend/.venv/Scripts/python.exe desktop_launcher.py --capture
```

La prueba de recorrido crea una base _Test de nombre único y elimina únicamente esa base al terminar. No ejecutarla con datos de producción.

Para generar el ejecutable se usa PyInstaller (dependencia de desarrollo); consultar scripts/compilar-demo.ps1. Un paquete compilado aceptado por las políticas del equipo no necesitaría Python instalado, pero sí SQL Server/ODBC y la configuración/carpeta del proyecto indicadas. Actualmente se usa Python para ejecutarla.
