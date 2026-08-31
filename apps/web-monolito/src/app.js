// Aplicación principal - Monolito web para gestión de librería
const express = require('express');
const path = require('path');
const session = require('express-session');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
require('dotenv').config();

// Inicializar aplicación
const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de vistas
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware de parseo
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cookieParser());

// Middleware de sesión
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key-change-in-production',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: false, // Cambiar a true en producción con HTTPS
    maxAge: 24 * 60 * 60 * 1000 // 24 horas
  }
}));

// Archivos estáticos
app.use(express.static(path.join(__dirname, '../public')));

// Middleware de variables locales
const { setUserLocal } = require('./middleware/auth');
app.use(setUserLocal);

// Rutas
const routes = require('./routes/index');
app.use(routes);

// Página 404
app.use((req, res) => {
  res.status(404).render('404', { title: 'Página no encontrada' });
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error('Error sin manejar:', err);
  res.status(500).render('error', { 
    message: 'Ocurrió un error en el servidor',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});

// Iniciar servidor
const server = app.listen(PORT, () => {
  console.log(`\n✓ Servidor iniciado en http://localhost:${PORT}`);
  console.log('✓ Presiona CTRL+C para detener el servidor\n');
});

// Manejo de señales para cierre limpio
process.on('SIGINT', () => {
  console.log('\n✓ Servidor detenido correctamente');
  process.exit(0);
});

module.exports = app;
