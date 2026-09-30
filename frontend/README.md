# Aplicación de escritorio Python

Por solicitud del usuario del 29 de septiembre de 2026, esta demostración usa Python y PySide6. El alcance actual es Windows. La implementación móvil queda pendiente.

- desktop/window.py: ventanas, tablas y acciones.
- desktop/client.py: comunicación HTTP con FastAPI.
- desktop/theme.py: presentación visual.

El cliente no accede a SQL Server. El lanzador desktop_launcher.py arranca una API local privada y la ventana; al cerrar termina únicamente el servicio que inició.

Abrir [Iniciar Demo.cmd](../Iniciar%20Demo.cmd). Instrucciones completas en [demo-escritorio.md](../docs/demo-escritorio.md).
