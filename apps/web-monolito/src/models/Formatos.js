// Modelo de Formatos
const pool = require('../config/database');

const Formatos = {
  // Obtener todos los formatos
  getAll: async () => {
    try {
      const result = await pool.query('SELECT id_formato, nombre, descripcion FROM formatos ORDER BY nombre');
      return result.rows;
    } catch (error) {
      console.error('Error en Formatos.getAll():', error);
      throw error;
    }
  },

  // Obtener formato por ID
  getById: async (id) => {
    try {
      const result = await pool.query(
        'SELECT id_formato, nombre, descripcion FROM formatos WHERE id_formato = $1',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Formatos.getById():', error);
      throw error;
    }
  },

  // Crear formato
  create: async (nombre, descripcion = null) => {
    try {
      const result = await pool.query(
        'INSERT INTO formatos (nombre, descripcion) VALUES ($1, $2) RETURNING id_formato, nombre, descripcion',
        [nombre, descripcion]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Formatos.create():', error);
      throw error;
    }
  },

  // Actualizar formato
  update: async (id, nombre, descripcion) => {
    try {
      const result = await pool.query(
        'UPDATE formatos SET nombre = $1, descripcion = $2 WHERE id_formato = $3 RETURNING id_formato, nombre, descripcion',
        [nombre, descripcion, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Formatos.update():', error);
      throw error;
    }
  },

  // Eliminar formato
  delete: async (id) => {
    try {
      const result = await pool.query(
        'DELETE FROM formatos WHERE id_formato = $1 RETURNING id_formato',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Formatos.delete():', error);
      throw error;
    }
  }
};

module.exports = Formatos;
