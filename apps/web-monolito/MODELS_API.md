# Referencia de API de Modelos

## Modelos Disponibles

### Usuarios

```javascript
const Usuarios = require('../models/Usuarios');

// Obtener todos
await Usuarios.getAll()
// Retorna: Array<{id_usuario, nombre, email, es_administrador, activo, created_at}>

// Obtener por ID
await Usuarios.getById(id)
// Retorna: {id_usuario, nombre, email, es_administrador, activo, created_at} | null

// Obtener por email
await Usuarios.getByEmail(email)
// Retorna: {id_usuario, nombre, email, es_administrador, activo, ...} | null

// Crear usuario
await Usuarios.create(nombre, email, password, es_administrador = false)
// Retorna: {id_usuario, nombre, email, es_administrador, created_at}

// Actualizar
await Usuarios.update(id, nombre, email)
// Retorna: {id_usuario, nombre, email, es_administrador, activo, updated_at} | null

// Cambiar contraseña
await Usuarios.changePassword(id, newPassword)
// Retorna: {id_usuario, nombre, email} | null

// Verificar contraseña
await Usuarios.verifyPassword(email, password)
// Retorna: {id_usuario, ...} | null (si es válida)

// Eliminar
await Usuarios.delete(id)
// Retorna: {id_usuario} | null

// Activar/Desactivar
await Usuarios.toggleActive(id)
// Retorna: {id_usuario, nombre, email, es_administrador, activo}
```

### Libros

```javascript
const Libros = require('../models/Libros');

// Obtener todos con paginación
await Libros.getAll(limit = 20, offset = 0)
// Retorna: Array<{id_libro, isbn, titulo, year_publicacion, precio, stock, formato, ...}>

// Contar total
await Libros.count()
// Retorna: number

// Obtener por ID
await Libros.getById(id)
// Retorna: {id_libro, isbn, titulo, precio, stock, formato, id_formato, autores, generos, ...} | null

// Crear
await Libros.create(isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion)
// Retorna: {id_libro, isbn, titulo, ...}

// Actualizar
await Libros.update(id, isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion)
// Retorna: {id_libro, ...} | null

// Eliminar (borra en cascada)
await Libros.delete(id)
// Retorna: {id_libro} | null

// Buscar por título
await Libros.searchByTitle(titulo)
// Retorna: Array<{id_libro, isbn, titulo, precio, autores, generos}>

// Obtener por género
await Libros.getByGenero(id_genero, limit = 20, offset = 0)
// Retorna: Array<{id_libro, ...}>
```

### Autores

```javascript
const Autores = require('../models/Autores');

// Obtener todos
await Autores.getAll()
// Retorna: Array<{id_autor, nombre, apellido, biografia, fecha_nacimiento, nacionalidad}>

// Obtener por ID
await Autores.getById(id)
// Retorna: {id_autor, nombre, apellido, ...} | null

// Crear
await Autores.create(nombre, apellido, biografia, fecha_nacimiento, nacionalidad)
// Retorna: {id_autor, nombre, apellido, ...}

// Actualizar
await Autores.update(id, nombre, apellido, biografia, fecha_nacimiento, nacionalidad)
// Retorna: {id_autor, ...} | null

// Eliminar
await Autores.delete(id)
// Retorna: {id_autor} | null

// Obtener autores de un libro
await Autores.getByLibro(id_libro)
// Retorna: Array<{id_autor, nombre, apellido, biografia, orden_autor}>
```

### Géneros

```javascript
const Generos = require('../models/Generos');

// Obtener todos
await Generos.getAll()
// Retorna: Array<{id_genero, nombre, descripcion, created_at}>

// Obtener por ID
await Generos.getById(id)
// Retorna: {id_genero, nombre, descripcion, created_at} | null

// Crear
await Generos.create(nombre, descripcion)
// Retorna: {id_genero, nombre, descripcion, created_at}

// Actualizar
await Generos.update(id, nombre, descripcion)
// Retorna: {id_genero, nombre, descripcion} | null

// Eliminar
await Generos.delete(id)
// Retorna: {id_genero} | null
```

### Formatos

```javascript
const Formatos = require('../models/Formatos');

// Obtener todos
await Formatos.getAll()
// Retorna: Array<{id_formato, nombre, descripcion}>

// Obtener por ID
await Formatos.getById(id)
// Retorna: {id_formato, nombre, descripcion} | null

// Crear, Actualizar, Eliminar
// (similar a Generos)
```

### Imágenes

```javascript
const Imagenes = require('../models/Imagenes');

// Obtener todas las imágenes de un libro
await Imagenes.getByLibro(id_libro)
// Retorna: Array<{id_imagen, id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden}>

// Obtener por ID
await Imagenes.getById(id)
// Retorna: {id_imagen, id_libro, ...} | null

// Obtener portada
await Imagenes.getPortada(id_libro)
// Retorna: {id_imagen, ruta_archivo} | null

// Crear
await Imagenes.create(id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden)
// Retorna: {id_imagen, id_libro, ...}

// Actualizar
await Imagenes.update(id, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada)
// Retorna: {id_imagen, ...} | null

// Eliminar
await Imagenes.delete(id)
// Retorna: {id_imagen, id_libro}
```

