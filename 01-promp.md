Diseña una base de datos en PostgreSQL, tomando en consideracion que mas adelante se desarrollara un sistema web completo que administre usuarios registrados,
implementar CRUD del modelo normalizado (en todas las tablas), manejar imagenes y conservar definiciones de conceptos asociadas a cada libro.

Partiendo de que todo libro tiene ISBN, título, autor, año de publicación, género, precio, stock, formato, imágenes y
conceptos definidos por libro, identifica dependencias funcionales y multivaluadas.

· Un libro puede tener varios autores.
· Un libro puede pertenecer a varios géneros.
· Un libro puede definir muchos conceptos y un mismo concepto puede aparecer en distintos
libros con definiciones diferentes.
· Un libro puede tener varias imágenes.
· Formato y categoría son catálogos independientes.
· Debe existir como máximo un administrador.

Crea el diseño de la base de datos en un archivo .sql dentro del directorio library/db y llamalo schema.sql
