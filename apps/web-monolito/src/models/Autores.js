// Modelo de Autores
const pool = require('../config/database');

const Autores = {
  // Obtener todos los autores
  getAll: async () => {
    try {
      const result = await pool.query('SELECT id_autor, nombre, apellido, biografia, fecha_nacimiento, nacionalidad FROM autores ORDER BY apellido, nombre');
      return result.rows;
    } catch (error) {
      console.error('Error en Autores.getAll():', error);
      throw error;
    }
  },

  // Obtener autor por ID
  getById: async (id) => {
    try {
      const result = await pool.query(
        'SELECT id_autor, nombre, apellido, biografia, fecha_nacimiento, nacionalidad, created_at FROM autores WHERE id_autor = $1',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Autores.getById():', error);
      throw error;
    }
  },

  // Crear autor
  create: async (nombre, apellido, biografia = null, fecha_nacimiento = null, nacionalidad = null) => {
    try {
      const result = await pool.query(
        `INSERT INTO autores (nombre, apellido, biografia, fecha_nacimiento, nacionalidad) 
         VALUES ($1, $2, $3, $4, $5) 
         RETURNING id_autor, nombre, apellido, biografia, fecha_nacimiento, nacionalidad, created_at`,
        [nombre, apellido, biografia, fecha_nacimiento, nacionalidad]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Autores.create():', error);
      throw error;
    }
  },

  // Actualizar autor
  update: async (id, nombre, apellido, biografia, fecha_nacimiento, nacionalidad) => {
    try {
      const result = await pool.query(
        `UPDATE autores 
         SET nombre = $1, apellido = $2, biografia = $3, fecha_nacimiento = $4, nacionalidad = $5, updated_at = CURRENT_TIMESTAMP
         WHERE id_autor = $6
         RETURNING id_autor, nombre, apellido, biografia, fecha_nacimiento, nacionalidad, updated_at`,
        [nombre, apellido, biografia, fecha_nacimiento, nacionalidad, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Autores.update():', error);
      throw error;
    }
  },

  // Eliminar autor
  delete: async (id) => {
    try {
      const result = await pool.query(
        'DELETE FROM autores WHERE id_autor = $1 RETURNING id_autor',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Autores.delete():', error);
      throw error;
    }
  },

  // Obtener autores de un libro
  getByLibro: async (id_libro) => {
    try {
      const result = await pool.query(
        `SELECT a.id_autor, a.nombre, a.apellido, a.biografia, la.orden_autor
         FROM autores a
         JOIN libros_autores la ON a.id_autor = la.id_autor
         WHERE la.id_libro = $1
         ORDER BY la.orden_autor, a.apellido, a.nombre`,
        [id_libro]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en Autores.getByLibro():', error);
      throw error;
    }
  }
};

module.exports = Autores;
