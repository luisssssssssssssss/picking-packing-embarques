# Preparación local

Esta guía prepara el entorno local. Ya existe una app Python/PySide6 con FastAPI y SQL Server. Para empezar rápidamente, usa [la guía del compañero](../inicio-companero.md).
Consultar [Conexión SQL](conexion-sql.md) para los comandos de instalación y comprobación.

## Herramientas

| Herramienta | Uso | Estado conocido en la PC principal |
| --- | --- | --- |
| Git | Compartir código e historial. | Disponible y repositorio conectado. |
| SQL Server | Base local de desarrollo. | Standard Developer 2025, servicio MSSQLSERVER en ejecución en la última comprobación. |
| Microsoft ODBC Driver 18 for SQL Server | Conexión del backend con SQL Server. | Disponible. |
| SSMS | Consultas y administración manual. | Instalado. |
| Python | Backend e inicializador. | Python 3.14.7 de 64 bits instalado; backend/.venv y pip comprobados. |
| PySide6 | Aplicación Windows en Python. | Dependencias en frontend/requirements.txt. |

Developer se utilizará para desarrollo y pruebas. La edición de la instalación productiva se decidirá
con el responsable del entorno antes del piloto operativo.

## Python 3.14.7 de 64 bits

La versión acordada está registrada en [.python-version](../../.python-version).
Ese archivo documenta la versión; no instala Python por sí mismo. Las actualizaciones se acordarán
entre ambos y se verificarán antes de cambiar la versión del proyecto.

En la PC principal ya se instaló Python y se creó el entorno. Para preparar la computadora del compañero:

1. Instalar la misma versión para su usuario con WinGet:

```powershell
winget install --id Python.Python.3.14 --exact --version 3.14.7 --source winget --scope user --architecture x64 --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
```

El paquete usa el instalador de la Python Software Foundation. También está disponible en la
[página oficial de Python 3.14.7](https://www.python.org/downloads/release/python-3147/).

2. Abrir una terminal nueva y comprobar que python --version devuelve Python 3.14.7.
Si la terminal conserva el PATH anterior, cerrarla y abrirla de nuevo; puede ser necesario reiniciar el editor.
3. Desde la raíz del repositorio, crear un entorno independiente únicamente si backend/.venv no existe:

```powershell
python -m venv backend\.venv
.\backend\.venv\Scripts\python.exe --version
.\backend\.venv\Scripts\python.exe -m pip --version
```

No es necesario activar el entorno si se usa directamente su ejecutable.
La carpeta backend/.venv está excluida de Git y se crea en cada computadora.
No se debe copiar ni subir este entorno a GitHub. Un entorno existente debe revisarse antes de reemplazarlo.

Para comprobar su aislamiento:

```powershell
.\backend\.venv\Scripts\python.exe -c "import sys; print(sys.executable); print(sys.prefix != sys.base_prefix)"
```

El ejecutable debe pertenecer a backend/.venv y el resultado debe incluir True.

Las dependencias ya están fijadas en backend/requirements.txt. Instalarlas en cada entorno:

```powershell
.\backend\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt -r frontend/requirements.txt
```

## Configuración propia

Con Python preparado, copiar la plantilla una sola vez.
Si backend/.env ya existe, conservarlo y revisar las diferencias manualmente:

```powershell
if (-not (Test-Path -LiteralPath 'backend/.env')) {
    Copy-Item -LiteralPath 'backend/.env.example' -Destination 'backend/.env'
}
```

Editar el archivo local según la computadora. El módulo backend/app/core/config.py lee estas variables;
las variables SQL_ del proceso tienen prioridad sobre backend/.env.

- SQL_SERVER: instancia SQL de esta computadora; localhost para una instancia predeterminada.
- SQL_DATABASE: nombre de la base propia de desarrollo, por ejemplo PickingPackingEmbarques_Dev.
- SQL_AUTH_MODE: windows o sql, según la instalación.
- SQL_USERNAME y SQL_PASSWORD: solo para autenticación SQL; vacíos con autenticación Windows.
- SQL_DRIVER: controlador ODBC instalado.
- SQL_ENCRYPT: conexión cifrada.
- SQL_TRUST_SERVER_CERTIFICATE: excepción para el certificado de una instalación local de desarrollo.

La plantilla está orientada a SQL local con autenticación Windows. Cada persona se autentica con su
propio usuario; puede usar el mismo nombre de base porque las instancias están en computadoras distintas.
Para un entorno desplegado se configurará un certificado confiable y la validación correspondiente.

La autenticación Windows inicializa con la identidad que ejecuta Python; abrir SSMS con otro usuario
no garantiza que el proceso Python tenga esos permisos. El inicializador comprobará conexión y permisos.

## SQL Server: comprobación disponible

En la PC principal se comprobó conexión de solo lectura con localhost y autenticación Windows.
La cuenta comprobada puede crear bases. El compañero debe verificar estos requisitos en su propio equipo.

El inicializador ya crea la base y aplica las cuatro migraciones sin borrar datos:

```powershell
.\backend\.venv\Scripts\python.exe -m backend.app.init_database
```

La cuenta de instalación podrá tener más permisos que la cuenta de operación habitual.

## App y red

La app Python consulta FastAPI; no recibe credenciales SQL. El lanzador actual inicia una API privada en 127.0.0.1 y una ventana nativa. Cada desarrollador usa su propia instancia local.

La aplicación móvil, la autenticación por roles y el despliegue compartido siguen pendientes.
