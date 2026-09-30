# Plan de trabajo y alcance de la primera versión

Fecha: 2026-09-19.
Estado: propuesta para revisar antes de programar funcionalidades.
Referencia: AGENTS.md y decisiones acordadas en la conversación del proyecto.

## 1. Objetivo

Construir una aplicación instalable para celulares y tablets Android y computadoras Windows que permita seguir un pedido desde su importación hasta el cierre de su embarque:

Archivo CSV/TXT exportado de SAP y entregado por una persona → Importación manual y validación → Pedido → Picking → Packing → Preembarque → Carga a tráiler → Cierre de embarque.

El stack se mantiene: Flutter/Dart, Python/FastAPI y Microsoft SQL Server. La versión web queda fuera del alcance actual.

La primera versión completa se entregará por módulos. Las primeras demostraciones solo tendrán las funciones de las etapas terminadas; todavía no serán una solución lista para operar todo el almacén.

## 2. Estado actual

- Git local y repositorio privado de GitHub configurados.
- Rama main sincronizada con el commit inicial.
- AGENTS.md y .gitignore registrados.
- Todavía no hay aplicación, backend ni base de datos del proyecto.
- El usuario dispone de SQL Server local para desarrollar; falta verificar su instancia y autenticación y crear la base del proyecto.
- No se dispone de acceso al servidor de Nemak y el desarrollo no dependerá de ese acceso.
- No existe una muestra real del archivo del cliente.
- Falta incorporar al segundo desarrollador cuando tenga cuenta de GitHub.

## 3. Qué podrá hacer la primera versión completa

| Área | Funciones previstas | Control principal |
| --- | --- | --- |
| Acceso | Iniciar sesión; gestionar usuarios, roles y catálogos necesarios. | El backend valida permisos por operación. |
| Importación | Recibir manualmente archivos CSV/TXT exportados de SAP, sin conectarse a SAP, y procesarlos mediante Python, crear pedidos, consultar resultados y errores por línea. Adaptar el mapeo cuando llegue el archivo real. | Detectar archivos ya procesados y validar campos obligatorios, fechas y cantidades. Las reglas de corrección de pedidos se acordarán antes de implementarlas. |
| Pedidos | Consultar encabezado, materiales, cantidades y avance del proceso. | Todos los dispositivos consultan la misma información persistida en SQL Server. |
| Picking | Generar y asignar tareas; consultar tareas asignadas; iniciar, validar ubicación y material, confirmar cantidades y registrar incidencias. | Rechazar cantidades superiores a las pendientes y acciones no autorizadas o fuera de estado. |
| Packing | Recibir material del Picking, validar cantidades y crear unidades de manejo (HU), por ejemplo cajas o tarimas, según el proceso del cliente. | No empacar más de lo recibido y asignar un identificador único a cada HU. |
| Preembarque | Registrar el movimiento de las HU a una ubicación de espera y consultar su estado. | Conservar el historial de movimientos y validar el estado permitido. |
| Embarques | Gestionar los datos necesarios de tráiler y andén, asignar HU, escanear carga, registrar sello cuando aplique y cerrar el embarque. | Rechazar HU inexistentes, no empacadas, no liberadas, ajenas al pedido, ya cargadas o destinadas a un tráiler cerrado. |
| Supervisión | Consultar avance, pendientes e incidencias por pedido o etapa. | Presentar información consistente con las operaciones registradas. |
| Auditoría | Consultar usuario, fecha, hora y resultado de las acciones críticas. | Registrar la auditoría desde cada módulo, no añadirla al final. |

La consulta y gestión de cada área respetará los roles de Administrador, Supervisor, Montacarguista, Packing y Embarques definidos en AGENTS.md.

Se contempla lectura con cámara y lectores Bluetooth/USB compatibles. Los lectores que funcionan como teclado tendrán un flujo de captura adecuado. Se probarán los modelos reales antes de prometer compatibilidad; la operación no dependerá exclusivamente de cámara.

