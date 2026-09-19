# AGENTS.md — Proyecto de Picking, Packing y Embarques

## 1. Objetivo general

Construir una aplicación multiplataforma para administrar y dar trazabilidad al proceso de almacén:

1. Recepción de información desde archivo plano CSV o TXT.
2. Importación y validación de la información.
3. Generación de tareas de Picking.
4. Ejecución y confirmación de Picking.
5. Proceso de Packing.
6. Manejo de Staging / preembarque.
7. Asignación y carga a tráiler.
8. Cierre de embarque.
9. Consulta de estatus, incidencias y trazabilidad.
10. Operación desde celular, tablet y PC.

El sistema debe desarrollarse con código, no como solución low-code.

---

## 2. Arquitectura tecnológica acordada

### Frontend
- Flutter
- Lenguaje: Dart
- Debe poder ejecutarse como:
  - Android: aplicación instalable para celular y tablet.
  - Windows: aplicación instalable para PC.
- La versión web queda fuera del alcance actual. Solo se evaluará si el cliente la solicita posteriormente.
- Diseño responsive.
- La misma solución debe adaptar la interfaz de acuerdo con el tamaño de pantalla y el rol del usuario.

### Backend
- Python
- FastAPI
- API REST
- Las reglas de negocio principales deben vivir en el backend, no solamente en Flutter.

### Base de datos
- Microsoft SQL Server
- Usar SQL para tablas, relaciones, índices, vistas y procedimientos cuando sea conveniente.
- Separar conceptualmente:
  - Integración / Staging
  - Operación
  - Catálogos
  - Auditoría

### Fuente de información
- Archivo plano CSV o TXT.
- El archivo será generado por un sistema externo.
- Todavía no existe una muestra real del archivo.
- Durante el desarrollo se utilizarán archivos ficticios de prueba.
- El sistema debe permitir adaptar posteriormente el mapeo de columnas sin rediseñar toda la aplicación.

### Control de versiones
- Git
- Repositorio local desde el inicio.
- Evitar cambios gigantes en un solo commit.
- Los commits deben ser pequeños y descriptivos.

---

## 3. Principios del proyecto

1. No desarrollar todo de una sola vez.
2. Construir módulos pequeños y verificables.
3. No asumir estructura definitiva del CSV/TXT hasta recibir una muestra real.
4. No acoplar la base de datos al formato exacto del archivo plano.
5. No permitir que Flutter se conecte directamente a SQL Server.
6. Flutter solo debe comunicarse con FastAPI.
7. La aplicación nunca debe leer directamente el CSV/TXT.
8. Python procesa el archivo y escribe en SQL Server.
9. FastAPI aplica reglas de negocio y expone la información al frontend.
10. Toda operación importante debe dejar trazabilidad.
11. Antes de modificar código existente, revisar la arquitectura y las dependencias.
12. Antes de crear una nueva librería o tecnología, justificar por qué se necesita.
13. Preferir soluciones simples y mantenibles.
14. No introducir microservicios mientras no exista una necesidad real.
15. Mantener secretos, passwords y cadenas de conexión fuera del código fuente.

---

## 4. Arquitectura lógica

Flujo principal:

Sistema origen
    ↓
CSV / TXT
    ↓
Servicio de integración en Python
    ↓
Tablas de Staging en SQL Server
    ↓
Validaciones
    ↓
Tablas operacionales
    ↓
FastAPI
    ↓
Flutter
    ↓
Celular / Tablet / PC

No conectar:

Flutter → SQL Server

Sí conectar:

Flutter → FastAPI → SQL Server

---

## 5. Estructura inicial del repositorio

Mantener una estructura similar a:

proyecto/
│
├── AGENTS.md
├── README.md
├── .gitignore
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── core/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── repositories/
│   │   ├── services/
│   │   └── integrations/
│   ├── tests/
│   └── requirements.txt
│
├── frontend/
│   └── Flutter application
│
├── database/
│   ├── schema/
│   ├── migrations/
│   ├── seed/
│   └── queries/
│
├── samples/
│   ├── csv/
│   └── txt/
│
├── docs/
│   ├── arquitectura/
│   ├── requerimientos/
│   ├── diagramas/
│   └── pruebas/
│
└── scripts/

La estructura puede evolucionar, pero no debe cambiarse sin una razón clara.

---

## 6. Roles iniciales del sistema

### Administrador
Puede:
- Gestionar usuarios.
- Gestionar roles.
- Gestionar catálogos.
- Revisar auditoría.
- Consultar configuración.
- Consultar importaciones.

### Supervisor
Puede:
- Consultar pedidos.
- Consultar Picking.
- Consultar Packing.
- Consultar Staging.
- Consultar Embarques.
- Revisar incidencias.
- Visualizar avance general.

