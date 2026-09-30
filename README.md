# Picking, Packing y Embarques

Demostración de escritorio Windows en Python/PySide6, FastAPI y Microsoft SQL Server.
La interfaz Python fue solicitada el 29 de septiembre de 2026. La aplicación móvil queda pendiente.

## Empezar y colaborar

- **[Guía rápida para el compañero](docs/inicio-companero.md)**: instalar, crear la base y abrir.
- **[Script SQL completo](database/distribucion/crear_base_desarrollo.sql)** para SSMS.
- **[Primera tarea: agregar productos](docs/tareas/agregar-productos.md)** con pruebas y entrega.

## Estado

- Repositorio Git y remoto de GitHub configurados.
- Estructura inicial y guía para dos desarrolladores preparadas.
- La instalación local del motor SQL Server se comprobó mediante una conexión de lectura.
- Python 3.14.7 de 64 bits instalado y entorno local backend/.venv creado y comprobado.
- Configuración SQL, dependencias fijadas y diagnóstico de conexión Python implementados.
- Base SQL Server de desarrollo creada con 68 tablas y un inicializador con migraciones.
- Demo funcional de escritorio con FastAPI y PySide6: importación, planeación, picking, packing, staging y embarque.
- Interfaz guiada de cinco secciones, productos de tienda, pedidos con valores sugeridos y destinos por kilómetros desde almacén.
- Abrir **Iniciar Demo.cmd**. Consultar [guía de la demo](docs/demo-escritorio.md).
- El archivo real de SAP y varias reglas operativas siguen pendientes de validación.

## Arquitectura

La app de escritorio Python se comunica con FastAPI. El backend aplica las reglas y accede a SQL Server.
La app podrá enviar el archivo seleccionado; Python interpreta y valida su contenido.
La entrada será CSV/TXT exportado de SAP y entregado para importación manual.

```text
CSV/TXT -> Importador Python -> SQL Server (staging y operación)
                                     ^
                                     |
                                  FastAPI
                                     ^
                                     |
                          Python / PySide6 Windows
```

No se incluye web, conexión directa a SAP ni operación offline en la primera versión.

## Carpetas

| Carpeta | Responsabilidad |
| --- | --- |
| backend/app/api | Endpoints de FastAPI. |
| backend/app/core | Configuración, seguridad y errores. |
| backend/app/models | Modelos de persistencia. |
| backend/app/schemas | Contratos de entrada y salida. |
| backend/app/repositories | Acceso a SQL Server. |
| backend/app/services | Reglas de negocio. |
| backend/app/integrations | Importación de archivos. |
| backend/tests | Pruebas del backend. |
| frontend | Interfaz nativa Python/PySide6 de escritorio. |
| database/schema | Definición documentada del modelo. |
| database/migrations | Cambios ordenados y versionados de la base. |
| database/seed | Datos iniciales mínimos y ficticios. |
| database/queries | Consultas de apoyo. |
| samples/csv y samples/txt | Muestras exclusivamente ficticias. |
| docs | Arquitectura, requerimientos, diagramas y pruebas. |
| scripts | Herramientas de preparación. |

Los archivos .gitkeep conservan en Git las carpetas que aún están vacías.

## Preparar otra computadora

Consultar [Preparación local](docs/arquitectura/preparacion-local.md).
Cada desarrollador tendrá su entorno Python, su archivo backend/.env y su propia base de prueba.
GitHub comparte código y scripts, no sincroniza las bases de datos.

El archivo [backend/.env.example](backend/.env.example) contiene la plantilla de configuración.
El backend lee backend/.env y las variables SQL_ del proceso.
Consultar [Conexión SQL](docs/arquitectura/conexion-sql.md) para instalar dependencias y comprobar la instancia o la base.

## Trabajo entre dos personas

Consultar [Guía de colaboración](docs/colaboracion.md).
El flujo será una rama por tarea, cambios pequeños y revisión por la otra persona antes de integrar a main.

Repositorio: https://github.com/luisssssssssssssss/picking-packing-embarques

## Próximo resultado verificable

Validar el recorrido de la demo con el usuario y ajustar reglas contra un archivo real.
El incremento actual ya importa datos ficticios y registra las operaciones de extremo a extremo.

La configuración vive en el backend. Las credenciales SQL no se compartirán con Flutter
ni se guardarán en Git. backend/requirements.txt fija las dependencias Python.

## Documentación del alcance

- [AGENTS.md](AGENTS.md): arquitectura y reglas del proyecto.
- [Plan de trabajo](docs/requerimientos/plan-de-trabajo.md): propuesta de módulos y alcance.
- Los campos y reglas que dependan del negocio se mantienen como propuestas hasta su validación.

## Diseño de la base de datos

Se preparó un [esquema lógico propuesto](database/schema/esquema-logico.md) con planeación, importación, Picking, Packing y embarques. Incluye [diagramas de relaciones](docs/diagramas/modelo-datos.md), [diccionario de tablas](database/schema/diccionario-tablas.md), [modelo DBML](database/schema/modelo-logico.dbml) y [casos de aceptación](docs/pruebas/casos-modelo-datos.md).

El modelo 0.2 ya tiene una implementación SQL inicial. Consultar [instalación y migraciones](database/migrations/README.md) y [planeación de capacidad diaria](database/schema/capacidad-diaria.md). Las reglas de negocio agregadas se implementarán en el backend; las decisiones pendientes siguen separadas del alcance inicial.

## Datos ficticios para revisar el modelo

Consultar [muestras y comprobación local](samples/README.md) y el [recorrido explicado](docs/pruebas/recorrido-demo.md). Se prepararon CSV/TXT y un escenario ficticio con pedidos, dos almacenes y dos viajes; la nueva muestra demo_escritorio.csv sí se carga en SQL Server mediante la demo.


## Paquete para compartir por WhatsApp

[Base_Datos_Desarrollo_v0.2.zip](database/distribucion/Base_Datos_Desarrollo_v0.2.zip) contiene un script SQL autónomo para SSMS y una guía. Permite preparar la misma estructura sin Python; no contiene credenciales ni datos operativos. Se genera desde las migraciones con:

```powershell
& backend/.venv/Scripts/python.exe -m scripts.empaquetar_base
```

El paquete 0.2 se comprobó en una base temporal: creación de 68 tablas, repetición sin duplicar los 6 roles y coincidencia de hashes con el inicializador Python. Se eliminó únicamente esa base temporal después de la prueba. La base de desarrollo existente se conservó.

## Ejecución de escritorio

Doble clic en [Iniciar Demo.cmd](Iniciar%20Demo.cmd). El acceso usa Python; el ejecutable generado fue bloqueado por la política de aplicaciones de Windows. No se incluyeron credenciales en el binario. Consulta [alcance y pruebas](docs/demo-escritorio.md). El repositorio incluye el código y los scripts; cada equipo instala sus dependencias y conserva su configuración local.