## 4. Cómo funcionarán las apps

- En Android: pantallas de operación, botones grandes y captura rápida.
- En Windows: consultas con más información, filtros y funciones de administración y supervisión según el rol.
- Ambas se comunicarán con FastAPI, y FastAPI accederá a SQL Server.
- El importador Python procesará los archivos; Flutter no leerá ni interpretará directamente CSV/TXT.
- Durante el desarrollo, la propia PC del usuario ejecutará Python/FastAPI y accederá a su SQL Server local. A ese servicio de FastAPI se refiere la palabra servidor; no implica un servidor de Nemak ni un servicio cloud.
- La app Windows podrá comunicarse con FastAPI en esa misma PC. El celular se comunicará con FastAPI mediante la dirección de la PC en una red accesible; la PC y los servicios deberán estar encendidos. La primera versión no operará sin conexión al backend.
- GitHub compartirá código e historial de desarrollo. Los pedidos, credenciales y la base de datos operativa no se almacenarán en GitHub.

### Configuración y preparación de otra instalación

Se incluirá una herramienta de instalación en Python para preparar el backend y la base de datos. El flujo previsto es:

1. Disponer de una instancia de SQL Server instalada y accesible en el equipo elegido.
2. Configurar instancia/servidor, nombre de base y tipo de autenticación. Cuando se use autenticación SQL se indicarán usuario y contraseña; también se evaluará autenticación Windows según el entorno.
3. Guardar esa configuración únicamente en el backend, mediante variables de entorno o un archivo local .env excluido de Git. requirements.txt contendrá las dependencias Python, no la conexión SQL.
4. Ejecutar el inicializador: comprobar conexión y permisos, crear la base si no existe y preparar tablas, relaciones y datos iniciales. Si no hay permisos para crear bases, usar una base vacía provisionada por un administrador con los permisos necesarios para preparar sus objetos.
5. Reconocer una instalación existente sin borrar ni sobrescribir datos; aplicar únicamente migraciones pendientes y compatibles. La inicialización será un paso de instalación, no una acción que cada celular ejecute al iniciar.
6. Iniciar FastAPI y configurar las apps con su dirección. Las apps no tendrán credenciales de SQL Server ni se conectarán directamente a la base.

La cuenta utilizada para preparar la base podrá requerir más permisos que la cuenta de operación habitual del backend. Cambiar la configuración permite apuntar a otra base o instancia de SQL Server; trasladar información histórica requiere un procedimiento separado de respaldo/restauración o migración de datos. Otro motor de base de datos implicaría revisar el stack y no forma parte de este cambio.

Cada desarrollador podrá usar una base local de prueba. Compartir el repositorio no sincroniza los datos de esas bases.

### Entrada de archivos de SAP

Una persona entregará las exportaciones y un usuario autorizado iniciará su importación. La interfaz podrá seleccionar y enviar el archivo al backend sin interpretar sus columnas; Python realizará la lectura, el mapeo y todas las validaciones. Se conservarán el resultado y los errores de cada importación. No se utilizará un conector SAP ni se solicitarán credenciales de SAP. El formato definitivo sigue pendiente de una muestra real.

## 5. Qué queda fuera del alcance inicial

