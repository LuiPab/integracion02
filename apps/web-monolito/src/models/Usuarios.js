// Modelo de Usuarios
const pool = require('../config/database');
const bcrypt = require('bcryptjs');

const Usuarios = {
  // Obtener todos los usuarios
  getAll: async () => {
    try {
      const result = await pool.query('SELECT id_usuario, nombre, email, es_administrador, activo, created_at FROM usuarios ORDER BY created_at DESC');
      return result.rows;
    } catch (error) {
      console.error('Error en Usuarios.getAll():', error);
      throw error;
    }
  },

  // Obtener usuario por ID
  getById: async (id) => {
    try {
      const result = await pool.query(
        'SELECT id_usuario, nombre, email, es_administrador, activo, created_at FROM usuarios WHERE id_usuario = $1',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Usuarios.getById():', error);
      throw error;
    }
  },

  // Obtener usuario por email
  getByEmail: async (email) => {
    try {
      const result = await pool.query(
        'SELECT * FROM usuarios WHERE email = $1',
        [email.toLowerCase()]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Usuarios.getByEmail():', error);
      throw error;
    }
  },

  // Crear usuario
  create: async (nombre, email, password, es_administrador = false) => {
    try {
      // Verificar si ya existe un administrador
      if (es_administrador) {
        const adminExist = await pool.query('SELECT COUNT(*) FROM usuarios WHERE es_administrador = true');
        if (adminExist.rows[0].count > 0) {
          throw new Error('Ya existe un administrador en el sistema');
        }
      }

      // Hash de la contraseña
      const hashedPassword = await bcrypt.hash(password, 10);

      const result = await pool.query(
        'INSERT INTO usuarios (nombre, email, contraseña_hash, es_administrador, activo) VALUES ($1, $2, $3, $4, true) RETURNING id_usuario, nombre, email, es_administrador, created_at',
        [nombre, email.toLowerCase(), hashedPassword, es_administrador]
      );
      return result.rows[0];
    } catch (error) {
      console.error('Error en Usuarios.create():', error);
      throw error;
    }
  },

  // Actualizar usuario
  update: async (id, nombre, email) => {
    try {
      const result = await pool.query(
        'UPDATE usuarios SET nombre = $1, email = $2, updated_at = CURRENT_TIMESTAMP WHERE id_usuario = $3 RETURNING id_usuario, nombre, email, es_administrador, activo, updated_at',
        [nombre, email.toLowerCase(), id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Usuarios.update():', error);
      throw error;
    }
  },

  // Cambiar contraseña
  changePassword: async (id, newPassword) => {
    try {
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      const result = await pool.query(
        'UPDATE usuarios SET contraseña_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id_usuario = $2 RETURNING id_usuario, nombre, email',
        [hashedPassword, id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Usuarios.changePassword():', error);
      throw error;
    }
  },

  // Verificar contraseña
  verifyPassword: async (email, password) => {
    try {
      const user = await Usuarios.getByEmail(email);
      if (!user) return null;

      const isPasswordValid = await bcrypt.compare(password, user.contraseña_hash);
      return isPasswordValid ? user : null;
    } catch (error) {
      console.error('Error en Usuarios.verifyPassword():', error);
      throw error;
    }
  },

  // Eliminar usuario
  delete: async (id) => {
    try {
      // No permitir eliminar si es administrador
      const user = await Usuarios.getById(id);
      if (user && user.es_administrador) {
        throw new Error('No se puede eliminar el administrador del sistema');
      }

      const result = await pool.query(
        'DELETE FROM usuarios WHERE id_usuario = $1 RETURNING id_usuario',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Usuarios.delete():', error);
      throw error;
    }
  },

  // Activar/Desactivar usuario
  toggleActive: async (id) => {
    try {
      const result = await pool.query(
        'UPDATE usuarios SET activo = NOT activo, updated_at = CURRENT_TIMESTAMP WHERE id_usuario = $1 RETURNING id_usuario, nombre, email, es_administrador, activo',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Usuarios.toggleActive():', error);
      throw error;
    }
  }
};

module.exports = Usuarios;
