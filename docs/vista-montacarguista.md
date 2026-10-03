# Vista del montacarguista — demo de escritorio

La aplicación abre directamente **Mi tarea**: una tarjeta con producto, cantidad, almacén/ubicación de origen y lugar al que debe llevarse. El destino comercial se muestra aparte como «Para: tienda», para no confundirlo con el siguiente lugar dentro del almacén.

1. Recoge el producto y pulsa **Ya recogí X piezas**.
2. La misma pantalla indica dónde empacarlo. Pulsa **Ya empaqué X piezas**.
3. Lleva la tarima al área de salida y confirma que la dejaste allí.
4. Cuando supervisión prepare el viaje, aparece la tarea de cargar la siguiente tarima, con andén y tráiler. El backend conserva la carga inversa.

No se requiere elegir filas, navegar entre módulos ni volver a escribir códigos. «Voy a confirmar otra cantidad» permite una confirmación parcial; lo recogido se empaca antes de continuar con el resto. «No puedo continuar» registra una incidencia y pausa esta pantalla hasta reanudarla después de revisar.

**Supervisor** abre la ventana administrativa ya existente: importar CSV, organizar por capacidad, administrar destinos, preparar viajes y cerrar embarques. El botón **Volver al montacarguista** refresca la tarea. Importar no libera tareas por sí solo: primero hay que organizar los pedidos pendientes.

## Alcance de esta revisión

- Python/PySide6 de escritorio; todavía no es la app Android.
- Pantalla estrecha comprobada a 390 × 780 y principal a 480 × 860; confirmación siempre fuera del área desplazable.
- La selección de tarea está en Python/FastAPI. Las ubicaciones proceden del catálogo SQL, sin nuevas tablas ni migraciones.
- Un solo coordinador de demo compartido. Separar ventanas NO implementa permisos, login ni asignación entre varios montacarguistas.
- Confirmación manual de prueba con códigos completos; no prueba un escaneo ni consulta inventario físico.
- La fecha de picking sigue siendo el día planeado del reloj simulado; la cola de demo puede incluir días futuros.
- La pausa de incidencia afecta esta ventana; no es un bloqueo persistente del pedido para otros usuarios.
- Si la respuesta de guardado es incierta, se conserva la misma clave de operación para reintentar sin duplicar. No se permite iniciar otra confirmación mientras esta sigue pendiente.

## Validación y archivos

37 pruebas backend y 11 pruebas de interfaz aprobadas. Incluyen recorrido SQL real de 48 piezas, dividido en 20 y 28, empaque, dos tarimas, preembarque, viaje y cierre; además selección por orden de carga, cantidades parciales, confirmación con un clic, prevención de doble clic y reintento con la misma identidad.

Creados: backend/app/services/demo_operator.py, frontend/desktop/operator_window.py y sus pruebas test_demo_operator.py / test_operator_window.py.

Modificados: consulta demo_queries.py (nombres de ubicaciones y referencias), main.py (consulta del operador), client.py (estado de errores HTTP), desktop_launcher.py (ventana inicial), prueba de autenticación y documentación.

La pantalla administrativa window.py y el módulo demo_catalog.py no se modificaron en este incremento, para reducir cruces con la tarea de productos del compañero. Rama: codex/vista-montacarguista. Integrado en main junto con las mejoras posteriores de supervisión.
