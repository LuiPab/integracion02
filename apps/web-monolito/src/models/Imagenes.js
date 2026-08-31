// Modelo de Imágenes
const pool = require('../config/database');

const Imagenes = {
  // Obtener todas las imágenes de un libro
  getByLibro: async (id_libro) => {
    try {
      const result = await pool.query(
        `SELECT id_imagen, id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden, created_at
         FROM imagenes 
         WHERE id_libro = $1 
         ORDER BY es_portada DESC, orden ASC, created_at DESC`,
        [id_libro]
      );
      return result.rows;
    } catch (error) {
      console.error('Error en Imagenes.getByLibro():', error);
      throw error;
    }
  },

  // Obtener imagen por ID
  getById: async (id) => {
    try {
      const result = await pool.query(
        'SELECT id_imagen, id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden, created_at FROM imagenes WHERE id_imagen = $1',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Imagenes.getById():', error);
      throw error;
    }
  },

  // Obtener portada de un libro
  getPortada: async (id_libro) => {
    try {
      const result = await pool.query(
        'SELECT id_imagen, ruta_archivo FROM imagenes WHERE id_libro = $1 AND es_portada = true LIMIT 1',
        [id_libro]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Imagenes.getPortada():', error);
      throw error;
    }
  },

  // Crear imagen
  create: async (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada = false, orden = null) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Si es portada, desmarcar la portada anterior
      if (es_portada) {
        await client.query(
          'UPDATE imagenes SET es_portada = false WHERE id_libro = $1',
          [id_libro]
        );
      }

      const result = await client.query(
        `INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id_imagen, id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden, created_at`,
        [id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden]
      );

      await client.query('COMMIT');
      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error en Imagenes.create():', error);
      throw error;
    } finally {
      client.release();
    }
  },

  // Actualizar imagen
  update: async (id, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Obtener id_libro de la imagen
      const imageRes = await client.query('SELECT id_libro FROM imagenes WHERE id_imagen = $1', [id]);
      if (imageRes.rows.length === 0) {
        throw new Error('Imagen no encontrada');
      }
      const id_libro = imageRes.rows[0].id_libro;

      // Si es portada, desmarcar la portada anterior
      if (es_portada) {
        await client.query(
          'UPDATE imagenes SET es_portada = false WHERE id_libro = $1 AND id_imagen != $2',
          [id_libro, id]
        );
      }

      const result = await client.query(
        `UPDATE imagenes 
         SET nombre_archivo = $1, ruta_archivo = $2, tipo_mime = $3, tamaño_bytes = $4, es_portada = $5
         WHERE id_imagen = $6
         RETURNING id_imagen, id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden`,
        [nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, id]
      );

      await client.query('COMMIT');
      return result.rows[0] || null;
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error en Imagenes.update():', error);
      throw error;
    } finally {
      client.release();
    }
  },

  // Eliminar imagen
  delete: async (id) => {
    try {
      const result = await pool.query(
        'DELETE FROM imagenes WHERE id_imagen = $1 RETURNING id_imagen, id_libro',
        [id]
      );
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error en Imagenes.delete():', error);
      throw error;
    }
  }
};

module.exports = Imagenes;
