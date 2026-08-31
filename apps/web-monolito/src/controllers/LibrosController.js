// Controlador de libros
const Libros = require('../models/Libros');
const Autores = require('../models/Autores');
const LibrosAutores = require('../models/LibrosAutores');
const Generos = require('../models/Generos');
const LibrosGeneros = require('../models/LibrosGeneros');
const Imagenes = require('../models/Imagenes');
const Conceptos = require('../models/Conceptos');
const Formatos = require('../models/Formatos');
const fs = require('fs');
const path = require('path');

const LibrosController = {
  // Listar todos los libros con paginación
  listLibros: async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = 10;
      const offset = (page - 1) * limit;

      const libros = await Libros.getAll(limit, offset);
      const totalLibros = await Libros.count();
      const totalPages = Math.ceil(totalLibros / limit);

      res.render('libros/list', {
        title: 'Catálogo de Libros',
        libros,
        page,
        totalPages,
        totalLibros
      });
    } catch (error) {
      console.error('Error en LibrosController.listLibros():', error);
      res.status(500).render('error', { message: 'Error al listar libros' });
    }
  },

  // Ver detalle de un libro
  viewLibro: async (req, res) => {
    try {
      const { id } = req.params;
      const libro = await Libros.getById(id);

      if (!libro) {
        return res.status(404).render('error', { message: 'Libro no encontrado' });
      }

      const autores = await LibrosAutores.getAutoresByLibro(id);
      const generos = await LibrosGeneros.getGenerosByLibro(id);
      const imagenes = await Imagenes.getByLibro(id);
      const conceptos = await Conceptos.getByLibro(id);

      res.render('libros/view', {
        title: libro.titulo,
        libro,
        autores,
        generos,
        imagenes,
        conceptos
      });
    } catch (error) {
      console.error('Error en LibrosController.viewLibro():', error);
      res.status(500).render('error', { message: 'Error al obtener el libro' });
    }
  },

  // Mostrar formulario crear libro (solo admin)
  showCreateForm: async (req, res) => {
    try {
      const formatos = await Formatos.getAll();
      res.render('libros/create', {
        title: 'Crear libro',
        formatos
      });
    } catch (error) {
      console.error('Error en LibrosController.showCreateForm():', error);
      res.status(500).render('error', { message: 'Error al cargar el formulario' });
    }
  },

  // Crear libro (solo admin)
  createLibro: async (req, res) => {
    try {
      const { isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion } = req.body;

      if (!isbn || !titulo || !id_formato || !precio || stock === undefined) {
        return res.status(400).render('error', { message: 'Campos requeridos faltantes' });
      }

      const libro = await Libros.create(isbn, titulo, year_publicacion || null, precio, stock, id_formato, descripcion || null);

      res.redirect(`/libros/${libro.id_libro}`);
    } catch (error) {
      console.error('Error en LibrosController.createLibro():', error);
      res.status(500).render('error', { message: 'Error al crear el libro' });
    }
  },

  // Mostrar formulario editar libro (solo admin)
  showEditForm: async (req, res) => {
    try {
      const { id } = req.params;
      const libro = await Libros.getById(id);
      const formatos = await Formatos.getAll();

      if (!libro) {
        return res.status(404).render('error', { message: 'Libro no encontrado' });
      }

      res.render('libros/edit', {
        title: `Editar: ${libro.titulo}`,
        libro,
        formatos
      });
    } catch (error) {
      console.error('Error en LibrosController.showEditForm():', error);
      res.status(500).render('error', { message: 'Error al cargar el formulario' });
    }
  },

  // Actualizar libro (solo admin)
  updateLibro: async (req, res) => {
    try {
      const { id } = req.params;
      const { isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion } = req.body;

      if (!isbn || !titulo || !id_formato || !precio || stock === undefined) {
        return res.status(400).render('error', { message: 'Campos requeridos faltantes' });
      }

      await Libros.update(id, isbn, titulo, year_publicacion || null, precio, stock, id_formato, descripcion || null);

      res.redirect(`/libros/${id}`);
    } catch (error) {
      console.error('Error en LibrosController.updateLibro():', error);
      res.status(500).render('error', { message: 'Error al actualizar el libro' });
    }
  },

  // Eliminar libro (solo admin)
  deleteLibro: async (req, res) => {
    try {
      const { id } = req.params;

      // Eliminar imágenes del servidor
      const imagenes = await Imagenes.getByLibro(id);
      imagenes.forEach((img) => {
        const filePath = path.join(__dirname, '../../public', img.ruta_archivo);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      });

      await Libros.delete(id);

      res.redirect('/libros');
    } catch (error) {
      console.error('Error en LibrosController.deleteLibro():', error);
      res.status(500).render('error', { message: 'Error al eliminar el libro' });
    }
  },

  // Buscar libros
  searchLibros: async (req, res) => {
    try {
      const { query } = req.query;

      if (!query || query.trim() === '') {
        return res.redirect('/libros');
      }

      const libros = await Libros.searchByTitle(query);

      res.render('libros/list', {
        title: `Resultados de búsqueda: "${query}"`,
        libros,
        query
      });
    } catch (error) {
      console.error('Error en LibrosController.searchLibros():', error);
      res.status(500).render('error', { message: 'Error al buscar libros' });
    }
  }
};

module.exports = LibrosController;
