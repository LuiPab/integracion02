"Modifica mi schema.sql agregando al puro inicio sentencias DROP TABLE IF EXISTS ... CASCADE; para eliminar limpia y ordenadamente todas las tablas existentes (libros, usuarios, imagenes, autores, generos, categorias, formatos, conceptos, y sus tablas intermedias).

Después de las sentencias DROP, genera todo el esquema corrigiendo las sintaxis:

Cambia la extensión a CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; (con comillas).

Remueve la restricción UNIQUE (...) WHERE ... de la tabla imagenes y créala al final del archivo como un índice: CREATE UNIQUE INDEX idx_una_portada_por_libro ON imagenes (id_libro) WHERE es_portada = true;.

Agrega las sentencias INSERT para 12 libros completos con sus usuarios, autores, géneros e imágenes correspondientes.

Devuélveme todo el archivo schema.sql completo para reemplazo total."