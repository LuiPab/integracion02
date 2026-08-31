# Documentación de Arquitectura - Librería Online

## 1. Visión General

Esta es una **aplicación web monolítica** construida con Node.js que implementa el patrón **MVC (Modelo-Vista-Controlador)** para la gestión de una librería en línea.

### Características Arquitectónicas

- **Monolito**: Todo el código en una sola aplicación
- **SSR (Server-Side Rendering)**: HTML renderizado en el servidor
- **Sin APIs REST**: No hay separación API/Frontend
- **Modular**: Código organizado por responsabilidades
- **Gestión de Sesiones**: Autenticación basada en sesiones
- **Base de Datos Normalizada**: Diseño 3NF en PostgreSQL

## 2. Arquitectura MVC

### 2.1 Capas de la Aplicación

```
┌─────────────────────────────────────┐
│        Capa de Presentación         │
│  (Vistas EJS + HTML + CSS)          │
└──────────┬──────────────────────────┘
           │
┌──────────▼──────────────────────────┐
│     Capa de Controladores           │
│  (Lógica de negocio y flujo)        │
└──────────┬──────────────────────────┘
           │
┌──────────▼──────────────────────────┐
│     Capa de Modelos                 │
│  (Acceso a datos, BD)               │
└──────────┬──────────────────────────┘
           │
┌──────────▼──────────────────────────┐
│     Base de Datos PostgreSQL        │
│  (Persistencia de datos)            │
└─────────────────────────────────────┘
```

### 2.2 Flujo de Solicitud

1. **Request**: Usuario realiza una solicitud HTTP
2. **Router**: Identifica la ruta y middleware
3. **Middleware**: Autenticación, sesión, etc.
4. **Controlador**: Procesa la lógica de negocio
5. **Modelo**: Consulta/Modifica datos en BD
6. **Vista**: Renderiza HTML con datos
7. **Response**: Envía HTML al navegador

## 3. Estructura de Directorios

```
src/
├── app.js                      # Punto de entrada
├── config/
│   └── database.js            # Conexión a PostgreSQL
├── models/                    # Capa de Datos
│   ├── Usuarios.js
│   ├── Libros.js
│   ├── Autores.js
│   ├── Generos.js
│   ├── Formatos.js
│   ├── Imagenes.js
│   ├── Conceptos.js
│   ├── LibrosAutores.js
│   └── LibrosGeneros.js
├── controllers/              # Capa de Lógica
│   ├── AuthController.js
│   └── LibrosController.js
├── routes/                  # Definición de Rutas
│   └── index.js
├── middleware/             # Funciones Intermedias
│   └── auth.js
├── views/                  # Capa de Presentación
│   ├── layout.ejs
│   ├── index.ejs
│   ├── error.ejs
│   ├── auth/
│   ├── libros/
│   └── ...
└── utils/                 # Funciones Auxiliares
    └── helpers.js
```

## 4. Modelos de Datos

### 4.1 Entidades Principales

#### USUARIOS
- Gestión de usuarios del sistema
- Máximo un administrador
- Contraseñas hasheadas con bcrypt
- Control de acceso

```
id_usuario (UUID)
nombre (VARCHAR)
email (VARCHAR) - UNIQUE
contraseña_hash (VARCHAR)
es_administrador (BOOLEAN)
activo (BOOLEAN)
```

#### LIBROS
- Información principal de libros
- Referencia a formato
- Descripción detallada

```
id_libro (UUID)
isbn (VARCHAR) - UNIQUE
titulo (VARCHAR)
year_publicacion (INTEGER)
precio (DECIMAL)
stock (INTEGER)
id_formato (INTEGER) - FK
descripcion (TEXT)
```

### 4.2 Relaciones N:N

#### LIBROS_AUTORES
- Un libro puede tener múltiples autores
- Un autor puede escribir múltiples libros
- Orden de autores

#### LIBROS_GENEROS
- Un libro puede pertenecer a múltiples géneros
- Un género puede clasificar múltiples libros

#### LIBROS_CONCEPTOS
- Un libro puede definir múltiples conceptos
- Un concepto puede aparecer en múltiples libros
- **Cada relación puede tener definición diferente**

### 4.3 Entidades Complementarias

#### IMAGENES
- Múltiples imágenes por libro
- Una portada designada por libro
- Metadatos de archivo

#### AUTORES, GENEROS, FORMATOS, CONCEPTOS
- Catálogos independientes
- Información de referencia

## 5. Flujos Principales

### 5.1 Flujo de Registro/Login

