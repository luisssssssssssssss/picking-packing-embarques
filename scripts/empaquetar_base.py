"""Package the reviewed migrations as one SSMS script, without local secrets."""
from pathlib import Path
import hashlib
from zipfile import ZipFile, ZIP_DEFLATED

from backend.app.init_database import APP_CODE, load_migrations, quote_database

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "database" / "distribucion"


def literal(text: str) -> str:
    return "N'" + text.replace("'", "''") + "'"


def build_sql(database: str = "PickingPackingEmbarques_Dev") -> str:
    name = quote_database(database)
    migrations = load_migrations()
    history_checks = [f"IF (SELECT COUNT(*) FROM platform.SchemaMigration) <> {len(migrations)} THROW 51000, 'Version distinta; use las migraciones del repositorio.', 1;"]
    for m in migrations:
        history_checks.append(f"IF NOT EXISTS (SELECT 1 FROM platform.SchemaMigration WHERE Version='{m.version}' AND ApplicationCode='{APP_CODE}' AND ScriptChecksum=0x{m.checksum.hex()}) THROW 51000, 'Historial diferente; no se modifico la base.', 1;")
    body = f"""
USE {name};
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @marker nvarchar(128);
 SELECT @marker=CONVERT(nvarchar(128),value) FROM sys.extended_properties WHERE class=0 AND name=N'ApplicationCode';
 IF @marker IS NOT NULL
 BEGIN
   IF @marker <> N'{APP_CODE}' THROW 51000, 'Base de otra aplicacion; no se modifico.', 1;
   IF OBJECT_ID(N'platform.SchemaMigration',N'U') IS NULL THROW 51000, 'Falta el historial; revisar manualmente.', 1;
   EXEC({literal(chr(10).join(history_checks))});
   COMMIT;
   PRINT N'La base ya tiene la version 0.2. Datos conservados.';
   RETURN;
 END;
 IF EXISTS (SELECT 1 FROM sys.objects WHERE is_ms_shipped=0)
   THROW 51000, 'La base contiene objetos sin identificacion. Use una base vacia.', 1;
 EXEC sys.sp_addextendedproperty @name=N'ApplicationCode', @value=N'{APP_CODE}';
"""
    for m in migrations:
        body += "\nEXEC(" + literal(m.sql) + ");\n"
        insert = f"INSERT INTO platform.SchemaMigration (ApplicationCode,Version,ScriptChecksum,AppliedAtUtc,ApplicationVersion) VALUES (N'{APP_CODE}',N'{m.version}',0x{m.checksum.hex()},SYSUTCDATETIME(),N'0.2');"
        body += "EXEC(" + literal(insert) + ");\n"
    body += """
 COMMIT;
 SELECT DB_NAME() AS BaseCreada, COUNT(*) AS Tablas FROM sys.tables WHERE is_ms_shipped=0;
 PRINT N'Instalacion 0.2 terminada: 68 tablas y catalogos iniciales.';
END TRY
BEGIN CATCH
 IF XACT_STATE() <> 0 ROLLBACK;
 THROW;
END CATCH;
"""
    resource = APP_CODE + ":install:" + hashlib.sha256(database.upper().encode()).hexdigest()
    return f"""-- Paquete de desarrollo 0.2. Ejecutar COMPLETO en SSMS, conectado a su propia instancia.
-- No requiere Python ni modo SQLCMD. No contiene credenciales ni datos operativos.
-- Si ocurre un error, las migraciones se revierten; una base nueva puede quedar vacia.
USE [master];
SET NOCOUNT ON;
IF @@TRANCOUNT <> 0 THROW 51000, 'Ejecute en una ventana nueva sin transaccion abierta.', 1;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'{resource}', @LockMode='Exclusive', @LockOwner='Session', @LockTimeout=0;
IF @lock < 0 THROW 51000, 'Otra instalacion esta en curso.', 1;
BEGIN TRY
 IF DB_ID({literal(database)}) IS NULL EXEC(N'CREATE DATABASE {name}');
 EXEC({literal(body)});
 EXEC sys.sp_releaseapplock @Resource=N'{resource}', @LockOwner='Session';
END TRY
BEGIN CATCH
 EXEC sys.sp_releaseapplock @Resource=N'{resource}', @LockOwner='Session';
 THROW;
END CATCH;
"""


GUIDE = """BASE DE DESARROLLO - Picking, Packing y Embarques - version 0.2
Generado el 29 de septiembre de 2026.

NECESITAS
- Motor Microsoft SQL Server instalado; se probo con SQL Server 2025.
- SQL Server Management Studio (SSMS).
- Un usuario con permiso para crear la base y sus objetos.
Para ejecutar este archivo SQL no necesitas Python ni ODBC.

PASOS
1. Extrae el ZIP en tu computadora.
2. Abre SSMS y conectate a TU instancia local con tus propias credenciales.
3. Abre crear_base_desarrollo.sql.
4. Ejecuta TODO el archivo con F5, sin seleccionar solamente una parte.
5. Debe indicar: Instalacion 0.2 terminada: 68 tablas y catalogos iniciales.
6. Actualiza Databases/Bases de datos y abre PickingPackingEmbarques_Dev.
Si tu instancia tiene nombre, usa ese nombre al conectarte; no tiene que ser igual al del otro desarrollador.

CONTENIDO
68 tablas, relaciones, restricciones, indices y registro de migraciones.
Incluye 6 roles, 3 unidades de medida y 2 tipos de unidad de manejo.
No contiene usuarios habilitados, claves, pedidos, archivos SAP ni datos privados.
Es la misma estructura inicial del proyecto; NO es una copia de sus datos.
Si la misma version ya existe, valida el historial y conserva sus registros.
Si encuentra objetos ajenos o un historial distinto, se detiene.
Si falla, comparte el mensaje de error; no borres bases para reintentar.
No ejecutar fragmentos sueltos ni cambiar los scripts que ya se aplicaron.

DESPUES
Para trabajar en el backend: repositorio actualizado, Python, dependencias de
backend/requirements.txt, ODBC Driver 18 y archivo backend/.env propio.
El historial es compatible con el inicializador Python del repositorio.
Git y este ZIP no sincronizan los registros entre computadoras.
Las siguientes versiones se compartiran por Git mediante migraciones.
Este paquete no implementa API, importador, pantallas ni reglas operativas.

SOBRE CSV Y PYTHON
El archivo exportado de SAP entra al importador Python.
Python valida, registra errores y escribe pedidos en SQL Server.
Un CSV de pedidos no llena todas las tablas:
- Catalogos: productos, clientes, almacenes y ubicaciones se preparan aparte
  o mediante importaciones controladas.
- Planeacion: capacidades, calendario, rutas y prioridades se configuran.
- Operacion: picking, packing, tarimas, carga e incidencias se generan al usar la app.
Aun no existe el CSV real ni un contrato definitivo de columnas.
"""


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sql = OUTPUT / "crear_base_desarrollo.sql"
    guide = OUTPUT / "LEEME.txt"
    sql.write_text(build_sql(), encoding="utf-8-sig")
    guide.write_text(GUIDE, encoding="utf-8-sig")
    target = OUTPUT / "Base_Datos_Desarrollo_v0.2.zip"
    with ZipFile(target, "w", ZIP_DEFLATED) as archive:
        archive.write(sql, sql.name)
        archive.write(guide, guide.name)
    print(target)


if __name__ == "__main__":
    main()
