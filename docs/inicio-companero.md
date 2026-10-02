# Empezar en tu computadora

Necesitas Windows, Git, Python 3.14 de 64 bits, SQL Server local y **ODBC Driver 18 for SQL Server**. Acepta la invitación de GitHub para poder subir cambios.

**1. Descarga el proyecto** (PowerShell):

```powershell
git clone https://github.com/luisssssssssssssss/picking-packing-embarques.git
cd picking-packing-embarques
```

Si ya lo tienes: desde esa carpeta, guarda tus cambios y ejecuta `git switch main` y `git pull --ff-only`.

**2. Instala las dependencias:**

```powershell
py -3.14 -m venv backend/.venv
.\backend\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt -r frontend/requirements.txt
if (-not (Test-Path backend/.env)) { Copy-Item backend/.env.example backend/.env }
notepad backend/.env
```

**3. En ese archivo**, pon tu instancia en `SQL_SERVER`: `localhost` o, por ejemplo, `localhost\SQLEXPRESS`. Deja `SQL_DATABASE=PickingPackingEmbarques_Dev`. Con autenticación Windows, usuario y contraseña SQL van vacíos.

**4. Crea la base y abre la app:**

```powershell
.\backend\.venv\Scripts\python.exe -m backend.app.init_database
.\backend\.venv\Scripts\python.exe desktop_launcher.py
```

Si la creación falla, revisa que SQL Server esté iniciado y que tu usuario tenga permisos para crear la base/objetos. Después puedes abrir con doble clic en **Iniciar Demo.cmd**.

**Script SQL:** [crear_base_desarrollo.sql](../database/distribucion/crear_base_desarrollo.sql). Alternativa al inicializador: abrirlo en SSMS, conectado a tu SQL, y ejecutar **todo** con F5. Crea las mismas 68 tablas; no copia los pedidos del otro equipo.

**5. Prueba:** abre **Supervisor → Pedidos**, pulsa **Usar los 3 pedidos del ejemplo**; organiza a 600 piezas/día y pulsa **Volver al montacarguista** para recoger, empacar y trasladar. Desde Supervisor → Viajes prepara el viaje; vuelve al operador para cargar y finalmente cierra el embarque desde Supervisor. También puedes crear un pedido de 24 piezas y un destino de 7 km. Cierra y vuelve a abrir: deben conservarse. Para tener el escenario parcialmente avanzado: `.\backend\.venv\Scripts\python.exe -m scripts.preparar_demo` (solo si aún no importaste pedidos).

**6. Tu primera tarea:** [Agregar productos y probar el recorrido](tareas/agregar-productos.md).

Cada quien tiene su propia base. GitHub comparte código y scripts, no los datos. **Nunca subas backend/.env**, respaldos SQL ni archivos reales del cliente.


## Actualización del 2 de octubre: operador y supervisor

Antes de actualizar, ejecuta `git status`. Si tienes cambios propios, guárdalos en un commit en tu rama; no los descartes.

Con tu trabajo guardado, actualiza main:

```powershell
git switch main
git pull --ff-only origin main
```

Si Git informa divergencia o conflicto, conserva tus commits y revisen la integración juntos.

Abre **Iniciar Supervisor.cmd**. Desde Hoy, el botón grande abre la pantalla del montacarguista.
**Iniciar Demo.cmd** abre directamente el operador. Conserva tu backend/.env local.
No hay nuevas migraciones SQL ni dependencias en esta actualización.
El CSV ficticio pedidos_prueba.csv sirve para importar 48 Coca-Colas, 36 Sabritas y 24 Ruffles.
Las fechas son fijas de prueba; volver a importar el mismo archivo no crea pedidos duplicados.
Validación de publicación: 42 pruebas backend y 14 de interfaz aprobadas.
