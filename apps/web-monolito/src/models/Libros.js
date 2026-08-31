// Modelo de Libros
const pool = require('../config/database');

const Libros = {
  // Obtener todos los libros con información completa
  getAll: async (limit = 20, offset = 0) => {
    try {
      const result = await pool.query(`
        SELECT 
          l.id_libro,
          l.isbn,
          l.titulo,
          l.year_publicacion,
          l.precio,
          l.stock,
          f.nombre AS formato,
          l.descripcion,
          STRING_AGG(DISTINCT CONCAT(a.nombre, ' ', a.apellido), ', ' ORDER BY CONCAT(a.nombre, ' ', a.apellido)) AS autores,
          STRING_AGG(DISTINCT g.nombre, ', ' ORDER BY g.nombre) AS generos,
          COUNT(DISTINCT i.id_imagen) AS cantidad_imagenes,
          l.created_at,
          l.updated_at
        FROM libros l
        LEFT JOIN formatos f ON l.id_formato = f.id_formato
        LEFT JOIN libros_autores la ON l.id_libro = la.id_libro
        LEFT JOIN autores a ON la.id_autor = a.id_autor
        LEFT JOIN libros_generos lg ON l.id_libro = lg.id_libro
        LEFT JOIN generos g ON lg.id_genero = g.id_genero
        LEFT JOIN imagenes i ON l.id_libro = i.id_libro
        GROUP BY l.id_libro, f.nombre
        ORDER BY l.created_at DESC
        LIMIT $1 OFFSET $2
      `, [limit, offset]);
      return result.rows;
    } catch (error) {
      console.error('Error en Libros.getAll():', error);
      throw error;
    }
  },

  // Contar total de libros
  count: async () => {
    try {
      const result = await pool.query('SELECT COUNT(*) FROM libros');
      return parseInt(result.rows[0].count, 10);
    } catch (error) {
      console.error('Error en Libros.count():', error);
      throw error;
    }
  },

  // Obtener libro por ID
  getById: async (id) => {
    try {
      const result = await pool.query(`
        SELECT 
          l.id_libro,
          l.isbn,
          l.titulo,
          l.year_publicacion,
          l.precio,
          l.stock,
          f.nombre AS formato,
          f.id_formato,
          l.descripcion,
          STRING_AGG(DISTINCT CONCAT(a.nombre, ' ', a.apellido), ', ' ORDER BY CONCAT(a.nombre, ' ', a.apellido)) AS autores,
          STRING_AGG(DISTINCT g.nombre, ', ' ORDER BY g.nombre) AS generos,
          l.created_at,
          l.updated_at
        FROM libros l
        LEFT JOIN formatos f ON l.id_formato = f.id_formato
        LEFT JOIN libros_autores la ON l.id_libro = la.id_libro
        LEFT JOIN autores a ON la.id_autor = a.id_autor
        LEFT JOIN libros_generos lg ON l.id_libro = lg.id_libro
        LEFT JOIN generos g ON lg.id_genero = g.id_genero
        WHERE l.id_libro = $1
        GROUP BY l.id_libro, f.id_formato, f.nombre
      `, [id]);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Libros.getById():', error);
      throw error;
    }
  },

  // Crear libro
  create: async (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) => {
    try {
      const result = await pool.query(
        `INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) 
         VALUES ($1, $2, $3, $4, $5, $6, $7) 
         RETURNING id_libro, isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion, created_at`,
        [isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Libros.create():', error);
      throw error;
    }
  },

  // Actualizar libro
  update: async (id, isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) => {
    try {
      const result = await pool.query(
        `UPDATE libros 
         SET isbn = $1, titulo = $2, year_publicacion = $3, precio = $4, stock = $5, id_formato = $6, descripcion = $7, updated_at = CURRENT_TIMESTAMP
         WHERE id_libro = $8
         RETURNING id_libro, isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion, updated_at`,
        [isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Libros.update():', error);
      throw error;
    }
  },

  // Eliminar libro
  delete: async (id) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // Eliminar imágenes (on cascade delete)
      await client.query('DELETE FROM imagenes WHERE id_libro = $1', [id]);
      
      // Eliminar conceptos asociados
      await client.query('DELETE FROM libros_conceptos WHERE id_libro = $1', [id]);
      
      // Eliminar géneros asociados
      await client.query('DELETE FROM libros_generos WHERE id_libro = $1', [id]);
      
      // Eliminar autores asociados
      await client.query('DELETE FROM libros_autores WHERE id_libro = $1', [id]);
      
      // Eliminar libro
      const result = await client.query(
        'DELETE FROM libros WHERE id_libro = $1 RETURNING id_libro',
        [id]
      );
      
      await client.query('COMMIT');
      return result.rows[0] || null;
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error en Libros.delete():', error);
      throw error;
    } finally {
      client.release();
    }
  },

  // Buscar libros por título
  searchByTitle: async (titulo) => {
    try {
      const result = await pool.query(`
        SELECT 
          l.id_libro,
          l.isbn,
          l.titulo,
          l.year_publicacion,
          l.precio,
          l.stock,
          f.nombre AS formato,
          STRING_AGG(DISTINCT CONCAT(a.nombre, ' ', a.apellido), ', ') AS autores,
          STRING_AGG(DISTINCT g.nombre, ', ') AS generos
        FROM libros l
        LEFT JOIN formatos f ON l.id_formato = f.id_formato
        LEFT JOIN libros_autores la ON l.id_libro = la.id_libro
        LEFT JOIN autores a ON la.id_autor = a.id_autor
        LEFT JOIN libros_generos lg ON l.id_libro = lg.id_libro
        LEFT JOIN generos g ON lg.id_genero = g.id_genero
        WHERE LOWER(l.titulo) LIKE LOWER($1)
        GROUP BY l.id_libro, f.nombre
        ORDER BY l.titulo
      `, [`%${titulo}%`]);
      return result.rows;
    } catch (error) {
      console.error('Error en Libros.searchByTitle():', error);
      throw error;
    }
  },

  // Obtener libros por género
  getByGenero: async (id_genero, limit = 20, offset = 0) => {
    try {
      const result = await pool.query(`
        SELECT 
          l.id_libro,
          l.isbn,
          l.titulo,
          l.year_publicacion,
          l.precio,
          l.stock,
          f.nombre AS formato,
          STRING_AGG(DISTINCT CONCAT(a.nombre, ' ', a.apellido), ', ') AS autores,
          STRING_AGG(DISTINCT g.nombre, ', ') AS generos
        FROM libros l
        LEFT JOIN formatos f ON l.id_formato = f.id_formato
        LEFT JOIN libros_autores la ON l.id_libro = la.id_libro
        LEFT JOIN autores a ON la.id_autor = a.id_autor
        LEFT JOIN libros_generos lg ON l.id_libro = lg.id_libro
        LEFT JOIN generos g ON lg.id_genero = g.id_genero
        WHERE EXISTS (SELECT 1 FROM libros_generos WHERE id_libro = l.id_libro AND id_genero = $1)
        GROUP BY l.id_libro, f.nombre
        ORDER BY l.titulo
        LIMIT $2 OFFSET $3
      `, [id_genero, limit, offset]);
      return result.rows;
    } catch (error) {
      console.error('Error en Libros.getByGenero():', error);
      throw error;
    }
  }
};

module.exports = Libros;