### Montacarguista
Puede:
- Consultar tareas de Picking asignadas.
- Iniciar tarea.
- Escanear ubicación.
- Escanear material.
- Capturar o confirmar cantidad.
- Confirmar Picking.
- Registrar incidencia.

### Packing
Puede:
- Consultar pedidos disponibles para Packing.
- Recibir material proveniente de Picking.
- Validar cantidades.
- Crear unidades de manejo / Handling Units.
- Confirmar Packing.
- Enviar material a Staging.
- Registrar incidencia.

### Embarques
Puede:
- Consultar tráileres y andenes.
- Asignar pedido o unidad de manejo.
- Escanear carga.
- Validar que el material esté autorizado.
- Registrar número de sello si aplica.
- Cerrar embarque.

---

## 7. Flujo de estados propuesto

Estados principales:

CREATED
RELEASED
PICKING_ASSIGNED
PICKING_IN_PROGRESS
PICKED
PACKING_IN_PROGRESS
PACKED
STAGING
ASSIGNED_TO_TRAILER
LOADING
LOADED
SHIPPED

Estados de excepción:

SHORTAGE
DAMAGED
WRONG_MATERIAL
WRONG_LOCATION
HOLD
PARTIAL
CANCELLED

Los nombres definitivos pueden cambiar cuando se conozca el proceso real del cliente.

---

## 8. Modelo de datos inicial

No generar todavía un modelo excesivamente complejo.

Entidades iniciales sugeridas:

### Catálogos
- User
- Role
- Material
- Location
- Dock
- IncidentType

### Operación
- Order
- OrderDetail
- PickingTask
- PickingDetail
- HandlingUnit
- HandlingUnitDetail
- StagingMovement
- Trailer
- Shipment
- ShipmentDetail
- InventoryMovement
- Incident

### Integración
- ImportedFile
- StagingOrder
- ImportError

### Auditoría
- AuditLog

Los nombres físicos de tablas pueden estar en inglés para mantener consistencia técnica.

---

## 9. Archivo plano

Todavía no existe el archivo real.

Crear archivos ficticios para desarrollo.

### Ejemplo CSV inicial

NumeroPedido,Fecha,Cliente,Destino,Material,Descripcion,Cantidad,UnidadMedida,Ubicacion,Lote
450001,2026-09-19,Cliente A,Planta A,MAT001,Pieza soporte,1000,PZA,R01-A01,L001
450001,2026-09-19,Cliente A,Planta A,MAT002,Tornillo M8,500,PZA,R01-A04,L002
450002,2026-09-19,Cliente B,Planta B,MAT005,Ensamble lateral,800,PZA,R03-B02,L003

### Ejemplo TXT inicial

450001|2026-09-19|Cliente A|Planta A|MAT001|Pieza soporte|1000|PZA|R01-A01|L001

La aplicación debe permitir posteriormente mapear columnas del archivo real a campos internos.

Ejemplo:

ORD_NO → NumeroPedido
PART_NO → Material
QTY_REQ → Cantidad
LOC → Ubicacion
SHIP_TO → Destino

---

## 10. Importador de archivos

El importador debe ser un módulo independiente del API.

Responsabilidades:

1. Detectar o recibir archivo.
2. Registrar archivo recibido.
3. Calcular hash SHA-256.
4. Validar que el archivo no haya sido procesado antes.
5. Validar estructura.
6. Leer registros.
7. Cargar datos a Staging.
8. Validar información.
9. Registrar errores por fila.
10. Insertar o actualizar información operacional.
11. Registrar resultado de importación.
12. Mover el archivo a procesados o errores.

Carpetas sugeridas:

incoming/
processing/
processed/
error/

Todavía no implementar monitoreo continuo hasta definir cómo entregará el archivo el sistema origen.

---

## 11. Validaciones mínimas del archivo

Como punto de partida:

- Número de pedido obligatorio.
- Material obligatorio.
- Cantidad mayor que cero.
- Fecha válida.
- Evitar duplicados.
- Validar ubicación cuando exista catálogo de ubicaciones.
- Registrar errores sin detener todo el archivo cuando sea posible.
- Conservar número de línea del archivo para rastrear errores.

---

## 12. Reglas de negocio fundamentales

### Picking
No confirmar una cantidad superior a la pendiente.

Validar:
- Pedido existente.
- Tarea activa.
- Ubicación correcta.
- Material correcto.
- Cantidad válida.
- Usuario autorizado.

### Packing
No empacar más material del que haya sido correctamente recibido desde Picking.

Validar:
- Pedido.
- Material.
- Cantidad disponible.
- Estado permitido.

