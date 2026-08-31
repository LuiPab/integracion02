// Modelo para relación Libros-Autores
const pool = require('../config/database');

const LibrosAutores = {
  // Obtener autores de un libro
  getAutoresByLibro: async (id_libro) => {
    try {
      const result = await pool.query(
        `SELECT a.id_autor, a.nombre, a.apellido, la.orden_autor
         FROM autores a
         JOIN libros_autores la ON a.id_autor = la.id_autor
         WHERE la.id_libro = $1
         ORDER BY la.orden_autor, a.apellido, a.nombre`,
        [id_libro]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en LibrosAutores.getAutoresByLibro():', error);
      throw error;
    }
  },

  // Obtener libros de un autor
  getLibrosByAutor: async (id_autor) => {
    try {
      const result = await pool.query(
        `SELECT l.id_libro, l.isbn, l.titulo, l.year_publicacion, l.precio, l.stock
         FROM libros l
         JOIN libros_autores la ON l.id_libro = la.id_libro
         WHERE la.id_autor = $1
         ORDER BY l.titulo`,
        [id_autor]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en LibrosAutores.getLibrosByAutor():', error);
      throw error;
    }
  },

  // Agregar autor a un libro
  addAutorToLibro: async (id_libro, id_autor, orden_autor = null) => {
    try {
      const result = await pool.query(
        `INSERT INTO libros_autores (id_libro, id_autor, orden_autor)
         VALUES ($1, $2, $3)
         ON CONFLICT (id_libro, id_autor) DO UPDATE SET orden_autor = $3
         RETURNING id_libro, id_autor, orden_autor`,
        [id_libro, id_autor, orden_autor]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en LibrosAutores.addAutorToLibro():', error);
      throw error;
    }
  },

  // Eliminar autor de un libro
  removeAutorFromLibro: async (id_libro, id_autor) => {
    try {
      const result = await pool.query(
        'DELETE FROM libros_autores WHERE id_libro = $1 AND id_autor = $2 RETURNING id_libro, id_autor',
        [id_libro, id_autor]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en LibrosAutores.removeAutorFromLibro():', error);
      throw error;
    }
  }
};

module.exports = LibrosAutores;
