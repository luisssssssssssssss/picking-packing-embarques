# Presentación · domingo 4 de octubre de 2026

Ejercicio con datos simulados y productos conocidos. No es una exportación real de SAP.
La base de presentación está separada de las pruebas anteriores. Conserva lo que hagas al cerrar.
Un solo montacarguista; el mismo operador realiza las tareas en secuencia.

## Abrir
1. Abre `D:\Proyecto\Iniciar Presentacion.cmd`. Abre supervisor y montacarguista.
2. Usa esas ventanas; las abiertas con los accesos anteriores consultan otra base.
3. En la primera ejecución preparada hay cero pedidos. Los catálogos ya existen.
4. Archivo a importar: `D:\Proyecto\Presentacion_domingo_2026-10-04.txt`.

## Lo que recibimos
Todos los pedidos solicitan entrega el domingo **2026-10-04**.

| ID pedido | Almacén | Producto | Piezas | Quién lo pidió / destino | Distancia de ejemplo |
|---|---|---|---:|---|---:|
| PED-001 | Cuarto de Víctor | Coca-Cola 600 ml | 48 | La Ralde | 7 km |
| PED-002 | Cuarto de Víctor | Ruffles Queso 50 g | 36 | Oxxo | 1 km |
| PED-003 | Cuarto de Huicho | Doritos Nacho 58 g | 60 | Salma | 20 km |
| PED-004 | Cuarto de Huicho | Agua Ciel 1 L | 24 | La Ralde | 7 km |
| PED-005 | Cuarto de Veloco | Pepsi 600 ml | 48 | Oxxo | 1 km |
| PED-006 | Cuarto de Veloco | Cheetos Torciditos 52 g | 24 | Salma | 20 km |

**6 pedidos, 6 productos, 240 piezas.** Víctor 84; Huicho 84; Veloco 72.
Los kilómetros son valores de demostración desde cada almacén, no mediciones de una ruta.

## Guion A a Z (20–30 minutos)
1. **Supervisor → Pedidos → Importar CSV o TXT… → Seleccionar CSV o TXT…**.
   Selecciona el archivo indicado y confirma la importación. Deben entrar 6 pedidos sin errores.
   No uses “Usar los 3 pedidos del ejemplo”: es otro ejercicio.
2. En Pedidos, deja **600 piezas por almacén** y **Empezar el 04/10/2026**.
   Pulsa **Organizar pedidos pendientes**. Las 240 piezas caben hoy; son seis tareas.
   La capacidad actual es por almacén, no una medición de productividad del único trabajador.
3. Ve a **Hoy**: muestra las 240 piezas programadas y sus tareas pendientes.
4. En el **montacarguista**, deja Hoy. Lee producto, cantidad, almacén de origen y destino.
   Confirma **recoger → empacar → llevar a salida**, solo como ejercicio simulado.
   Repite para los seis productos. Usa las cantidades completas para obtener seis tarimas.
   No necesitas escribir códigos ni escanear. El supervisor permite ver el avance.
5. **Supervisor → Viajes → Preparar nuevo viaje**. Elige un almacén y marca las tarimas que quieres enviar. Para completar este ejercicio, usa “Seleccionar todas” en cada almacén. Revisa el total y pulsa “Crear viaje con la selección”. Las tarimas no seleccionadas permanecen en salida.
   Cada viaje sale de un solo almacén; la demo usa un solo tráiler, por eso se hacen tres viajes consecutivos.
6. Lee las dos paradas: se entregan primero las más cercanas según los kilómetros capturados.
   La carga ocurre al revés. Por ejemplo, para Víctor: cargar La Ralde antes de Oxxo.
7. En el montacarguista pulsa Actualizar y confirma las **dos cargas** que vaya indicando.
8. Regresa a **Viajes**, selecciona el viaje y pulsa **Cerrar embarque**.
   Usa un sello de ejemplo (PRESENTACION-01). Consulta **Ver manifiesto**.
9. Repite los pasos 5–8 para los otros dos almacenes, con sellos 02 y 03.
10. Comprueba **240 piezas embarcadas**, seis tarimas y tres embarques cerrados.
    Abre **Ver historial** para mostrar la trazabilidad.

**Cerrar embarque significa salida del almacén, no recepción por el cliente.**
El calendario permite consultar el futuro, pero no confirmar trabajo futuro.
Los domingos ahora son laborables; el exceso de capacidad continúa al día siguiente.
Si vuelves a importar el mismo archivo, se detectará como repetido. El acceso no borra ni reinicia la presentación.

## Cinco recomendaciones para la exposición
1. Empieza con una historia: “La Ralde, Oxxo y Salma pidieron 240 piezas; veamos cómo salen sin perdernos”.
2. Mantén las dos ventanas visibles: realiza una confirmación como operador y muestra el cambio en supervisión.
3. Destaca una sola instrucción a la vez: producto, cantidad, de dónde recoger y a dónde llevar.
4. Explica la carga inversa con las dos paradas de un viaje y termina mostrando su manifiesto.
5. Cierra con el historial y pregunta al cliente si nombres, cantidades, excepciones y pasos corresponden a su operación.

## Qué sí demuestra y qué no
Sí: TXT validado, separación de almacenes, planeación dominical, confirmaciones, empaque, salida, viajes, carga y auditoría.
No: inventario físico verificado, conexión SAP, rutas calculadas por mapas, GPS, entrega confirmada por cliente,
aplicación móvil instalada ni operación con dos usuarios independientes.
No prometas existencia disponible a partir del catálogo: aún no es un control completo de stock.

## Para tu compañero
Base: `PickingPackingEmbarques_Presentacion_20261004_Dev`.
El acceso usa la instancia y autenticación del `backend/.env` local y cambia únicamente SQL_DATABASE en su proceso.
No modifica .env, no importa pedidos automáticamente y no borra datos.
Pruebas SQL del recorrido: `backend/tests/test_demo_presentation.py`, sobre una base temporal de prueba.

## ID del pedido
El TXT incluye ID como primera columna: PED-001 a PED-006. Se conserva como texto, incluidos ceros iniciales. NumeroPedido sigue identificando el pedido de origen; ID es su referencia visible. Un pedido con varios productos comparte ID y utiliza distintas LineaPedido. No se permiten IDs vacíos ni el mismo ID en pedidos diferentes. Archivos anteriores sin ID utilizan NumeroPedido como referencia visible.

Sigue PED-001 desde Pedidos y Hoy hasta el montacarguista, las tarimas, el viaje, el manifiesto y el historial de confirmaciones. Los catálogos de destinos y los totales diarios no son pedidos individuales.
