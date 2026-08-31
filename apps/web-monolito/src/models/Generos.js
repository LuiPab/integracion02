// Modelo de Géneros
const pool = require('../config/database');

const Generos = {
  // Obtener todos los géneros
  getAll: async () => {
    try {
      const result = await pool.query('SELECT id_genero, nombre, descripcion, created_at FROM generos ORDER BY nombre');
      return result.rows;
    } catch (error) {
      console.error('Error en Generos.getAll():', error);
      throw error;
    }
  },

  // Obtener género por ID
  getById: async (id) => {
    try {
      const result = await pool.query(
        'SELECT id_genero, nombre, descripcion, created_at FROM generos WHERE id_genero = $1',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Generos.getById():', error);
      throw error;
    }
  },

  // Crear género
  create: async (nombre, descripcion = null) => {
    try {
      const result = await pool.query(
        'INSERT INTO generos (nombre, descripcion) VALUES ($1, $2) RETURNING id_genero, nombre, descripcion, created_at',
        [nombre, descripcion]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Generos.create():', error);
      throw error;
    }
  },

  // Actualizar género
  update: async (id, nombre, descripcion) => {
    try {
      const result = await pool.query(
        'UPDATE generos SET nombre = $1, descripcion = $2 WHERE id_genero = $3 RETURNING id_genero, nombre, descripcion',
        [nombre, descripcion, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Generos.update():', error);
      throw error;
    }
  },

  // Eliminar género
  delete: async (id) => {
    try {
      const result = await pool.query(
        'DELETE FROM generos WHERE id_genero = $1 RETURNING id_genero',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Generos.delete():', error);
      throw error;
    }
  }
};

module.exports = Generos;
