# 📚 Librería Online - Aplicación Web Monolítica

Sistema web monolítico desarrollado en Node.js para la gestión completa de una librería en línea con renderización de HTML del lado del servidor (SSR).

## Características

✅ **Gestión de Libros**: CRUD completo de libros con todos sus atributos  
✅ **Gestión de Usuarios**: Registro, login y control de acceso  
✅ **Administrador**: Máximo un administrador en el sistema  
✅ **Relaciones N:N**: Manejo completo de:
- Libros → Autores (múltiples autores por libro)
- Libros → Géneros (múltiples géneros por libro)
- Libros → Conceptos (con definiciones específicas por libro)
- Libros → Imágenes (con designación de portada)

✅ **Patrón MVC**: Arquitectura Modelo Vista Controlador  
✅ **Modularizado**: Código organizado por módulos  
✅ **Seguridad**: Autenticación y autorización con sesiones  
✅ **Base de Datos Normalizada**: PostgreSQL con diseño 3NF

## Requisitos Previos

- CentOS 10 Stream
- PostgreSQL instalado y funcionando
- Node.js 16+ y npm
- Usuario y base de datos creados en PostgreSQL:
  - Usuario: `library_user`
  - Contraseña: `libraryApp`
  - Base de datos: `library_db`

## Instalación en CentOS 10 Stream

### 1. Preparar la Base de Datos

```bash
# Conectarse a PostgreSQL
sudo -u postgres psql

# Dentro de psql, ejecutar:
CREATE DATABASE library_db;
CREATE USER library_user WITH PASSWORD 'libraryApp';
ALTER ROLE library_user SET client_encoding TO 'utf8';
ALTER ROLE library_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE library_user SET default_transaction_deferrable TO on;
ALTER ROLE library_user SET default_transaction_deferrable TO off;
GRANT ALL PRIVILEGES ON DATABASE library_db TO library_user;
\c library_db
GRANT ALL PRIVILEGES ON SCHEMA public TO library_user;
\q
```

### 2. Importar el Schema

```bash
# Conectarse a la base de datos e importar el schema
psql -U library_user -d library_db -h localhost < path/to/schema.sql

# Verificar que las tablas se crearon correctamente
psql -U library_user -d library_db -h localhost -c "\dt"
```

### 3. Instalar la Aplicación

```bash
# Navegar al directorio de la aplicación
cd /ruta/a/web-monolito

# Instalar dependencias
npm install

# Crear archivo .env con la configuración
cp .env.example .env

# Verificar que .env tiene la configuración correcta
cat .env
```

### 4. Configurar el Archivo .env

```bash
nano .env
```

Asegurar que tenga los siguientes valores:

```
DB_HOST=localhost
DB_PORT=5432
DB_USER=library_user
DB_PASSWORD=libraryApp
DB_NAME=library_db
PORT=3000
NODE_ENV=production
SESSION_SECRET=cambiar-esto-por-una-clave-segura-larga
```

### 5. Iniciar la Aplicación

```bash
# Desarrollo (con reinicio automático)
npm run dev

# Producción
npm start
```

La aplicación estará disponible en `http://localhost:3000`

## Configuración de Systemd (Recomendado para Producción)

Crear un servicio systemd para que la aplicación se reinicie automáticamente:

### 1. Crear archivo de servicio

```bash
sudo nano /etc/systemd/system/libreria-web.service
```

### 2. Agregar el siguiente contenido

```ini
[Unit]
Description=Librería Online - Aplicación Web
After=network.target
Requires=postgresql.service

[Service]
Type=simple
User=nodejs
WorkingDirectory=/ruta/a/web-monolito
Environment="NODE_ENV=production"
Environment="PORT=3000"
ExecStart=/usr/bin/node /ruta/a/web-monolito/src/app.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 3. Crear usuario para el servicio

```bash
sudo useradd -r -s /bin/false nodejs
sudo chown -R nodejs:nodejs /ruta/a/web-monolito
```

### 4. Habilitar e iniciar el servicio

```bash
sudo systemctl daemon-reload
sudo systemctl enable libreria-web.service
sudo systemctl start libreria-web.service

# Verificar estado
sudo systemctl status libreria-web.service

# Ver logs
sudo journalctl -u libreria-web.service -f
```

## Configuración con Nginx (Recomendado para Producción)

### 1. Instalar Nginx

```bash
sudo dnf install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 2. Crear archivo de configuración

```bash
sudo nano /etc/nginx/conf.d/libreria.conf
```

### 3. Agregar la siguiente configuración

