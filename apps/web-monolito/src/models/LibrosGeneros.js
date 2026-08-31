// Modelo para relación Libros-Géneros
const pool = require('../config/database');

const LibrosGeneros = {
  // Obtener géneros de un libro
  getGenerosByLibro: async (id_libro) => {
    try {
      const result = await pool.query(
        `SELECT g.id_genero, g.nombre, g.descripcion
         FROM generos g
         JOIN libros_generos lg ON g.id_genero = lg.id_genero
         WHERE lg.id_libro = $1
         ORDER BY g.nombre`,
        [id_libro]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en LibrosGeneros.getGenerosByLibro():', error);
      throw error;
    }
  },

  // Obtener libros de un género
  getLibrosByGenero: async (id_genero, limit = 20, offset = 0) => {
    try {
      const result = await pool.query(
        `SELECT l.id_libro, l.isbn, l.titulo, l.year_publicacion, l.precio, l.stock
         FROM libros l
         JOIN libros_generos lg ON l.id_libro = lg.id_libro
         WHERE lg.id_genero = $1
         ORDER BY l.titulo
         LIMIT $2 OFFSET $3`,
        [id_genero, limit, offset]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en LibrosGeneros.getLibrosByGenero():', error);
      throw error;
    }
  },

  // Agregar género a un libro
  addGeneroToLibro: async (id_libro, id_genero) => {
    try {
      const result = await pool.query(
        `INSERT INTO libros_generos (id_libro, id_genero)
         VALUES ($1, $2)
         ON CONFLICT (id_libro, id_genero) DO NOTHING
         RETURNING id_libro, id_genero`,
        [id_libro, id_genero]
      );
      return result.rows[0] || { id_libro, id_genero };
    } catch (error) {
      console.error('Error en LibrosGeneros.addGeneroToLibro():', error);
      throw error;
    }
  },

  // Eliminar género de un libro
  removeGeneroFromLibro: async (id_libro, id_genero) => {
    try {
      const result = await pool.query(
        'DELETE FROM libros_generos WHERE id_libro = $1 AND id_genero = $2 RETURNING id_libro, id_genero',
        [id_libro, id_genero]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en LibrosGeneros.removeGeneroFromLibro():', error);
      throw error;
    }
  }
};

module.exports = LibrosGeneros;