```
┌─────────────────────────────────────────────────────┐
│ 1. Usuario accede a /register o /login              │
│    → Se renderiza formulario HTML                   │
└────────────┬────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│ 2. Usuario envía datos (POST)                       │
│    → Middleware verifica sesión                     │
│    → AuthController recibe datos                    │
└────────────┬────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│ 3. Controller valida datos                          │
│    → Usuarios.verifyPassword() o create()           │
│    → Interactúa con BD                              │
└────────────┬────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│ 4. BD confirma/rechaza                              │
│    → Sessioné se establece (req.session)            │
└────────────┬────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│ 5. Se redirige (302 redirect)                       │
│    → GET / con sesión activa                        │
└─────────────────────────────────────────────────────┘
```

### 5.2 Flujo de Visualización de Libro

```
┌────────────────────────────────────────────────────┐
│ GET /libros/:id                                    │
└────────────┬─────────────────────────────────────┘
             │
┌────────────▼─────────────────────────────────────┐
│ Router → LibrosController.viewLibro()             │
└────────────┬─────────────────────────────────────┘
             │
┌────────────▼─────────────────────────────────────┐
│ Libro.getById(id) - BD                            │
│ LibrosAutores.getAutoresByLibro(id)               │
│ LibrosGeneros.getGenerosByLibro(id)               │
│ Imagenes.getByLibro(id)                           │
│ Conceptos.getByLibro(id)                          │
└────────────┬─────────────────────────────────────┘
             │
┌────────────▼─────────────────────────────────────┐
│ Renderiza libros/view.ejs con datos               │
│ → HTML final se envía al navegador                │
└────────────────────────────────────────────────┘
```

### 5.3 Flujo de Creación de Libro (Admin)

```
GET /admin/libros/crear
    ↓
showCreateForm() - Carga formatos de BD
    ↓
Renderiza libros/create.ejs
    ↓
POST /admin/libros/crear
    ↓
createLibro() - Valida datos
    ↓
Libros.create() - Inserta en BD
    ↓
Redirect → GET /libros/:id
```

## 6. Seguridad

### 6.1 Autenticación

- Sesiones con express-session
- Contraseñas hasheadas con bcrypt (10 rounds)
- Middleware `isAuthenticated` en rutas protegidas
- Logout destruye sesión

### 6.2 Autorización

- Middleware `isAdmin` verifica es_administrador
- Restricción a máximo 1 administrador
- Rutas admin prefijadas con `/admin`

### 6.3 Validaciones

- Validación en controlador
- Validación en modelo (constraints de BD)
- Prevención de inyección SQL (prepared statements)

## 7. Gestión de Errores

### 7.1 Niveles de Manejo

```
1. Validación en Controlador
   ↓
2. Captura en Try/Catch
   ↓
3. Log en consola
   ↓
4. Respuesta al usuario (error.ejs)
```

### 7.2 Errores Comunes

- 400: Datos inválidos
- 401: No autenticado
- 403: No autorizado
- 404: Recurso no encontrado
- 500: Error del servidor

## 8. Extensibilidad

### 8.1 Cómo Agregar Nueva Funcionalidad

1. **Crear Modelo** (si es necesario)
   ```javascript
   // src/models/NuevaEntidad.js
   const NuevaEntidad = {
     getAll: async () => { /* ... */ },
     create: async () => { /* ... */ }
   };
   ```

2. **Crear Controlador**
   ```javascript
   // src/controllers/NuevaController.js
   const NuevaController = {
     list: async (req, res) => { /* ... */ }
   };
   ```

3. **Crear Vistas**
   ```html
   <!-- src/views/nueva/list.ejs -->
   ```

4. **Agregar Rutas**
   ```javascript
   // src/routes/index.js
   router.get('/nueva', NuevaController.list);
   ```

## 9. Performance

### 9.1 Optimizaciones

- Índices en BD (CREATE INDEX)
- Paginación en listados
- Pool de conexiones a BD
- Caché de sesiones en memoria

### 9.2 Consideraciones

- Conexión única al servidor
- Escalabilidad limitada (sin clustering)
- Para producción: considerar load balancer

## 10. Deployment

### 10.1 Desarrollo

```bash
npm run dev    # Con reinicio automático
```

### 10.2 Producción

```bash
npm start      # Ejecución normal
```

Con Systemd + Nginx para máxima confiabilidad (ver README.md)

## 11. Mantenimiento

### 11.1 Backups

```bash
pg_dump -U library_user library_db > backup.sql
```

### 11.2 Logs

- Aplicación: stdout/stderr
- Nginx: /var/log/nginx/
- PostgreSQL: /var/log/postgresql/

### 11.3 Actualizaciones

```bash
npm update     # Actualizar dependencias
npm audit      # Revisar vulnerabilidades
```

---

**Última actualización:** 2024
**Versión:** 1.0.0
