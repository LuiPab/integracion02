// Configuración de conexión a PostgreSQL
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'library_user',
  password: process.env.DB_PASSWORD || 'libraryApp',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'library_db',
});

// Manejo de errores de conexión
pool.on('error', (err) => {
  console.error('Error en la conexión a la base de datos:', err);
  process.exit(-1);
});

// Verificar conexión
pool.connect((err, client, release) => {
  if (err) {
    console.error('Error al conectar a la base de datos:', err);
    process.exit(-1);
  } else {
    console.log('✓ Conexión a PostgreSQL exitosa');
    release();
  }
});

module.exports = pool;
