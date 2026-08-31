// Modelo de Conceptos
const pool = require('../config/database');

const Conceptos = {
  // Obtener todos los conceptos
  getAll: async () => {
    try {
      const result = await pool.query('SELECT id_concepto, termino, created_at FROM conceptos ORDER BY termino');
      return result.rows;
    } catch (error) {
      console.error('Error en Conceptos.getAll():', error);
      throw error;
    }
  },

  // Obtener concepto por ID
  getById: async (id) => {
    try {
      const result = await pool.query(
        'SELECT id_concepto, termino, created_at FROM conceptos WHERE id_concepto = $1',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Conceptos.getById():', error);
      throw error;
    }
  },

  // Crear concepto
  create: async (termino) => {
    try {
      const result = await pool.query(
        'INSERT INTO conceptos (termino) VALUES ($1) RETURNING id_concepto, termino, created_at',
        [termino]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Conceptos.create():', error);
      throw error;
    }
  },

  // Obtener concepto por término
  getByTermino: async (termino) => {
    try {
      const result = await pool.query(
        'SELECT id_concepto, termino FROM conceptos WHERE LOWER(termino) = LOWER($1)',
        [termino]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Conceptos.getByTermino():', error);
      throw error;
    }
  },

  // Obtener conceptos de un libro
  getByLibro: async (id_libro) => {
    try {
      const result = await pool.query(
        `SELECT c.id_concepto, c.termino, lc.definicion, lc.created_at
         FROM conceptos c
         JOIN libros_conceptos lc ON c.id_concepto = lc.id_concepto
         WHERE lc.id_libro = $1
         ORDER BY c.termino`,
        [id_libro]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en Conceptos.getByLibro():', error);
      throw error;
    }
  },

  // Agregar concepto a un libro
  addToLibro: async (id_libro, id_concepto, definicion) => {
    try {
      const result = await pool.query(
        `INSERT INTO libros_conceptos (id_libro, id_concepto, definicion)
         VALUES ($1, $2, $3)
         ON CONFLICT (id_libro, id_concepto) DO UPDATE SET definicion = $3
         RETURNING id_libro, id_concepto, definicion, created_at`,
        [id_libro, id_concepto, definicion]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Conceptos.addToLibro():', error);
      throw error;
    }
  },

  // Eliminar concepto de un libro
  removeFromLibro: async (id_libro, id_concepto) => {
    try {
      const result = await pool.query(
        'DELETE FROM libros_conceptos WHERE id_libro = $1 AND id_concepto = $2 RETURNING id_libro, id_concepto',
        [id_libro, id_concepto]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Conceptos.removeFromLibro():', error);
      throw error;
    }
  },

  // Eliminar concepto
  delete: async (id) => {
    try {
      const result = await pool.query(
        'DELETE FROM conceptos WHERE id_concepto = $1 RETURNING id_concepto',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Conceptos.delete():', error);
      throw error;
    }
  }
};

module.exports = Conceptos;
