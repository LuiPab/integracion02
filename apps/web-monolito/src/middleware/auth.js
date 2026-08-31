// Middleware de autenticación
const Usuarios = require('../models/Usuarios');

// Middleware para verificar sesión
const isAuthenticated = (req, res, next) => {
  if (req.session && req.session.userId) {
    next();
  } else {
    res.redirect('/login');
  }
};

// Middleware para verificar admin
const isAdmin = async (req, res, next) => {
  if (req.session && req.session.userId) {
    try {
      const user = await Usuarios.getById(req.session.userId);
      if (user && user.es_administrador) {
        next();
      } else {
        res.status(403).render('error', { message: 'Acceso denegado: se requieren permisos de administrador' });
      }
    } catch (error) {
      console.error('Error en middleware isAdmin:', error);
      res.status(500).render('error', { message: 'Error en la verificación de permisos' });
    }
  } else {
    res.redirect('/login');
  }
};

// Middleware para establecer variables locales de usuario
const setUserLocal = async (req, res, next) => {
  if (req.session && req.session.userId) {
    try {
      const user = await Usuarios.getById(req.session.userId);
      res.locals.user = user;
      res.locals.isAdmin = user && user.es_administrador;
    } catch (error) {
      console.error('Error en middleware setUserLocal:', error);
      res.locals.user = null;
      res.locals.isAdmin = false;
    }
  } else {
    res.locals.user = null;
    res.locals.isAdmin = false;
  }
  next();
};

module.exports = {
  isAuthenticated,
  isAdmin,
  setUserLocal
};