```nginx
upstream library_app {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Redirigir HTTP a HTTPS (comentar si no tienes SSL)
    # return 301 https://$server_name$request_uri;

    # Descomenta para HTTPS
    # listen 443 ssl http2;
    # ssl_certificate /ruta/a/certificado.crt;
    # ssl_certificate_key /ruta/a/certificado.key;
    # ssl_protocols TLSv1.2 TLSv1.3;
    # ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 50M;
    
    location / {
        proxy_pass http://library_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_pass http://library_app;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 4. Verificar y recargar Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Estructura del Proyecto

```
web-monolito/
├── src/
│   ├── app.js                 # Archivo principal
│   ├── config/
│   │   └── database.js       # Configuración de BD
│   ├── models/               # Modelos (acceso a datos)
│   │   ├── Usuarios.js
│   │   ├── Libros.js
│   │   ├── Autores.js
│   │   ├── Generos.js
│   │   ├── Formatos.js
│   │   ├── Imagenes.js
│   │   ├── Conceptos.js
│   │   ├── LibrosAutores.js
│   │   └── LibrosGeneros.js
│   ├── controllers/          # Controladores
│   │   ├── AuthController.js
│   │   └── LibrosController.js
│   ├── routes/
│   │   └── index.js         # Definición de rutas
│   ├── middleware/
│   │   └── auth.js          # Middleware de autenticación
│   └── views/               # Plantillas EJS
│       ├── layout.ejs
│       ├── index.ejs
│       ├── error.ejs
│       ├── 404.ejs
│       ├── auth/
│       │   ├── login.ejs
│       │   └── register.ejs
│       └── libros/
│           ├── list.ejs
│           ├── view.ejs
│           ├── create.ejs
│           └── edit.ejs
├── public/
│   ├── css/
│   ├── js/
│   └── images/
├── package.json
├── .env.example
├── .gitignore
└── README.md
```

## Uso de la Aplicación

### Primer Acceso - Crear Administrador

1. Acceder a `http://localhost:3000`
2. Hacer clic en "Crear cuenta"
3. Registrar un nuevo usuario
4. Para convertir el primer usuario en administrador, ejecutar en PostgreSQL:

```sql
UPDATE usuarios SET es_administrador = true WHERE id_usuario = (SELECT id_usuario FROM usuarios ORDER BY created_at ASC LIMIT 1);
```

### Flujo de Uso

**Para Usuarios Normales:**
- Registrarse/Iniciar sesión
- Explorar catálogo de libros
- Buscar libros por título
- Ver detalles de libros (autores, géneros, conceptos, imágenes)

**Para Administradores:**
- Todas las funciones de usuario
- Crear nuevos libros
- Editar información de libros
- Eliminar libros
- Gestionar autores, géneros y conceptos

## API de Base de Datos

### Endpoints de Libros

```
GET /libros                    - Listar libros (con paginación)
GET /libros/:id               - Ver detalles del libro
GET /libros/search?query=...  - Buscar libros por título
POST /admin/libros/crear      - Crear nuevo libro (admin)
POST /admin/libros/:id/editar - Editar libro (admin)
POST /admin/libros/:id/eliminar - Eliminar libro (admin)
```

## Troubleshooting

### Error: "Connection refused" a PostgreSQL

```bash
# Verificar que PostgreSQL está ejecutándose
sudo systemctl status postgresql

# Verificar conexión manualmente
psql -U library_user -d library_db -h localhost
```

### Error: "EACCES: permission denied"

```bash
# Verificar permisos
ls -la /ruta/a/web-monolito

# Corregir si es necesario
chmod 755 /ruta/a/web-monolito
```

### Puerto 3000 ya en uso

```bash
# Cambiar en .env
PORT=3001

# O liberar el puerto
sudo lsof -i :3000
sudo kill -9 <PID>
```

## Mantenimiento

### Logs

```bash
# Ver logs de la aplicación
sudo journalctl -u libreria-web.service -f

# Ver logs de nginx
sudo tail -f /var/log/nginx/error.log
```

### Backups de Base de Datos

```bash
# Crear backup
pg_dump -U library_user library_db > backup_$(date +%Y%m%d).sql

# Restaurar backup
psql -U library_user library_db < backup_20240101.sql
```

### Actualizar Dependencias

```bash
npm update
npm outdated
```

## Seguridad

⚠️ **Importante para Producción:**

1. Cambiar `SESSION_SECRET` en `.env` por una clave segura
2. Usar HTTPS (configurar certificado SSL)
3. Configurar firewall
4. Usar contraseñas fuertes para PostgreSQL
5. Realizar backups regulares
6. Mantener Node.js y dependencias actualizadas
7. Configurar límites de rate en Nginx
8. Habilitar CORS restrictivo si es necesario

## Soporte

Para reportar problemas o sugerencias, contactar al administrador del sistema.

---

**Versión:** 1.0.0  
**Última actualización:** 2024
