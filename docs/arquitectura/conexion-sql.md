# Conexión de Python con SQL Server

## Alcance implementado

El backend lee backend/.env, valida la configuración y abre conexiones con pyodbc.
El comando de diagnóstico solo ejecuta SELECT: no crea bases, tablas, usuarios ni datos.
Aún no hay API FastAPI ni aplicación Flutter.

Dependencias directas:
- pyodbc: usa el controlador Microsoft ODBC instalado en Windows.
- pydantic-settings: carga y valida la configuración; utiliza Pydantic, ya acordado en el proyecto.

backend/requirements.txt fija las versiones directas y transitivas verificadas con Python 3.14.7.
No se añadió ORM ni un framework distinto del stack acordado.

## Preparar cada computadora

Desde la raíz del repositorio, con el entorno Python ya creado:

```powershell
.\backend\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
if (-not (Test-Path -LiteralPath 'backend/.env')) {
    Copy-Item -LiteralPath 'backend/.env.example' -Destination 'backend/.env'
}
```

Editar backend/.env con la instancia y la base propias. No copiar las credenciales del compañero.
El archivo .env está excluido de Git; .env.example y requirements.txt sí se comparten.

Las variables del proceso tienen prioridad sobre .env. El archivo se localiza respecto al módulo
de configuración, no respecto a la carpeta de la terminal. Los comandos de esta guía se ejecutan
desde la raíz para que Python encuentre el paquete backend.

## Variables

| Variable | Significado |
| --- | --- |
| SQL_SERVER | Instancia; localhost para la instancia predeterminada de esta PC. |
| SQL_DATABASE | Base que usará el proyecto. No se crea al conectarse. |
| SQL_AUTH_MODE | windows o sql. |
| SQL_DRIVER | Nombre exacto del controlador ODBC de 64 bits instalado. |
| SQL_USERNAME | Obligatorio con modo sql; vacío con windows. |
| SQL_PASSWORD | Obligatorio con modo sql; vacío con windows. |
| SQL_ENCRYPT | true para cifrar la conexión. |
| SQL_TRUST_SERVER_CERTIFICATE | true en esta instalación local con certificado propio; false al validar un certificado confiable. |
| SQL_LOGIN_TIMEOUT | Espera de conexión en segundos, de 1 a 60; predeterminado 5. |
| SQL_QUERY_TIMEOUT | Espera de consultas en segundos, de 1 a 300; predeterminado 10. |

La plantilla usa autenticación Windows y no contiene contraseña.
Con autenticación SQL, el servidor debe estar configurado para permitirla y la cuenta debe existir.
Este módulo no habilita autenticación mixta ni crea cuentas. Las pruebas reales se hicieron con Windows;
la construcción y validación de la configuración SQL se cubren con pruebas automáticas.

La contraseña se trata como secreta en el modelo. No imprimir el resultado de build_connection_string:
esa función entrega las credenciales al controlador. Los diagnósticos mostrados al usuario omiten
la cadena de conexión y el texto original del controlador.

## Dos comprobaciones diferentes

Comprobar únicamente la instancia, usando explícitamente master:

```powershell
.\backend\.venv\Scripts\python.exe -m backend.app.check_connection --server-only
```

Un resultado status=ok con scope=server demuestra conexión a la instancia.
application_database_verified=false indica que no se comprobó la base del proyecto.

Comprobar la base indicada en SQL_DATABASE:

```powershell
.\backend\.venv\Scripts\python.exe -m backend.app.check_connection
```

Este segundo comando conecta directamente a la base configurada. No cambia a master si falla.
Una base inexistente o inaccesible produce un error y un código de salida distinto de cero.

Códigos de salida:
- 0: conexión y consulta correctas para el alcance indicado.
- 1: controlador ausente, conexión o consulta SQL fallida.
- 2: configuración inválida o uso incorrecto de argumentos.

Los errores por base no disponible no demuestran por sí solos que no exista: también pueden indicar
falta de permisos. El diagnóstico conserva esa distinción. No se registra la contraseña.

## Resultado comprobado en la PC principal

- Instancia local PC-GAMER-WICHO, SQL Server 17.0.1000.7.
- Conexión Python a master con autenticación Windows: correcta.
- PickingPackingEmbarques_Dev: todavía no existe, verificado con la cuenta administradora.
- Diagnóstico de esa base: devuelve error controlado sin intentar crearla ni usar otra base.
- La conexión se cierra al terminar, incluso cuando falla una operación.
- Las escrituras futuras requerirán confirmación explícita de transacción mediante commit.

## Verificación automática

```powershell
.\backend\.venv\Scripts\python.exe -m unittest discover -s backend/tests -v
.\backend\.venv\Scripts\python.exe -m pip check
```

Las pruebas no necesitan SQL Server: usan datos ficticios y conexiones simuladas para cubrir
prioridad de variables, autenticación, protección de valores ODBC, ausencia del controlador,
cierre de conexiones y mensajes sin secretos. La conexión real se comprueba por separado.

## Archivos del incremento

- backend/app/core/config.py: carga y validación.
- backend/app/repositories/connection.py: apertura, cierre y diagnóstico seguro.
- backend/app/check_connection.py: comando de solo lectura.
- backend/tests/test_sql_connection.py: pruebas.
- backend/requirements.txt: dependencias fijadas.
- backend/.env.example: plantilla compartida.
- backend/.env: configuración local, excluida de Git.

## Próximo paso

Construir el inicializador y las migraciones mínimas para la base de desarrollo.
La comprobación de conexión no sustituye ese instalador.