### Handling Unit
Cada unidad de manejo debe contar con identificador único.

Ejemplo:
HU-00000001

### Embarque
No cargar una Handling Unit si:
- No existe.
- No está empacada.
- No está liberada.
- No pertenece al pedido.
- Ya fue cargada.
- El tráiler está cerrado.

### Auditoría
Registrar acciones críticas:
- Inicio de Picking.
- Confirmación de Picking.
- Inicio de Packing.
- Creación de HU.
- Movimiento a Staging.
- Carga a tráiler.
- Cierre de tráiler.
- Cambios manuales.
- Incidencias.

---

## 13. Lectura de QR y códigos de barras

Flutter deberá soportar lectura mediante:

- Cámara del dispositivo.
- Scanner Bluetooth.
- Scanner USB cuando funcione como teclado.

Elementos potenciales a escanear:

- Ubicación.
- Material.
- Handling Unit.
- Andén.
- Tráiler.

No diseñar flujos dependientes exclusivamente de cámara.

---

## 14. Offline

La operación offline es deseable pero no debe implementarse en la primera iteración.

Primero lograr:

1. CSV/TXT → SQL Server.
2. SQL Server → FastAPI.
3. FastAPI → Flutter.
4. Picking funcional.
5. Packing funcional.
6. Embarque funcional.

Después evaluar:
- SQLite local.
- Cola de sincronización.
- Resolución de conflictos.
- Reintentos.

---

## 15. API inicial propuesta

La API real se definirá conforme avance el modelo.

Endpoints de referencia:

GET /health

POST /auth/login

GET /orders
GET /orders/{id}

GET /picking/tasks
GET /picking/tasks/{id}
POST /picking/tasks/{id}/start
POST /picking/tasks/{id}/confirm

GET /packing/pending
POST /packing/start
POST /packing/confirm

POST /handling-units
GET /handling-units/{code}

GET /shipments
GET /shipments/{id}
POST /shipments/{id}/load
POST /shipments/{id}/close

GET /incidents
POST /incidents

GET /imports
GET /imports/{id}

No implementar todos los endpoints al inicio.

---

## 16. Seguridad

Desde el inicio:

- No guardar contraseñas en texto plano.
- No guardar cadena de conexión SQL en el repositorio.
- Usar variables de entorno.
- Preparar `.env.example`.
- No subir `.env` a Git.
- Validar permisos en backend.
- No confiar únicamente en ocultar botones en Flutter.
- Cada endpoint sensible debe validar autorización.

Autenticación:
- Inicialmente puede usarse JWT.
- Si posteriormente el cliente requiere Microsoft Entra ID / Azure AD, evaluar migración.

---

## 17. SQL Server

Usar SQL Server como fuente persistente de verdad.

Buenas prácticas:

- Claves primarias claras.
- Foreign keys.
- Índices según consultas reales.
- Constraints donde agreguen integridad.
- Campos CreatedAt / UpdatedAt.
- Evitar lógica de negocio repartida de forma confusa entre triggers, backend y frontend.
- Preferir que las reglas de negocio principales estén en Python.
- SQL debe asegurar integridad de datos.

No crear stored procedures innecesariamente.

---

## 18. FastAPI

Organización sugerida:

api/
- Endpoints.

services/
- Reglas de negocio.

repositories/
- Acceso a datos.

models/
- Modelos de base.

schemas/
- Modelos Pydantic.

integrations/
- Importadores CSV/TXT y futuras integraciones.

core/
- Configuración.
- Seguridad.
- Logging.
- Excepciones.

No colocar toda la aplicación en main.py.

---

## 19. Flutter

La aplicación debe ser responsive.

Móvil:
- Pantallas simples.
- Botones grandes.
- Flujo orientado a operación.
- Pocas acciones por pantalla.
- Escaneo rápido.

PC:
- Más información simultánea.
- Tablas.
- Filtros.
- Dashboard.
- Supervisión.

No duplicar la lógica de negocio del backend.

Flutter puede realizar validaciones de UX, pero FastAPI debe volver a validar las operaciones.

---

## 20. Testing

Agregar pruebas desde las primeras fases.

Prioridad:

### Backend
- Pruebas de importación.
- Validaciones.
- Reglas de Picking.
- Reglas de Packing.
- Reglas de Shipping.

### Datos de prueba
Crear:

samples/
- pedidos_correctos.csv
- pedidos_duplicados.csv
- pedidos_con_errores.csv
- pedidos_actualizados.csv
- pedidos.txt

Probar:
- Archivo vacío.
- Columnas faltantes.
- Cantidad negativa.
- Material vacío.
- Duplicados.
- Archivo repetido.
- Formato de fecha incorrecto.

---