### Conceptos

```javascript
const Conceptos = require('../models/Conceptos');

// Obtener todos
await Conceptos.getAll()
// Retorna: Array<{id_concepto, termino, created_at}>

// Obtener por ID
await Conceptos.getById(id)
// Retorna: {id_concepto, termino, created_at} | null

// Crear
await Conceptos.create(termino)
// Retorna: {id_concepto, termino, created_at}

// Obtener por término
await Conceptos.getByTermino(termino)
// Retorna: {id_concepto, termino} | null

// Obtener conceptos de un libro
await Conceptos.getByLibro(id_libro)
// Retorna: Array<{id_concepto, termino, definicion, created_at}>

// Agregar concepto a libro
await Conceptos.addToLibro(id_libro, id_concepto, definicion)
// Retorna: {id_libro, id_concepto, definicion, created_at}

// Eliminar concepto de libro
await Conceptos.removeFromLibro(id_libro, id_concepto)
// Retorna: {id_libro, id_concepto} | null

// Eliminar concepto
await Conceptos.delete(id)
// Retorna: {id_concepto} | null
```

### LibrosAutores

```javascript
const LibrosAutores = require('../models/LibrosAutores');

// Obtener autores de un libro
await LibrosAutores.getAutoresByLibro(id_libro)
// Retorna: Array<{id_autor, nombre, apellido, orden_autor}>

// Obtener libros de un autor
await LibrosAutores.getLibrosByAutor(id_autor)
// Retorna: Array<{id_libro, isbn, titulo, year_publicacion, precio, stock}>

// Agregar autor a libro
await LibrosAutores.addAutorToLibro(id_libro, id_autor, orden_autor)
// Retorna: {id_libro, id_autor, orden_autor}

// Eliminar autor de libro
await LibrosAutores.removeAutorFromLibro(id_libro, id_autor)
// Retorna: {id_libro, id_autor} | null
```

### LibrosGeneros

```javascript
const LibrosGeneros = require('../models/LibrosGeneros');

// Obtener géneros de un libro
await LibrosGeneros.getGenerosByLibro(id_libro)
// Retorna: Array<{id_genero, nombre, descripcion}>

// Obtener libros de un género
await LibrosGeneros.getLibrosByGenero(id_genero, limit, offset)
// Retorna: Array<{id_libro, isbn, titulo, ...}>

// Agregar género a libro
await LibrosGeneros.addGeneroToLibro(id_libro, id_genero)
// Retorna: {id_libro, id_genero}

// Eliminar género de libro
await LibrosGeneros.removeGeneroFromLibro(id_libro, id_genero)
// Retorna: {id_libro, id_genero} | null
```

## Ejemplo de Uso en Controlador

```javascript
const Libros = require('../models/Libros');
const LibrosAutores = require('../models/LibrosAutores');
const LibrosGeneros = require('../models/LibrosGeneros');

// Crear libro con autores y géneros
async function createLibroCompleto(req, res) {
  try {
    // 1. Crear libro base
    const libro = await Libros.create(
      req.body.isbn,
      req.body.titulo,
      req.body.year_publicacion,
      req.body.precio,
      req.body.stock,
      req.body.id_formato,
      req.body.descripcion
    );

    // 2. Agregar autores
    if (req.body.autores && Array.isArray(req.body.autores)) {
      for (let i = 0; i < req.body.autores.length; i++) {
        await LibrosAutores.addAutorToLibro(
          libro.id_libro,
          req.body.autores[i],
          i + 1 // orden
        );
      }
    }

    // 3. Agregar géneros
    if (req.body.generos && Array.isArray(req.body.generos)) {
      for (const generoId of req.body.generos) {
        await LibrosGeneros.addGeneroToLibro(libro.id_libro, generoId);
      }
    }

    res.redirect(`/libros/${libro.id_libro}`);
  } catch (error) {
    res.status(500).render('error', { message: 'Error al crear libro' });
  }
}
```

## Manejo de Errores

Todos los métodos de modelos lanzan excepciones. Siempre usar try/catch:

```javascript
try {
  const libro = await Libros.getById(id);
  if (!libro) {
    // Libro no existe
  }
} catch (error) {
  console.error('Error:', error);
  // Manejar error
}
```

## Notas Importantes

1. **ID de Libro**: UUID, no número
2. **ID de Usuario**: UUID, no número
3. **Transacciones**: Algunos métodos (delete) usan transacciones automáticas
4. **Contraseñas**: Siempre hasheadas, nunca retornan en GET
5. **Validación**: Hacer en controlador antes de llamar modelo
6. **Pool de Conexiones**: Automático, reutiliza conexiones

---

**Última actualización:** 2024