| Función | Límite propuesto |
| --- | --- |
| Web, iPhone/iPad y macOS | Los destinos iniciales son Android y Windows. Otras plataformas requerirían ampliar el alcance. |
| Operación offline | No se confirmarán operaciones sin conexión al servidor. La sincronización posterior se evaluará después del flujo completo. |
| Conexión directa con SAP u otros sistemas | La entrada será la importación manual de archivos exportados de SAP y entregados por una persona. No se incluye consultar SAP ni escribir resultados en SAP. |
| Monitoreo continuo de carpetas | Se empezará con importación manual controlada; la automatización dependerá de cómo se entreguen los archivos. |
| Inventario integral | Se registrarán las cantidades y movimientos necesarios para este flujo. No se incluyen inicialmente compras, recepción física de mercancía, inventarios cíclicos, reabasto ni valuación. |
| Facturación, contabilidad y transporte | No se incluyen facturas, costos de flete, optimización de rutas ni seguimiento del transporte después del cierre del embarque. |
| Detección física automática | El sistema conocerá lo capturado o escaneado. No localizará mercancía físicamente ni identificará daños por sí solo. |
| Impresión e integraciones con equipos | Se generan identificadores de HU. La impresión de etiquetas, impresoras térmicas, básculas y otros equipos necesita requisitos y pruebas específicos. |
| Reglas aún desconocidas | No se decidirán automáticamente faltantes, sustituciones, cancelaciones, liberaciones o cambios de pedidos en operación sin definir primero quién puede hacerlos y bajo qué condiciones. |

Estas exclusiones delimitan la primera entrega; no significan que todas esas funciones sean técnicamente imposibles en una etapa posterior.

## 6. Etapas de trabajo y entregables

Se conserva el orden de AGENTS.md. Cada etapa se divide en tareas pequeñas y se verifica antes de continuar con el módulo dependiente.

| Etapa | Trabajo | Resultado verificable |
| --- | --- | --- |
| 0. Preparación y reglas iniciales | Completar estructura, README, configuración de ejemplo y entorno Python. Documentar el proceso normal, responsables y decisiones pendientes. Incorporar al compañero cuando tenga cuenta. Git ya está preparado. | Instrucciones reproducibles para preparar el proyecto en las dos computadoras, sin compartir secretos. |
| 1. Base de datos mínima | Verificar el SQL Server local, diseñar la configuración y el inicializador de instalación. Preparar scripts para importaciones, filas de staging, errores, pedidos, detalle y auditoría; añadir catálogos necesarios. | Crear la base configurada y sus objetos cuando haya permisos; repetir la inicialización sin perder datos y validar el mismo proceso en otra base de prueba. |
| 2. Integración | Crear muestras ficticias CSV/TXT y el importador independiente, con mapeo configurable, hash, validación, staging, errores y carga de pedidos. Definir el tratamiento de reintentos y actualizaciones antes de activarlos. | Un archivo válido crea pedidos; uno inválido informa línea y motivo; repetir uno ya procesado no duplica datos. |
| 3. Backend y seguridad inicial | Crear FastAPI por capas, configuración, conexión SQL Server, health, consulta de pedidos y autenticación/autorización antes de exponer información operativa. Ampliar los endpoints conforme avance cada módulo. | La API consulta datos reales de SQL Server y rechaza accesos no autorizados. |
| 4. Apps base | Crear Flutter para Android y Windows, inicio de sesión, estado de conexión y consulta de pedidos. | Una instalación Android y una Windows consultan los mismos pedidos a través de la API. |
| 5. Picking completo | Crear tareas y asignación, inicio, escaneo/captura, confirmación, incidencias y auditoría. Definir las transiciones y permisos de liberación. | Un operador completa el Picking y el sistema bloquea materiales, ubicaciones y cantidades incorrectos. Validar este flujo antes de Packing. |
| 6. Packing completo | Recibir cantidades válidas, formar HU, confirmar Packing y conservar trazabilidad. | Las HU tienen código único y sus cantidades no superan lo recibido desde Picking. |
| 7. Preembarque y embarques | Mover a preembarque, asignar HU a tráiler, validar carga y cerrar el embarque. | Completar el recorrido de un pedido y rechazar cargas duplicadas, ajenas o sobre un tráiler cerrado. |
| 8. Supervisión y piloto | Completar consultas de avance, incidencias y auditoría. Probar instalación, permisos, lectores, concurrencia y recuperación con usuarios y equipos reales. Documentar operación, instalación y respaldo/restauración. | Demostrar el flujo completo en el almacén con evidencia de pruebas y validación del cliente antes del uso productivo. |

