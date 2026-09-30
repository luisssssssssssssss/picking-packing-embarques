# Primera tarea: agregar productos desde la app

**Objetivo:** registrar, por ejemplo, Doritos Nacho 58 g o Sprite 600 ml y poder surtirlos igual que Coca-Cola. Es una tarea pendiente para el compañero; todavía no está implementada.

## Trabajar en tu rama

Desde una copia actualizada y sin cambios pendientes:

```powershell
git switch main
git pull --ff-only
git switch -c codex/alta-productos
git config --local user.name "TU NOMBRE"
git config --local user.email "TU CORREO"
```

## Qué entregar

- Botón **Agregar producto** con nombre y presentación; unidad PZA por defecto. Código DEMO generado automáticamente, sin escribir claves.
- Guardar por FastAPI en SQL Server. Validar nombre vacío y duplicados en el backend.
- Preparar también ubicación de surtido (`MaterialLocation`) y consumo de capacidad (`WorkStandardVersion`, una pieza = una unidad). Sin esto, el producto no se podrá planear.
- Mostrar el producto nuevo en **Nuevo pedido** y en Inicio. Actualmente las tres tarjetas de Inicio son fijas: convertirlas en una lista del catálogo.
- No borrar productos con movimientos ni cambiar migraciones ya aplicadas. El inventario físico queda fuera de esta tarea.

Puntos de partida: `backend/app/services/demo_catalog.py`, `demo_seed.py`, `demo_commands.py`, `backend/app/repositories/demo_queries.py` y `frontend/desktop/window.py`. No guardar reglas únicamente en la interfaz.

## Comprobar antes de entregar

1. Agregar Doritos, cerrar la app y volver a abrir: debe seguir disponible.
2. Crear un pedido de 24 piezas para un destino a 7 km; planear, recoger, empacar, cargar y cerrar.
3. Intentar nombre vacío y duplicado: mensaje claro, sin registros incompletos.
4. Confirmar que Coca-Cola, Sabritas y Ruffles siguen funcionando.
5. Añadir pruebas de alta/duplicados y del producto nuevo recorriendo la operación. Ejecutar desde la raíz:

```powershell
$env:RUN_SQL_INTEGRATION='1'
.\backend\.venv\Scripts\python.exe -m unittest discover -s backend/tests -v
Remove-Item Env:RUN_SQL_INTEGRATION
.\backend\.venv\Scripts\python.exe -m unittest discover -s frontend/tests -v
```

Las pruebas SQL crean y eliminan exclusivamente sus bases temporales; requieren permiso para ello. Si algo falla, adjunta pasos y mensaje sin credenciales.

## Compartir el resultado

Revisa `git diff`, agrega solamente tus archivos, haz un commit descriptivo y ejecuta `git push -u origin codex/alta-productos`. En GitHub abre un pull request hacia main; el otro compañero lo revisa antes de integrarlo. Adjunta una captura y el resultado de las pruebas.
