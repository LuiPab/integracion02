// Rutas principales
const express = require('express');
const router = express.Router();
const { isAuthenticated, isAdmin } = require('../middleware/auth');
const LibrosController = require('../controllers/LibrosController');
const AuthController = require('../controllers/AuthController');

// Rutas de autenticación (sin autenticación)
router.get('/login', (req, res) => {
  if (req.session && req.session.userId) {
    return res.redirect('/');
  }
  AuthController.showLogin(req, res);
});

router.post('/login', AuthController.login);

router.get('/register', (req, res) => {
  if (req.session && req.session.userId) {
    return res.redirect('/');
  }
  AuthController.showRegister(req, res);
});

router.post('/register', AuthController.register);

router.get('/logout', AuthController.logout);

// Ruta principal
router.get('/', async (req, res) => {
  try {
    // Obtener últimos libros
    const libros = await require('../models/Libros').getAll(10, 0);
    res.render('index', { title: 'Inicio', libros });
  } catch (error) {
    console.error('Error en ruta /:', error);
    res.render('index', { title: 'Inicio', libros: [] });
  }
});

// Rutas de libros
router.get('/libros', LibrosController.listLibros);
router.get('/libros/search', LibrosController.searchLibros);
router.get('/libros/:id', LibrosController.viewLibro);

// Rutas admin para libros
router.get('/admin/libros/crear', isAuthenticated, isAdmin, LibrosController.showCreateForm);
router.post('/admin/libros/crear', isAuthenticated, isAdmin, LibrosController.createLibro);
router.get('/admin/libros/:id/editar', isAuthenticated, isAdmin, LibrosController.showEditForm);
router.post('/admin/libros/:id/editar', isAuthenticated, isAdmin, LibrosController.updateLibro);
router.post('/admin/libros/:id/eliminar', isAuthenticated, isAdmin, LibrosController.deleteLibro);

module.exports = router;