La fase 9 de AGENTS.md, offline y mejoras, queda para una evaluación posterior y no forma parte de la primera versión completa.

Pruebas, seguridad y auditoría se desarrollan junto con cada módulo. No se reservan únicamente para el piloto.

## 7. Criterios de aceptación de la primera versión

1. Importar muestras correctas y detectar archivo vacío, columnas faltantes, material vacío, cantidad negativa, fecha inválida y duplicados según las reglas acordadas.
2. Consultar los mismos pedidos desde Android y Windows, con permisos aplicados en el backend.
3. Completar un pedido desde importación hasta cierre de embarque y consultar su historial.
4. Rechazar Picking superior a lo pendiente, Packing superior a lo recibido y carga duplicada o no autorizada.
5. Probar dos operadores sobre una misma tarea o HU: no permitir que el uso simultáneo exceda cantidades ni duplique la carga.
6. Ante pérdida de conexión o repetición de una confirmación, no mostrar un éxito falso ni duplicar la operación; permitir comprobar el resultado real.
7. Registrar usuario y momento de cada acción crítica, además de incidencias y cambios manuales autorizados.
8. Probar los lectores y dispositivos seleccionados, la instalación y la restauración de un respaldo de desarrollo antes del piloto productivo.
9. Configurar otra base de SQL Server, inicializarla con permisos adecuados y repetir el proceso sin borrar información. Si faltan permisos, mostrar el motivo y detener la preparación sin simular que fue exitosa.

## 8. Decisiones pendientes con el cliente

- Exportación real de SAP: columnas, codificación, separador, fechas, decimales y frecuencia de entrega manual. No se necesita acceso directo a SAP.
- Identificador de línea: cómo distinguir materiales o lotes repetidos dentro de un pedido.
- Importación parcial: aceptar filas o pedidos completos; reintentos y correcciones cuando hay operaciones iniciadas.
- Catálogos: fuente y responsable de materiales, ubicaciones, andenes y usuarios; tratamiento de códigos desconocidos.
- Operación: asignación de tareas, liberación, faltantes, daños, parciales, cancelaciones y reapertura o corrección de errores.
- HU: caja/tarima u otra unidad, contenido permitido, identificación, reutilización de etiquetas y necesidad de impresión.
- Infraestructura: instancia y autenticación del SQL Server local; equipo donde se instalará una futura operación compartida, red/Wi-Fi, equipos Android/Windows y modelos de lectores. El desarrollo no requiere acceso al servidor de Nemak.
- Volumen: pedidos y líneas por día, tamaño de archivos y número de usuarios simultáneos.
- Puesta en operación: responsable de respaldos, restauración, soporte e instalación/actualización de las apps.

Se resolverán las decisiones antes del módulo que dependa de ellas. Mientras llega el archivo real pueden avanzar la preparación y las pruebas con muestras identificadas como ficticias.

## 9. Forma de trabajo entre dos personas

- Una tarea pequeña y verificable a la vez por persona, con una rama propia.
- Actualizar main antes de iniciar una rama y evitar que ambos cambien simultáneamente el mismo módulo sin coordinarse.
- Revisar la propuesta de API y base de datos antes de dividir trabajo entre backend y Flutter.
- Usar commits descriptivos y revisar los cambios antes de incorporarlos a main.
- Mantener credenciales propias, configuración local excluida de Git y datos ficticios para desarrollo.
- Definir quién se encarga de cada tarea según disponibilidad y experiencia; todavía no se asignan responsabilidades permanentes.
- Al cerrar cada etapa: demostración, pruebas apropiadas, documentación de ejecución y pendientes visibles.

## 10. Estimación y siguiente paso

No se fija todavía una fecha de entrega: faltan las reglas operativas, el archivo real, el entorno y las horas disponibles de ambos desarrolladores. El siguiente paso es revisar este alcance con el usuario y el cliente, y desglosar la etapa 0 en tareas pequeñas. Las fechas se estimarán por etapa con esas dependencias identificadas.