## 21. Primera fase de implementación

NO comenzar creando todas las pantallas.

Orden recomendado:

### Fase 0 — Preparación
1. Inicializar Git.
2. Crear estructura de carpetas.
3. Crear README.
4. Crear .gitignore.
5. Crear entorno virtual Python.

### Fase 1 — Base de datos
1. Diseñar modelo mínimo.
2. Crear base SQL Server de desarrollo.
3. Crear tablas iniciales.
4. Crear datos semilla mínimos.

### Fase 2 — Integración
1. Crear CSV ficticio.
2. Leer CSV en Python.
3. Validar registros.
4. Guardar Staging.
5. Registrar errores.
6. Crear pedidos.

### Fase 3 — Backend
1. FastAPI.
2. Endpoint /health.
3. Configuración SQL Server.
4. Endpoint GET /orders.
5. Pruebas.

### Fase 4 — Flutter
1. Crear proyecto.
2. Pantalla base.
3. Cliente HTTP.
4. Consumir /health.
5. Consumir /orders.

### Fase 5 — Picking
Construir flujo completo antes de pasar a Packing.

### Fase 6 — Packing

### Fase 7 — Staging y embarques

### Fase 8 — Supervisor

### Fase 9 — Offline y mejoras

---

## 22. Qué debe hacer Codex antes de programar

Antes de una tarea grande:

1. Leer este AGENTS.md.
2. Revisar estructura existente.
3. Revisar README.
4. Revisar código relacionado.
5. Explicar brevemente el plan.
6. Modificar solamente lo necesario.
7. Ejecutar pruebas.
8. Reportar:
   - archivos creados;
   - archivos modificados;
   - pruebas ejecutadas;
   - resultado;
   - pendientes.

No rehacer partes funcionales sin necesidad.

---

## 23. Reglas para cambios

Codex NO debe:

- Cambiar de stack sin autorización.
- Sustituir SQL Server por PostgreSQL, SQLite u otra base principal.
- Sustituir FastAPI por otro framework sin autorización.
- Sustituir Flutter por React Native, Electron, .NET MAUI u otro frontend sin autorización.
- Agregar servicios cloud por defecto.
- Agregar Docker únicamente porque sí.
- Implementar Kubernetes.
- Crear microservicios prematuramente.
- Implementar una arquitectura exageradamente compleja.
- Inventar campos del archivo real como si fueran definitivos.
- Eliminar código o datos sin explicar el impacto.
- Exponer secretos.
- Poner reglas críticas únicamente en Flutter.

---

## 24. Convenciones generales

### Python
- Código legible.
- Type hints.
- Pydantic.
- Manejo centralizado de errores.
- Logging.
- Funciones y clases pequeñas.
- Nombres en inglés para código.

### SQL
- Nombres consistentes.
- Scripts repetibles cuando sea posible.
- No usar SELECT * en código productivo salvo casos justificados.

### Flutter / Dart
- Componentes reutilizables.
- Separar UI, estado y servicios.
- Mantener responsive design.

### Documentación
- Explicar decisiones importantes.
- Actualizar README cuando cambie la forma de ejecutar el proyecto.

---

## 25. Contexto actual

Estado del proyecto:

- El proyecto está comenzando.
- Existe una carpeta local creada por el usuario.
- Todavía no existe código.
- Todavía no existe CSV/TXT real.
- Todavía no existe modelo definitivo de base de datos.
- Todavía no se han confirmado todas las reglas del proceso del cliente.
- El flujo conceptual es:
  Picking → Packing → Staging → Trailer → Embarque.
- El cliente quiere una aplicación instalable/utilizable en celular y PC.
- El cliente solicitó desarrollo con lenguaje de programación.
- SQL Server es la base de datos elegida.
- Python + FastAPI es el backend elegido.
- Flutter + Dart es el frontend elegido.
- CSV/TXT será la fuente inicial de información.

---

## 26. Primera instrucción recomendada para Codex

Cuando Codex abra este proyecto por primera vez, pedirle:

"Lee AGENTS.md completo y revisa la carpeta actual. No programes todavía. Resume la arquitectura que entiendes, señala cualquier ambigüedad importante y propón únicamente la estructura inicial del repositorio y los primeros cinco pasos de implementación. No cambies el stack definido."

Después de revisar su respuesta, continuar con tareas pequeñas.

---

## 27. Prioridad principal

El objetivo no es producir la mayor cantidad de código posible.

El objetivo es construir un sistema:

- entendible;
- trazable;
- mantenible;
- probado;
- adaptable al archivo real del cliente;
- usable en operación de almacén;
- seguro para crecer posteriormente.

Siempre preferir una implementación sencilla, comprobable y consistente con el proceso real.
