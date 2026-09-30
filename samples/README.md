# Datos ficticios de demostración

Todos los nombres, códigos, cantidades, direcciones y kilómetros son inventados. No representan SAP, Nemak ni inventario real.

Este paquete permite revisar el esquema y comprobar coherencia de muestras **antes de crear la base**. No inserta datos en SQL Server. Para la app actual sí existe un importador operativo: usa samples/csv/demo_escritorio.csv. Los demás archivos de esta carpeta son muestras del diseño lógico, con un contrato distinto.

## Empezar

Leer [Recorrido de demostración](../docs/pruebas/recorrido-demo.md). El archivo [demo_logistica.json](scenarios/demo_logistica.json) describe el estado esperado después del primer viaje.

Desde la raíz del proyecto, ejecutar:

```powershell
.\backend\.venv\Scripts\python.exe .\scripts\validar_datos_demo.py
```

Requiere Python, usa solo su biblioteca estándar y no carga .env, credenciales ni conexiones SQL. El validador no modifica archivos. Revisa este conjunto de muestras; no debe usarse como importador o validador general del cliente.

Resultado comprobado: 276 comprobaciones de coherencia y 12 archivos con sus errores esperados.

## Contenido

- 2 almacenes y 8 ubicaciones.
- 3 clientes y 3 destinos.
- 3 productos con lotes ficticios, en PZA.
- 3 pedidos con 4 líneas.
- 5 asignaciones de surtido.
- 2 viajes; uno cerrado en el estado esperado y otro sin ejecutar.
- 3 HU del primer viaje, con 4 aportes trazables.
- Cantidades de 100 piezas repartidas 60/40 para ilustrar un pedido pendiente.

## Archivos de entrada

UTF-8, encabezado, fecha YYYY-MM-DD, decimal con punto. CSV separado por coma y TXT por barra vertical. Contrato **provisional**, no formato definitivo de SAP.

| Archivo | Qué debe observarse |
| --- | --- |
| [pedidos_correctos.csv](csv/pedidos_correctos.csv) | 3 pedidos, 4 líneas válidas. |
| [pedidos_repetidos.csv](csv/pedidos_repetidos.csv) | Mismos bytes que correctos con nombre distinto; detectar duplicado de archivo. |
| [pedidos_duplicados.csv](csv/pedidos_duplicados.csv) | Línea 10 del pedido 450001 repetida; rechazar ese pedido en el futuro importador. |
| [pedidos_con_errores.csv](csv/pedidos_con_errores.csv) | Cantidad negativa, material vacío, material desconocido y fecha imposible. |
| [pedidos_actualizados.csv](csv/pedidos_actualizados.csv) | Cantidad cambia de 100 a 120. Formato válido; requiere revisión por operaciones existentes. |
| [pedidos_columnas_faltantes.csv](csv/pedidos_columnas_faltantes.csv) | Falta Material; rechazar estructura. |
| [pedidos_vacio.csv](csv/pedidos_vacio.csv) | Archivo de cero bytes. |
| [pedidos_cantidad_cero.csv](csv/pedidos_cantidad_cero.csv) | Cantidad cero no aceptada. |
| [pedidos_fraccionarios.csv](csv/pedidos_fraccionarios.csv) | 1.5 PZA rechazada en este catálogo, que exige piezas enteras. |
| [pedidos_destino_incorrecto.csv](csv/pedidos_destino_incorrecto.csv) | Destino de otro cliente. |
| [pedidos_codigos_con_ceros.csv](csv/pedidos_codigos_con_ceros.csv) | Conservar pedido 000450004 y línea 000010 como texto. |
| [pedidos.txt](txt/pedidos.txt) | Misma información de correctos, con separador diferente. |

El [manifiesto](scenarios/manifest.json) declara el formato y los errores esperados. Los archivos inválidos son intencionales: la prueba pasa cuando se detectan los errores previstos, no cuando se importan como válidos.

No cambiar las muestras inválidas para hacerlas “correctas”. Agregar nuevos casos con expectativa explícita.

## Alcance de la validación

Se comprueban referencias entre códigos, compatibilidad de material/lote/ubicación/destino, cantidades por etapa, asignaciones a paradas, contenido de HU, orden inverso de carga, identidad por línea y errores de las muestras.

El escenario JSON es una representación legible simplificada. Omite PK SQL, usuarios reales, contraseñas, columnas técnicas, auditoría completa e historial de movimientos. **No es un volcado ni una semilla directamente insertable en las 63 tablas.**

Para llevarlo a SQL será necesario implementar migraciones y un cargador de desarrollo. Las operaciones deberán ejercitar los servicios del backend; insertar únicamente estados finales no demuestra que el flujo funcione.

Las 85 pruebas del [modelo](../docs/pruebas/casos-modelo-datos.md) siguen pendientes de implementación. Estas comprobaciones locales no demuestran concurrencia, seguridad ni transacciones reales.

Ambos desarrolladores pueden ejecutar el validador en sus computadoras. Compartir estas muestras por Git no sincroniza las futuras bases de datos.
