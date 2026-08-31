-- ============================================================================
-- SCHEMA DE BASE DE DATOS PARA SISTEMA DE GESTIÓN DE LIBROS
-- Sistema Web para Administración de Usuarios y Catálogo de Libros
-- ============================================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- ============================================================================
-- TABLAS DE CATÁLOGOS (Referencia)
-- ============================================================================

-- Tabla de Categorías/Formatos
CREATE TABLE IF NOT EXISTS formatos (
    id_formato SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS generos (
    id_genero SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABLA DE USUARIOS Y ADMINISTRADOR
-- ============================================================================

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    contraseña_hash VARCHAR(255) NOT NULL,
    es_administrador BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unico_administrador CHECK (
        NOT (es_administrador = TRUE AND 
            EXISTS (SELECT 1 FROM usuarios WHERE es_administrador = TRUE AND id_usuario != usuarios.id_usuario))
    )
);

-- ============================================================================
-- TABLA DE AUTORES
-- ============================================================================

CREATE TABLE IF NOT EXISTS autores (
    id_autor SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    apellido VARCHAR(150) NOT NULL,
    biografia TEXT,
    fecha_nacimiento DATE,
    nacionalidad VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABLA DE CONCEPTOS
-- ============================================================================

CREATE TABLE IF NOT EXISTS conceptos (
    id_concepto SERIAL PRIMARY KEY,
    termino VARCHAR(200) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABLA PRINCIPAL DE LIBROS
-- ============================================================================

CREATE TABLE IF NOT EXISTS libros (
    id_libro UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    isbn VARCHAR(17) NOT NULL UNIQUE,
    titulo VARCHAR(255) NOT NULL,
    year_publicacion INTEGER,
    precio DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    id_formato INTEGER NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_formato) REFERENCES formatos(id_formato) ON DELETE RESTRICT,
    CONSTRAINT precio_positivo CHECK (precio > 0),
    CONSTRAINT stock_no_negativo CHECK (stock >= 0)
);

-- ============================================================================
-- TABLA ASOCIATIVA: LIBROS - AUTORES (N:N)
-- ============================================================================

CREATE TABLE IF NOT EXISTS libros_autores (
    id_libro UUID NOT NULL,
    id_autor INTEGER NOT NULL,
    orden_autor INTEGER,
    PRIMARY KEY (id_libro, id_autor),
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro) ON DELETE CASCADE,
    FOREIGN KEY (id_autor) REFERENCES autores(id_autor) ON DELETE CASCADE
);

-- ============================================================================
-- TABLA ASOCIATIVA: LIBROS - GÉNEROS (N:N)
-- ============================================================================

CREATE TABLE IF NOT EXISTS libros_generos (
    id_libro UUID NOT NULL,
    id_genero INTEGER NOT NULL,
    PRIMARY KEY (id_libro, id_genero),
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro) ON DELETE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES generos(id_genero) ON DELETE CASCADE
);

-- ============================================================================
-- TABLA ASOCIATIVA: LIBROS - CONCEPTOS (N:N) CON DEFINICIÓN
-- Permite que un mismo concepto aparezca en diferentes libros con distintas definiciones
-- ============================================================================

CREATE TABLE IF NOT EXISTS libros_conceptos (
    id_libro UUID NOT NULL,
    id_concepto INTEGER NOT NULL,
    definicion TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_libro, id_concepto),
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro) ON DELETE CASCADE,
    FOREIGN KEY (id_concepto) REFERENCES conceptos(id_concepto) ON DELETE CASCADE
);

-- ============================================================================
-- TABLA DE IMÁGENES DE LIBROS
-- ============================================================================

CREATE TABLE IF NOT EXISTS imagenes (
    id_imagen UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_libro UUID NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo VARCHAR(500) NOT NULL,
    tipo_mime VARCHAR(50),
    tamaño_bytes BIGINT,
    es_portada BOOLEAN DEFAULT FALSE,
    orden INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro) ON DELETE CASCADE,
    CONSTRAINT una_portada_por_libro UNIQUE (id_libro, es_portada) WHERE es_portada = TRUE
);

-- ============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ============================================================================

-- Índices en tabla libros
CREATE INDEX idx_libros_isbn ON libros(isbn);
CREATE INDEX idx_libros_titulo ON libros(titulo);
CREATE INDEX idx_libros_formato ON libros(id_formato);

-- Índices en tabla autores
CREATE INDEX idx_autores_nombre ON autores(nombre, apellido);

-- Índices en tabla usuarios
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_administrador ON usuarios(es_administrador);

-- Índices en tablas asociativas
CREATE INDEX idx_libros_autores_autor ON libros_autores(id_autor);
CREATE INDEX idx_libros_generos_genero ON libros_generos(id_genero);
CREATE INDEX idx_libros_conceptos_concepto ON libros_conceptos(id_concepto);

-- Índices en tabla de imágenes
CREATE INDEX idx_imagenes_libro ON imagenes(id_libro);
CREATE INDEX idx_imagenes_portada ON imagenes(id_libro, es_portada);

