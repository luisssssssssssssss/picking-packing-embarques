# Trabajo entre dos desarrolladores

## Qué compartimos

Compartimos código, documentación, muestras ficticias, definición de dependencias y migraciones SQL.
Cada persona conserva sus credenciales, entorno Python y base de desarrollo en su equipo.
No compartir una base de desarrollo evita que una prueba de una persona altere el trabajo de la otra.

GitHub no copia los datos de SQL Server. Una futura base compartida para el piloto será una decisión separada.

## Incorporar al compañero

1. Crear su cuenta de GitHub si aún no la tiene.
2. El propietario lo invita como colaborador del repositorio.
3. El compañero acepta la invitación e inicia sesión en GitHub.
4. Clona el repositorio en una carpeta de su propia computadora:

```powershell
git clone https://github.com/luisssssssssssssss/picking-packing-embarques.git
cd picking-packing-embarques
```

5. Configura su propio nombre y correo de autor, solo en este repositorio:

```powershell
git config --local user.name "TU NOMBRE"
git config --local user.email "TU CORREO"
```

6. Sigue [la guía breve del compañero](inicio-companero.md).

No se debe enviar una copia del entorno virtual ni compartir el usuario de GitHub de otra persona.

## Una tarea pequeña por rama

Antes de empezar, ambos acuerdan objetivo, responsable, archivos afectados y criterio de aceptación.
Evitar cambios simultáneos al mismo módulo sin coordinarse.

Con los cambios anteriores guardados en su rama:

```powershell
git status
git switch main
git pull --ff-only
git switch -c codex/nombre-de-la-tarea
```

Cada tarea usará un nombre distinto. Si hay cambios sin guardar o Git informa divergencias, resolverlos
antes de continuar; no usar reset --hard ni borrar archivos para forzar el cambio de rama.

Al terminar:

1. Ejecutar las comprobaciones correspondientes.
2. Revisar git diff y git status.
3. Agregar únicamente los archivos de la tarea y hacer un commit pequeño y descriptivo.
4. Publicar la rama con git push -u origin NOMBRE-DE-LA-RAMA.
5. Abrir un pull request con objetivo, cambios, comprobaciones y pendientes.
6. La otra persona revisa. Integrar a main cuando el resultado esté verificado.

Mantener main estable es una regla de trabajo propuesta; esta guía no configura protección de ramas en GitHub.

## Reparto actual propuesto

- Compañero: [alta de productos y pruebas](tareas/agregar-productos.md), en su propia rama.
- Tú: validar usabilidad y reglas con el negocio, y revisar su pull request.
- Ambos: probar el recorrido completo en sus equipos. La interfaz actual es Python/PySide6; móvil queda pendiente.

## Cambios a la base

- Los cambios de esquema deben quedar en scripts versionados del repositorio.
- Ambos aplican los mismos cambios en su propia base.
- No modificar una migración que ya se aplicó en el otro equipo: crear una migración nueva.
- Acordar la siguiente migración antes de trabajar en paralelo para evitar números duplicados.
- Los cambios manuales hechos solo desde SSMS no sustituyen un script reproducible.
- Nunca añadir .env, respaldos SQL, archivos de datos ni exportaciones reales del negocio a un commit.

## Terminado significa comprobable

Una tarea termina cuando la otra persona puede reproducir el resultado con las instrucciones,
las comprobaciones relevantes pasan y los límites o preguntas pendientes están documentados.
