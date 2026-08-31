# Guía Rápida de Desarrollo

## Inicio Rápido

### 1. Preparar Base de Datos (Primera vez)

```bash
# Crear BD y usuario
psql -U postgres
CREATE DATABASE library_db;
CREATE USER library_user WITH PASSWORD 'libraryApp';
ALTER ROLE library_user SET client_encoding TO 'utf8';
ALTER ROLE library_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE library_user SET default_transaction_deferrable TO on;
GRANT ALL PRIVILEGES ON DATABASE library_db TO library_user;
\q

# Importar schema
psql -U library_user -d library_db < ../db/schema.sql
```

### 2. Instalar Dependencias

```bash
cd web-monolito
npm install
```

### 3. Configurar .env

```bash
cp .env.example .env
# Editar .env si es necesario (generalmente no lo es para desarrollo local)
```

### 4. Iniciar Desarrollo

```bash
npm run dev
```

Abrir navegador: http://localhost:3000

## Flujo de Desarrollo Típico

### Agregar Nuevo Modelo

1. Crear `src/models/NuevoModelo.js`
```javascript
const pool = require('../config/database');

const NuevoModelo = {
  getAll: async () => {
    const result = await pool.query('SELECT * FROM nueva_tabla');
    return result.rows;
  }
  // ... más métodos
};

module.exports = NuevoModelo;
```

2. En controlador:
```javascript
const NuevoModelo = require('../models/NuevoModelo');
```

### Agregar Nueva Ruta

En `src/routes/index.js`:
```javascript
router.get('/nueva-ruta', NuevoController.metodo);
router.post('/nueva-ruta', isAuthenticated, isAdmin, NuevoController.metodo);
```

### Agregar Nueva Vista

1. Crear `src/views/nueva/archivo.ejs`
2. En controlador:
```javascript
res.render('nueva/archivo', { data: datos });
```

## Debugging

### Ver Logs de Aplicación

```bash
# La aplicación imprime logs en consola
# Buscar errores de modelo, BD, etc.
```

### Ver Consultas SQL

```javascript
// En models, agregar antes de query:
console.log('SQL:', query);
console.log('Params:', params);
```

### Conectar Directamente a BD

```bash
psql -U library_user -d library_db

# Ver tablas
\dt

# Ver datos
SELECT * FROM libros;

# Ver esquema
\d libros
```

## Testing Manual

### 1. Crear Usuario Admin

```bash
npm start
# Ir a http://localhost:3000/register
# Crear usuario
# Ejecutar en BD:
psql -U library_user -d library_db
UPDATE usuarios SET es_administrador = true WHERE id_usuario = (SELECT id_usuario FROM usuarios ORDER BY created_at LIMIT 1);
```

### 2. Crear Libro

- Login como admin
- Ir a "Crear Libro"
- Llenar formulario
- Guardar

### 3. Ver Libro

- Ir a Catálogo
- Hacer clic en un libro

## Estructura de Proyecto

```
src/
├── app.js                 # Iniciador
├── config/database.js     # Conexión BD
├── models/                # Capas de datos
├── controllers/           # Lógica de negocio
├── routes/index.js        # Rutas
├── middleware/auth.js     # Autenticación
└── views/                 # Plantillas HTML
```

## Errores Comunes

### Error: "ENOENT: no such file or directory"

Posible causa: Falta crear directorio `public/images/uploads/`

```bash
mkdir -p public/images/uploads
```

### Error: "Connection refused"

PostgreSQL no está funcionando:

```bash
# Linux
sudo systemctl start postgresql

# Windows (si está instalado)
# Buscar en Servicios de Windows
```

### Error: "Port already in use"

Puerto 3000 ocupado. Cambiar en .env:

```
PORT=3001
```

## Base de Datos

### Ver Estructura

```bash
psql -U library_user -d library_db
\d librería
\d+ libros  # Con detalles
```

### Ejecutar Query

```bash
psql -U library_user -d library_db -c "SELECT COUNT(*) FROM libros;"
```

### Backup

```bash
pg_dump -U library_user library_db > backup.sql
```

### Restaurar

```bash
psql -U library_user library_db < backup.sql
```

## Performance

### Verificar Índices

```sql
SELECT indexname FROM pg_indexes WHERE tablename = 'libros';
```

### Ver Planes de Ejecución

```sql
EXPLAIN SELECT * FROM libros WHERE titulo LIKE 'Test%';
```

## Limpieza

### Eliminar Base de Datos (¡Cuidado!)

```bash
psql -U postgres
DROP DATABASE library_db;
```

### Limpia caché de Node

```bash
rm -rf node_modules/
npm install
```

## Tips Productivos

1. **Usar REST Client en VS Code** para probar endpoints
2. **Agregar console.log()** para debugging
3. **Revisar schema.sql** para entender relaciones
4. **Usar ARCHITECTURE.md** como referencia
5. **Leer MODELS_API.md** para métodos disponibles

## Comandos Útiles

```bash
# Iniciar desarrollo
npm run dev

# Ver qué está escuchando en puerto
lsof -i :3000

# Matar proceso
kill -9 <PID>

# Ver versión Node
node --version

# Ver versión npm
npm --version

# Actualizar dependencias
npm update

# Buscar vulnerabilidades
npm audit
```

---

**Última actualización:** 2024
**Versión:** 1.0.0
