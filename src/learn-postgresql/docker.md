# PostgreSQL local con Docker

Esta guía explica cómo levantar PostgreSQL en un contenedor con Docker Compose, conectarlo y apagarlo cuando no lo necesites.

## Requisitos

- Docker Desktop instalado y en ejecución (Windows, macOS o Linux)
- Docker Compose (incluido en Docker Desktop)

Comprueba que Docker responde:

```powershell
docker --version
docker compose version
```

## Archivos del proyecto

| Archivo | Propósito |
|---------|-----------|
| `docker-compose.yml` | Define el servicio PostgreSQL |
| `.env.example` | Plantilla de variables de entorno |
| `.env` | Tus credenciales locales (no se sube a git) |
| `docker/postgres/init/` | Scripts `.sql` que se ejecutan solo la primera vez |

## Primera configuración

Desde la raíz del repositorio:

```powershell
cd c:\Users\guill\dev\learn-sql
copy .env.example .env
```

Edita `.env` si quieres cambiar usuario, contraseña, base de datos o puerto.

## Levantar PostgreSQL

```powershell
docker compose up -d
```

- `up` crea e inicia el contenedor
- `-d` lo deja corriendo en segundo plano (detached)

Comprueba el estado:

```powershell
docker compose ps
```

Deberías ver el servicio `postgres` con estado `running` y `healthy`.

## Conectarte a la base de datos

### Desde el contenedor (psql incluido)

```powershell
docker compose exec postgres psql -U learn_sql -d learn_sql
```

Si cambiaste las variables en `.env`, sustituye `learn_sql` por tu `POSTGRES_USER` y `POSTGRES_DB`.

### Desde tu máquina (cliente psql instalado)

```powershell
psql -h localhost -p 5432 -U learn_sql -d learn_sql
```

Parámetros por defecto del proyecto:

| Parámetro | Valor por defecto |
|-----------|-------------------|
| Host | `localhost` |
| Puerto | `5432` |
| Usuario | `learn_sql` |
| Contraseña | `learn_sql` |
| Base de datos | `learn_sql` |

### Desde Python (Jupyter / scripts)

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    user="learn_sql",
    password="learn_sql",
    dbname="learn_sql",
)
```

Instala el driver si hace falta: `pip install psycopg2-binary`

## Apagar el servicio

### Parar sin borrar datos

```powershell
docker compose down
```

El contenedor se elimina, pero los datos persisten en el volumen `postgres_data`. La próxima vez que ejecutes `docker compose up -d`, recuperas la misma base.

### Parar y borrar todos los datos

```powershell
docker compose down -v
```

Útil cuando quieres empezar de cero.

### Solo pausar (sin eliminar el contenedor)

```powershell
docker compose stop
```

Para volver a arrancar:

```powershell
docker compose start
```

## Comandos útiles

Ver logs del servidor:

```powershell
docker compose logs postgres
docker compose logs -f postgres
```

Reiniciar el servicio:

```powershell
docker compose restart postgres
```

Entrar a una shell dentro del contenedor:

```powershell
docker compose exec postgres sh
```

## Scripts de inicialización

Cualquier archivo `.sql` o `.sh` en `docker/postgres/init/` se ejecuta automáticamente la primera vez que se crea el volumen de datos.

Ejemplo `docker/postgres/init/01_schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS ejemplo (
    id   SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL
);
```

Importante: esos scripts solo corren en la creación inicial del volumen. Si ya levantaste el contenedor antes, usa `docker compose down -v` y vuelve a subir, o ejecuta el SQL manualmente con `psql`.

## Instalación nativa vs Docker

| Enfoque | Cuándo usarlo |
|---------|---------------|
| Docker (este proyecto) | Practicar SQL, aislar entornos, encender/apagar fácil |
| Instalador oficial | Servidor siempre activo, integración profunda con el SO |

Para aprender y practicar en este repositorio, Docker suele ser la opción más simple: no ensucia el sistema y puedes borrarlo con un comando.

### Instalación nativa en Windows (referencia)

Si más adelante quieres PostgreSQL instalado en el sistema:

1. Descarga el instalador desde [postgresql.org/download/windows](https://www.postgresql.org/download/windows/)
2. Ejecuta el instalador y anota usuario (`postgres`) y contraseña
3. El servicio queda registrado en Windows y arranca con el sistema
4. Usa pgAdmin (incluido) o `psql` desde `C:\Program Files\PostgreSQL\16\bin`

Con Docker no necesitas este paso para trabajar en learn-sql.

## Solución de problemas

### El puerto 5432 ya está en uso

Cambia en `.env`:

```
POSTGRES_PORT=5433
```

Luego conecta usando el puerto `5433`.

### Contenedor unhealthy

Revisa los logs:

```powershell
docker compose logs postgres
```

Si el volumen quedó corrupto, prueba `docker compose down -v` y vuelve a levantar (perderás los datos locales).

## Flujo de trabajo recomendado

```text
Practicar SQL  →  docker compose up -d
Terminar       →  docker compose down
Empezar de cero →  docker compose down -v && docker compose up -d
```
