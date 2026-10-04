# Instalación de la base SQL Server

Implementación inicial 0.2, 28 de septiembre de 2026.

## Instalar en cada computadora

SQL Server y ODBC Driver 18 deben estar instalados. Desde la raíz del repositorio, con las dependencias de backend/requirements.txt instaladas:

1. Copiar backend/.env.example a backend/.env si todavía no existe.
2. Configurar SQL_SERVER, SQL_DATABASE y autenticación para la instancia propia. No compartir credenciales ni subir .env.
3. Ejecutar:

```powershell
& backend/.venv/Scripts/python.exe -m backend.app.init_database
& backend/.venv/Scripts/python.exe -m backend.app.check_connection
```

El inicializador crea la base si falta y el usuario tiene permiso. También acepta una base vacía creada previamente por un administrador. No instala el motor SQL Server.

La instalación local comprobada usa localhost y PickingPackingEmbarques_Dev. En SSMS: conectar a localhost con autenticación Windows y actualizar el nodo Databases.

## Qué se instala

- 68 tablas en 10 esquemas, 657 columnas.
- Claves primarias, 171 relaciones, 124 restricciones CHECK e índices únicos y de consulta.
- 7 índices únicos filtrados: por ejemplo, una HU no puede tener dos asignaciones de embarque vigentes.
- 6 roles, 3 unidades de medida y 2 tipos de unidad de manejo.
- Historial de cuatro migraciones con SHA-256.

No se crean cuentas habilitadas ni contraseñas predeterminadas. Los permisos funcionales se definirán al implementar la autorización. Los CSV/TXT ficticios todavía no se cargan; los datos operativos están vacíos.

## Migraciones y trabajo en equipo

Los cuatro scripts en database/migrations son la fuente ejecutable. Aplicarlos mediante el inicializador, no individualmente desde SSMS. El instalador conserva el historial y no vuelve a aplicar versiones registradas. Los finales de línea CRLF/LF se normalizan antes del cálculo del hash.

Una migración aplicada no se modifica: agregar una nueva versión y registrarla en MIGRATIONS del inicializador. Compartir scripts por Git, revisarlos juntos y aplicarlos en ambas computadoras. Git no sincroniza registros de SQL Server.

El instalador rechaza bases del sistema, bases con objetos ajenos sin identificación, versiones desconocidas e historial con hashes diferentes. Un bloqueo de sesión impide dos instalaciones simultáneas del mismo destino. Las migraciones pendientes se confirman juntas; un error revierte sus cambios. Si acaba de crear la base y falla la preparación, puede quedar una base vacía para reintentar: nunca la elimina automáticamente.

Se requieren permisos de creación de objetos en la base y acceso a master para la coordinación. La cuenta de ejecución cotidiana de la futura API deberá tener permisos limitados y no permisos de administrador/instalación.

## Integridad y alcance real

SQL asegura referencias, unicidad, tipos, campos obligatorios, cantidades positivas y varias condiciones de cada registro. Los UpdatedAtUtc tienen valor inicial, pero el backend deberá actualizarlos al modificar filas. RowVersion cambia automáticamente.

Las sumas entre registros y transiciones operativas necesitan servicios transaccionales: no surtir de más, no empacar de más, capacidad total diaria, compatibilidad material/destino, autorizaciones, orden de carga y reprogramación. Esas reglas NO están implementadas por tener sus tablas. No hay triggers ni procedimientos de negocio prematuros.

Los registros de evidencia deben quedar protegidos contra modificaciones por los permisos de la futura aplicación; por ahora una cuenta administradora SQL conserva sus facultades. No se promete auditoría inalterable ante un administrador.

Ver [planeación por capacidad](../schema/capacidad-diaria.md). La estructura puede ampliarse mediante nuevas tablas y migraciones; los campos y reglas del cliente continúan sujetos a validación.

## Pruebas

Pruebas unitarias y de conexión simulada:

```powershell
& backend/.venv/Scripts/python.exe -m unittest discover -s backend/tests -v
```

Pruebas con SQL real, únicamente contra una base propia terminada en _Dev o _Test:

```powershell
$env:RUN_SQL_INTEGRATION='1'
& backend/.venv/Scripts/python.exe -m unittest discover -s backend/tests -v
Remove-Item Env:RUN_SQL_INTEGRATION
```

Las pruebas reales revierten sus datos al terminar. Los contadores IDENTITY pueden avanzar aunque los registros se reviertan; no son números consecutivos del negocio. Cubren existencia de tablas, constraints habilitados, duplicados, referencias inexistentes, ubicación de otro almacén, capacidad inválida y rollback de una migración fallida.

Migración 005: agrega DisplayOrderId al pedido, conserva el número de origen y asigna ese número como ID visible a los pedidos anteriores. Índice único por sistema de origen. Ejecuta python -m backend.app.init_database antes de abrir una versión actualizada.
