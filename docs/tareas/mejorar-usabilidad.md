# Próximos pasos: hacer la demo más fácil de entender

Guía para trabajar entre dos personas · 2 de octubre de 2026.

## Punto de partida

La aplicación de escritorio ya tiene pantalla de montacarguista, resumen del supervisor, filtros y seguimiento de tarimas. Esas mejoras están en main. Esta guía describe trabajo **pendiente**, no funciones ya implementadas.

Objetivo: que una persona nueva entienda qué debe hacer, dónde hacerlo y cómo confirmar, sin ayuda. En este incremento solo mejoramos presentación, textos y navegación. Conservamos Python/PySide6, FastAPI y SQL Server; no agregamos tablas, dependencias ni app móvil.

## Antes de tocar código

1. Leer AGENTS.md y [la guía de inicio](../inicio-companero.md).
2. Ejecutar git status. Si tienes cambios propios, guardarlos en un commit en tu rama antes de cambiar de rama. No descartarlos.
3. Con el trabajo guardado:

```powershell
git switch main
git pull --ff-only origin main
git switch -c codex/usabilidad-supervisor
```

Si la rama ya existe, usarla sin volver a crearla. Si hay divergencia o conflictos, conservar los commits y coordinar la integración.
4. Abrir Iniciar Supervisor.cmd y recorrer la app antes de modificarla.
5. Acordar quién toca cada pantalla. Propuesta: tú trabajas supervisor y tu hermano operador. Si ya tienes cambios de productos, entregarlos por separado; evitar editar juntos window.py.

## Cinco pasos, en orden

### 1. Ordenar la pantalla inicial del supervisor

Responder arriba, sin desplazarse:
- ¿Qué falta hoy? Cantidad pendiente del plan de hoy.
- ¿Qué necesita atención? Atrasos y tarimas esperando viaje.
- ¿Qué terminamos? Empacadas del plan de hoy, sobre el total programado.

Mostrar menos títulos repetidos y dar más espacio a las tareas. Conservar la distinción entre hoy, atrasos y tarimas de todos los días. No sumar indicadores que se superponen.

Aceptación: una persona identifica el pendiente de hoy y el principal problema en unos segundos, sin entrar a otra sección.

### 2. Cambiar palabras técnicas por instrucciones

Ejemplos orientativos:
- Programadas hoy → Tenemos que preparar hoy.
- Preembarque → Área de salida.
- Sin viaje → Falta asignar un camión.
- Ver preparación → Ver qué falta recoger.

Mantener los términos técnicos internos; cambiar etiquetas visibles. Evitar mensajes de alarma por una cantidad cero. Mantener visible «Inventario sin verificar»: cero pendientes no significa inventario suficiente.

Aceptación: cada botón explica qué abre o qué confirma; el texto no promete algo que la demo no comprueba.

### 3. Simplificar la lista de trabajo

Priorizar producto, cantidad pendiente y siguiente paso. Conservar destino, ubicación y responsable accesibles como detalles cuando sean necesarios. Mantener filtros y selección al actualizar automáticamente.

No ocultar información necesaria para ejecutar bien una tarea. No usar únicamente colores: acompañar con «Pendiente», «Terminado» o «Necesita atención».

Aceptación: con muchas tareas, se localiza rápido qué recoger o empacar, sin perder la selección cada diez segundos.

### 4. Hacer más directa la pantalla del montacarguista

Una instrucción y un botón principal por paso:
«Recoge 36 bolsas de Sabritas»
«Ve a: almacén y ubicación»
«Llévalas a: mesa de empaque»
«Ya recogí las 36 bolsas».

Usar ubicaciones y unidades reales del catálogo; no inventar «bolsas» si el dato disponible solo indica piezas. Conservar cantidad parcial, reporte de problema y reintento seguro. Confirmar brevemente el resultado antes de mostrar el siguiente paso. No confirmar automáticamente ninguna operación.

Aceptación: producto, cantidad, origen y destino se leen fácilmente; el botón principal permanece visible en ventana compacta.

### 5. Probar con alguien que no conoce la app

Pedirle que:
1. Encuentre qué falta hoy.
2. Abra la pantalla del montacarguista desde el inicio.
3. Identifique qué producto recoger y de dónde.
4. Confirme una cantidad parcial de prueba.
5. Regrese a supervisión y encuentre el cambio.
6. Identifique las tarimas que esperan camión.

Observar dónde duda antes de explicarle. Anotar problema y ajuste propuesto, sin culpar al usuario. Usar datos ficticios; las fechas del CSV de ejemplo son fijas y pueden aparecer como atrasos.

## Archivos principales

- frontend/desktop/supervisor_panel.py: resumen y filtros.
- frontend/desktop/window.py: navegación y pantallas administrativas; coordinar cambios.
- frontend/desktop/operator_window.py: instrucciones y confirmaciones.
- frontend/desktop/theme.py: estilos compartidos; revisar ambas vistas si se cambia.
- backend/app/services/demo_supervisor.py: cálculos del resumen. No cambiar reglas para lograr un aspecto visual.
- frontend/tests/: pruebas de interacción.

## Verificación y entrega

Ejecutar las pruebas de interfaz:

```powershell
$env:QT_QPA_PLATFORM='offscreen'
.\backend\.venv\Scripts\python.exe -m unittest discover -s frontend/tests -q
Remove-Item Env:QT_QPA_PLATFORM
```

Abrir después la app normalmente y revisar textos, cortes, botones y desplazamiento. Probar ventana de supervisor y operador compacto. Si se modifica backend, ejecutar sus pruebas correspondientes. No cambiar una prueba para esconder un error.

Hacer commits pequeños; añadir solo los archivos de la tarea. No subir .env ni datos reales.
Publicar la rama y abrir un pull request contra main para que el otro revise antes de integrar. En la entrega incluir: qué cambió, captura antes/después, pruebas y pendientes.

## Fuera de este trabajo

Inventario físico, cuentas individuales, nuevas reglas de incidencias y movilidad siguen pendientes de otro incremento. Esta tarea no los implementa ni debe simularlos como terminados.
