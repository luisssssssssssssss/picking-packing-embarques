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

**5. Prueba:** en Pedidos, pulsa **Usar los 3 pedidos del ejemplo**; organiza a 600 piezas/día y sigue Inicio hasta cerrar el embarque. También puedes crear un pedido de 24 piezas y un destino de 7 km. Cierra y vuelve a abrir: deben conservarse. Para tener el escenario parcialmente avanzado: `.\backend\.venv\Scripts\python.exe -m scripts.preparar_demo` (solo si aún no importaste pedidos).

**6. Tu primera tarea:** [Agregar productos y probar el recorrido](tareas/agregar-productos.md).

Cada quien tiene su propia base. GitHub comparte código y scripts, no los datos. **Nunca subas backend/.env**, respaldos SQL ni archivos reales del cliente.