-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================

-- Vista de información completa de libros
CREATE OR REPLACE VIEW v_libros_completo AS
SELECT 
    l.id_libro,
    l.isbn,
    l.titulo,
    l.year_publicacion,
    l.precio,
    l.stock,
    f.nombre AS formato,
    l.descripcion,
    l.created_at,
    l.updated_at,
    STRING_AGG(DISTINCT CONCAT(a.nombre, ' ', a.apellido), ', ' ORDER BY CONCAT(a.nombre, ' ', a.apellido)) AS autores,
    STRING_AGG(DISTINCT g.nombre, ', ' ORDER BY g.nombre) AS generos,
    COUNT(DISTINCT i.id_imagen) AS cantidad_imagenes
FROM libros l
LEFT JOIN formatos f ON l.id_formato = f.id_formato
LEFT JOIN libros_autores la ON l.id_libro = la.id_libro
LEFT JOIN autores a ON la.id_autor = a.id_autor
LEFT JOIN libros_generos lg ON l.id_libro = lg.id_libro
LEFT JOIN generos g ON lg.id_genero = g.id_genero
LEFT JOIN imagenes i ON l.id_libro = i.id_libro
GROUP BY l.id_libro, f.nombre;

-- Vista de conceptos por libro
CREATE OR REPLACE VIEW v_libros_conceptos AS
SELECT 
    l.id_libro,
    l.titulo,
    c.id_concepto,
    c.termino,
    lc.definicion,
    lc.created_at
FROM libros l
INNER JOIN libros_conceptos lc ON l.id_libro = lc.id_libro
INNER JOIN conceptos c ON lc.id_concepto = c.id_concepto
ORDER BY l.titulo, c.termino;

-- ============================================================================
-- FUNCIONES Y TRIGGERS PARA INTEGRIDAD
-- ============================================================================

-- Función para actualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at
CREATE TRIGGER trigger_libros_updated_at
BEFORE UPDATE ON libros
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trigger_autores_updated_at
BEFORE UPDATE ON autores
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trigger_usuarios_updated_at
BEFORE UPDATE ON usuarios
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();

-- Función para garantizar máximo un administrador
CREATE OR REPLACE FUNCTION validar_unico_administrador()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.es_administrador = TRUE THEN
        IF EXISTS (SELECT 1 FROM usuarios WHERE es_administrador = TRUE AND id_usuario != NEW.id_usuario) THEN
            RAISE EXCEPTION 'Solo puede existir un administrador en el sistema';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_unico_administrador
BEFORE INSERT OR UPDATE ON usuarios
FOR EACH ROW
EXECUTE FUNCTION validar_unico_administrador();

-- ============================================================================
-- DATOS INICIALES
-- ============================================================================

-- Insertar formatos iniciales
INSERT INTO formatos (nombre, descripcion) VALUES
    ('Tapa Dura', 'Libro encuadernado en tapa dura'),
    ('Tapa Blanda', 'Libro encuadernado en tapa blanda'),
    ('Ebook', 'Libro en formato digital'),
    ('Audiolibro', 'Libro en formato de audio')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar géneros iniciales
INSERT INTO generos (nombre, descripcion) VALUES
    ('Ficción', 'Obras de narrativa de ficción'),
    ('No Ficción', 'Obras basadas en hechos reales'),
    ('Ciencia Ficción', 'Obras de ciencia ficción'),
    ('Fantasía', 'Obras de fantasía'),
    ('Misterio', 'Novelas de misterio y suspenso'),
    ('Romance', 'Novelas románticas'),
    ('Educativo', 'Libros educativos y académicos'),
    ('Infantil', 'Libros para niños'),
    ('Autoayuda', 'Libros de autoayuda y desarrollo personal'),
    ('Técnico', 'Libros técnicos y especializados')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar categorías iniciales
INSERT INTO categorias (nombre, descripcion) VALUES
    ('Best Seller', 'Libros más vendidos'),
    ('Clásicos', 'Clásicos de la literatura'),
    ('Nuevas Publicaciones', 'Lanzamientos recientes'),
    ('Ofertas', 'Libros en promoción')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================================================

COMMENT ON TABLE libros IS 'Tabla principal que almacena la información de libros del catálogo';
COMMENT ON TABLE libros_autores IS 'Tabla asociativa que relaciona libros con autores (relación N:N)';
COMMENT ON TABLE libros_generos IS 'Tabla asociativa que relaciona libros con géneros (relación N:N)';
COMMENT ON TABLE libros_conceptos IS 'Tabla asociativa que almacena conceptos definidos en cada libro con definiciones específicas por libro (relación N:N)';
COMMENT ON TABLE imagenes IS 'Tabla que almacena referencias a imágenes de libros';
COMMENT ON TABLE usuarios IS 'Tabla que almacena usuarios del sistema, con máximo un administrador';
COMMENT ON TABLE conceptos IS 'Tabla de catálogo de conceptos o términos utilizados en libros';

-- ============================================================================
-- FIN DEL SCHEMA
-- ============================================================================
