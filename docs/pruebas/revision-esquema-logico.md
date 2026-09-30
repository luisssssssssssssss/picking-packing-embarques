> Informe histórico del esquema 0.1 (63 tablas). Para la implementación SQL 0.2 y sus pruebas, consultar [revisión SQL](revision-sql.md).

# Revisión del esquema lógico

Fecha: 27 de septiembre de 2026. Versión lógica 0.1.

## Resultado

- 63 tablas y 596 campos definidos.
- 151 campos con referencia, 11 relaciones compuestas y 4 índices únicos filtrados propuestos.
- 693 comprobaciones estructurales/documentales realizadas; 0 errores encontrados al cierre.
- Sintaxis DBML analizada correctamente con @dbml/core 10.2.0, parser dbmlv2. Reconoció 63 tablas. No se exportó ni ejecutó SQL.
- Diccionario y DBML cubren todas las tablas del modelo JSON.
- Once diagramas Mermaid preparados: recorrido general y diez módulos. Verificación de cobertura de nombres; no renderizados con un motor Mermaid.
- SVG general renderizado a PNG e inspeccionado visualmente.
- 85 casos de aceptación definidos con identificadores consecutivos. Son pruebas futuras, no ejecutadas sobre una base.
- Referencias locales de navegación comprobadas.

## Alcance de la comprobación

Se revisaron PK, campos duplicados, referencias existentes, compatibilidad de tipos, claves candidatas de relaciones compuestas, cobertura de documentación y vínculos locales. Los ejemplos y las reglas de conservación se revisaron conceptualmente.

No se probó todavía DDL, aislamiento, rendimiento, permisos SQL, migraciones, fallos reales ni concurrencia de usuarios. Esas verificaciones necesitan implementar el primer incremento en una base de pruebas y resolver las decisiones de negocio.

No se creó base de datos, tabla ni procedimiento. No se cambiaron el backend, Flutter, dependencias Python, credenciales ni el stack. Solo se añadieron documentos de diseño y su enlace en README.

## Huella del modelo revisado

SHA-256 del DBML: 717e0182cbc8299f4556b10606bb85c13c3328dcb56fa624fd06d768032dc693

Una modificación posterior del DBML requiere volver a comprobar coherencia y actualizar esta revisión.
