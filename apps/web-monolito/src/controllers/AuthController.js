// Controlador de autenticación y usuarios
const Usuarios = require('../models/Usuarios');

const AuthController = {
  // Mostrar página de login
  showLogin: (req, res) => {
    res.render('auth/login', { title: 'Iniciar sesión' });
  },

  // Procesar login
  login: async (req, res) => {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.render('auth/login', { title: 'Iniciar sesión', error: 'Email y contraseña son requeridos' });
      }

      const user = await Usuarios.verifyPassword(email, password);
      if (!user) {
        return res.render('auth/login', { title: 'Iniciar sesión', error: 'Email o contraseña incorrectos' });
      }

      if (!user.activo) {
        return res.render('auth/login', { title: 'Iniciar sesión', error: 'La cuenta está desactivada' });
      }

      // Establecer sesión
      req.session.userId = user.id_usuario;
      req.session.userName = user.nombre;
      req.session.isAdmin = user.es_administrador;

      res.redirect('/');
    } catch (error) {
      console.error('Error en AuthController.login():', error);
      res.render('auth/login', { title: 'Iniciar sesión', error: 'Error al iniciar sesión' });
    }
  },

  // Mostrar página de registro
  showRegister: (req, res) => {
    res.render('auth/register', { title: 'Crear cuenta' });
  },

  // Procesar registro
  register: async (req, res) => {
    try {
      const { nombre, email, password, passwordConfirm } = req.body;

      if (!nombre || !email || !password || !passwordConfirm) {
        return res.render('auth/register', { title: 'Crear cuenta', error: 'Todos los campos son requeridos' });
      }

      if (password !== passwordConfirm) {
        return res.render('auth/register', { title: 'Crear cuenta', error: 'Las contraseñas no coinciden' });
      }

      if (password.length < 6) {
        return res.render('auth/register', { title: 'Crear cuenta', error: 'La contraseña debe tener al menos 6 caracteres' });
      }

      // Verificar si el email ya existe
      const existingUser = await Usuarios.getByEmail(email);
      if (existingUser) {
        return res.render('auth/register', { title: 'Crear cuenta', error: 'El email ya está registrado' });
      }

      // Crear usuario
      await Usuarios.create(nombre, email, password);

      res.render('auth/register', { title: 'Crear cuenta', success: 'Cuenta creada exitosamente. Por favor inicia sesión.' });
    } catch (error) {
      console.error('Error en AuthController.register():', error);
      res.render('auth/register', { title: 'Crear cuenta', error: 'Error al crear la cuenta' });
    }
  },

  // Logout
  logout: (req, res) => {
    req.session.destroy((err) => {
      if (err) {
        console.error('Error al destruir sesión:', err);
      }
      res.redirect('/login');
    });
  }
};

module.exports = AuthController;
