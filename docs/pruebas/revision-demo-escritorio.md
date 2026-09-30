# Verificación de la demo guiada — 2026-09-29

## Resultado

- 31 pruebas backend aprobadas: conexión/configuración, migraciones, integridad SQL, CSV, autorización HTTP y recorrido operacional completo sobre una base SQL Server temporal.
- 6 pruebas Qt aprobadas: navegación por cinco secciones; selección automática; cantidad y códigos sugeridos; pedido nuevo con 24 piezas; alta de tienda con 7.125 km; selección de la última entrega para cargar; importación del ejemplo en una acción.
- El recorrido SQL verifica 1,600 piezas repartidas 600/600/400, confirmaciones parciales, packing, staging, carga inversa y cierre; después registra una tienda nueva y otras 24 piezas hasta un segundo embarque cerrado.
- Se comprueban kilómetros cero, negativos, no finitos, demasiados decimales y fuera de rango; nombres duplicados; identificador inexistente; propuesta de viaje obsoleta.
- Cambiar Universidad a 2.5 km produce el orden 2.5, 5, 25. Editarla después a 40 km y cambiar su nombre conserva exactamente las paradas ya creadas.
- Se mantienen las pruebas de sobrepicking, packing sin recepción, códigos incorrectos, carga fuera de orden, doble carga, cierre incompleto e idempotencia concurrente.
- Arranque del lanzador con API local real y capturas de las cinco secciones. Revisión visual de Inicio, Pedidos, Viajes y Destinos con el motor nativo Windows.
- Python compileall y git diff --check sin errores. Aviso no bloqueante de Starlette sobre la futura sustitución de httpx en sus pruebas.
- No se cambiaron tablas, migraciones aplicadas ni dependencias. Se reutilizaron PointAddress, DeliverySite y DistanceReference. Las instrucciones de cada parada nueva contienen una copia inmutable y explícita de distancia desde almacén; DistanceFromPreviousId no recibe valores que representen otra cosa.

## Archivos de esta revisión

Creados:
- backend/app/services/demo_catalog.py: destinos, distancias, orden sugerido y pedido sencillo que genera CSV.
- frontend/desktop/widgets.py: componentes compartidos y comunicación asíncrona.

Modificados:
- frontend/desktop/window.py y theme.py: interfaz guiada.
- backend/app/services/demo_seed.py, demo_commands.py, demo_shipping.py y backend/app/repositories/demo_queries.py: catálogo familiar, comandos y consultas.
- desktop_launcher.py: captura de las cinco secciones.
- backend/tests/test_demo_journey.py y frontend/tests/test_window.py.
- README.md, docs/demo-escritorio.md y este informe.
- Capturas actuales en docs/pruebas/capturas/demo-escritorio.png y demo-pagina-1.png a demo-pagina-4.png. Las capturas con números superiores pertenecen a la versión anterior.

## Límites

Es una demo local de escritorio Python con FastAPI y SQL Server. Se asumen existencias suficientes; no se descuenta inventario físico ni se verifica un escaneo real. El orden por km desde almacén no calcula tráfico, caminos ni distancia entre tiendas. Las limitaciones restantes están en docs/demo-escritorio.md.

Los nombres originales ficticios de productos se actualizaron en el catálogo, sin sobrescribir las revisiones históricas de pedidos ni los manifiestos cerrados. Los viajes previamente creados conservan sus distancias de tramo anteriores.

Las pruebas GUI sustituyen el cliente HTTP por uno simulado. El recorrido operacional y el arranque/capturas usan SQL Server real. No se declara este sistema listo para producción.

La publicación incluye código, scripts y guías. Los entornos, secretos y datos operativos permanecen locales.
