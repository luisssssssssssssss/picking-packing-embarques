# Verificación SQL inicial — 28 de septiembre de 2026

Destino comprobado: localhost, base PickingPackingEmbarques_Dev, SQL Server 17.0.1000.7.

## Resultado ejecutado

- Creación real de la base y aplicación de migraciones 001–004.
- Segunda ejecución sin migraciones pendientes, conservando datos semilla.
- 68 tablas, 657 columnas: comparación de nombres, tipos base y nulabilidad contra el JSON lógico.
- 171 claves foráneas y 124 CHECK, todos habilitados y confiables.
- 7 índices únicos filtrados.
- 6 roles, 3 unidades de medida, 2 tipos de HU; cero pedidos operativos.
- 22 pruebas del backend aprobadas (10 existentes, 5 del instalador y 7 con SQL real).
- Prueba corregida de capacidad: primero insertó un calendario válido de 600 y después comprobó que SQL rechaza 601 de capacidad no disponible con error de constraint 547.
- Migración de prueba con DDL seguido de error: tabla y registro de versión ausentes tras rollback.
- Validación independiente de muestras: 276 comprobaciones, 12 CSV/TXT; no equivale a importación SQL.
- Diagnóstico de conexión a la base configurada: correcto.

## Límites de esta revisión

No certifica todos los procesos del sistema. Las pruebas de capacidad comprueban integridad por fila; todavía no existe el servicio transaccional de reservas, reprogramación o cierre de semana. Tampoco se han ejecutado picking, packing o embarques mediante API.

Los 85 escenarios de aceptación del diseño siguen siendo especificaciones por implementar, no 85 pruebas aprobadas. Las muestras ficticias continúan fuera de SQL. Las restricciones entre sumas de registros, autorización, auditoría funcional y concurrencia operativa deberán verificarse al desarrollar cada servicio.

Consultar [guía de instalación](../../database/migrations/README.md) para reproducir las pruebas y [capacidad diaria](../../database/schema/capacidad-diaria.md) para los casos de pendientes.
