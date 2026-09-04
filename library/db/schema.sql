-- ============================================================================
-- SCHEMA DE BASE DE DATOS PARA SISTEMA DE GESTIÓN DE LIBROS
-- Sistema Web para Administración de Usuarios y Catálogo de Libros
-- ============================================================================

-- ============================================================================
-- LIMPIEZA DE TABLAS EXISTENTES (Drop everything cleanly)
-- ============================================================================

-- Eliminar tablas asociativas primero (por dependencias de FK)
DROP TABLE IF EXISTS libros_conceptos CASCADE;
DROP TABLE IF EXISTS libros_generos CASCADE;
DROP TABLE IF EXISTS libros_autores CASCADE;
DROP TABLE IF EXISTS imagenes CASCADE;

-- Eliminar tablas principales
DROP TABLE IF EXISTS libros CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS autores CASCADE;
DROP TABLE IF EXISTS conceptos CASCADE;
DROP TABLE IF EXISTS categorias CASCADE;
DROP TABLE IF EXISTS generos CASCADE;
DROP TABLE IF EXISTS formatos CASCADE;

-- Eliminar funciones existentes
DROP FUNCTION IF EXISTS actualizar_updated_at() CASCADE;
DROP FUNCTION IF EXISTS validar_unico_administrador() CASCADE;

-- Habilitar extensiones necesarias (CORREGIDA: UUID entre comillas)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    -- CORRECCIÓN 1: Se eliminó el CONSTRAINT CHECK con subconsulta (se maneja con Trigger más abajo)
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (nombre, apellido) -- CORRECCIÓN 2: Se agregó UNIQUE para que funcione el ON CONFLICT
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
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro) ON DELETE CASCADE
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

-- CORREGIDO: Índice independiente para una portada por libro
CREATE UNIQUE INDEX idx_una_portada_por_libro ON imagenes (id_libro) WHERE es_portada = true;

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
-- DATOS INICIALES - CATÁLOGOS
-- ============================================================================

-- Insertar formatos iniciales
INSERT INTO formatos (nombre, descripcion) VALUES
    ('Tapa Dura', 'Libro encuadernado en tapa dura con calidad premium'),
    ('Tapa Blanda', 'Libro encuadernado en tapa blanda, portátil y económico'),
    ('Ebook', 'Libro en formato digital para lectores electrónicos'),
    ('Audiolibro', 'Libro en formato de audio narrado profesionalmente')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar géneros iniciales
INSERT INTO generos (nombre, descripcion) VALUES
    ('Ficción', 'Obras de narrativa de ficción contemporánea'),
    ('Ciencia Ficción', 'Novelas de ciencia ficción y futuros alternativos'),
    ('Misterio', 'Novelas de misterio, suspenso y crimen'),
    ('Fantasía', 'Obras de fantasía, magia y mundos imaginarios'),
    ('Romance', 'Novelas románticas y de relaciones personales'),
    ('No Ficción', 'Obras basadas en hechos reales e investigación'),
    ('Histórico', 'Novelas históricas y de época'),
    ('Infantil', 'Libros para niños y jóvenes lectores')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar categorías iniciales
INSERT INTO categorias (nombre, descripcion) VALUES
    ('Best Seller', 'Libros más vendidos y populares'),
    ('Clásicos', 'Clásicos de la literatura mundial'),
    ('Nuevas Publicaciones', 'Lanzamientos recientes'),
    ('Ofertas', 'Libros en promoción especial')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================================================
-- DATOS DE PRUEBA - USUARIOS (3 usuarios)
-- ============================================================================

INSERT INTO usuarios (nombre, email, contraseña_hash, es_administrador, activo) VALUES
    ('Carlos Administrador', 'admin@libreria.com', '$2a$10$qSvgoHWbHrj6g9lZ8.xA6OmNXy6r5vY8k2p1m0n9o8l7k6j5i4h3', true, true),
    ('María Editora', 'editor@libreria.com', '$2a$10$fG9vH8iJ7kL6mN5oP4qR3sT2uV1wX0yZ9aB8cD7eF6gH5iJ4kL3m', false, true),
    ('Juan Lector', 'lector@libreria.com', '$2a$10$pL2mK1jI0hG9fE8dC7bA6yZ5xW4vU3tS2rQ1pO0nM9lK8jI7hG6f', false, true)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- DATOS DE PRUEBA - AUTORES (4 autores)
-- ============================================================================

INSERT INTO autores (nombre, apellido, biografia, fecha_nacimiento, nacionalidad) VALUES
    ('Gabriel', 'García Márquez', 'Novelista colombiano y ganador del Premio Nobel de Literatura. Autor de "Cien años de soledad".', '1927-03-06', 'Colombiana'),
    ('J.K.', 'Rowling', 'Autora británica famosa por la serie Harry Potter que revolucionó la literatura infantil y juvenil.', '1965-07-31', 'Británica'),
    ('Haruki', 'Murakami', 'Novelista japonés contemporáneo conocido por su estilo surreal y existencial en la ficción.', '1949-01-12', 'Japonesa'),
    ('Agatha', 'Christie', 'Autora británica de misterio y crimen, creadora del detective Hércules Poirot.', '1890-01-15', 'Británica')
ON CONFLICT (nombre, apellido) DO NOTHING;

-- ============================================================================
-- DATOS DE PRUEBA - CONCEPTOS (12 conceptos)
-- ============================================================================

INSERT INTO conceptos (termino) VALUES
    ('Realismo Mágico'),
    ('Magia'),
    ('Detectives Privados'),
    ('Mundos Paralelos'),
    ('Misterio Psicológico'),
    ('Aprendizaje Mágico'),
    ('Crimen Clásico'),
    ('Surrealismo'),
    ('Familia Disfuncional'),
    ('Viajes en el Tiempo'),
    ('Intriga Política'),
    ('Encuentros Paranormales')
ON CONFLICT (termino) DO NOTHING;

-- ============================================================================
-- DATOS DE PRUEBA - LIBROS (12 libros completos)
-- ============================================================================

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8439708032', 'Cien años de soledad', 1967, 32.50, 15, 1, 'Novela magistral de Gabriel García Márquez que narra la historia de la familia Buendía en el pueblo ficticio de Macondo. Una obra maestra del realismo mágico que ha influenciado a generaciones de lectores. La novela explora temas de amor, soledad, muerte y el ciclo inevitable de la historia humana.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8498384956', 'Harry Potter y la Piedra Filosofal', 1997, 18.90, 25, 2, 'El primer libro de la serie Harry Potter de J.K. Rowling. Narra el descubrimiento de Harry de que es un mago y su entrada a la Escuela Hogwarts. Una aventura llena de magia, amistad y misterio que cautivó a millones de lectores en todo el mundo.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8432217388', 'Kafka en la orilla', 2002, 22.00, 12, 1, 'Novela de Haruki Murakami que sigue a dos protagonistas: un adolescente que huye de su casa y un anciano sordo. Una obra surrealista que explora temas de identidad, soledad y la búsqueda de significado en la vida moderna.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8427033528', 'Asesinato en el Expreso de Oriente', 1934, 15.99, 18, 2, 'Clásica novela de misterio de Agatha Christie. El detective Hércules Poirot debe resolver un asesinato cometido en un tren de lujo atrapado en la nieve. Una intriga magistral con giros sorprendentes.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8434403689', 'El amor en los tiempos del cólera', 1985, 28.50, 10, 1, 'Novela de Gabriel García Márquez que narra la historia de amor entre Florentino Ariza y Fermina Daza a lo largo de más de 50 años. Una profunda exploración del amor, la paciencia y la redención.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8498386929', 'Harry Potter y la Cámara Secreta', 1998, 19.50, 22, 2, 'Segundo libro de la serie Harry Potter. Harry regresa a Hogwarts para enfrentarse a nuevos misterios y descubrir los secretos ocultos de la escuela. La serie continúa con más intriga y desarrollo de personajes.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8432213779', 'Tokio Blues', 1987, 20.00, 14, 2, 'Novela de Haruki Murakami ambientada en Tokio durante los años 60. Historia de amor y nostalgia con la música de The Beatles como trasfondo. Una reflexión melancólica sobre la juventud, la pérdida y la conexión humana.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8427038790', 'Muerte en el Nilo', 1937, 17.99, 16, 1, 'Otro clásico de misterio de Agatha Christie. Hércules Poirot investiga un asesinato en un crucero por el Nilo. Intriga, pasión y crimen se entrelazan en esta novela cautivadora.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8439706679', 'Memoria de mis putas tristes', 2004, 25.00, 8, 1, 'Novela de Gabriel García Márquez. La historia de un anciano de 90 años que decide vivir una última aventura. Una reflexión íntima sobre la vejez, la soledad, el amor y la vitalidad.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8498388275', 'Harry Potter y el Prisionero de Azkaban', 1999, 20.00, 20, 2, 'Tercer libro de Harry Potter. Se introduce la complejidad de la trama con la fuga de un prisionero de la prisión mágica de Azkaban. Los misterios se profundizan y los personajes evolucionan.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8432218393', 'La tierra de los espíritus', 2010, 26.50, 9, 1, 'Novela contemporánea de misterio y aventura. Una exploración de culturas ancestrales y encuentros sobrenaturales. Combina elementos de realismo mágico con intriga moderna.')
ON CONFLICT (isbn) DO NOTHING;

INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion) VALUES
    ('978-8427044102', 'Testimonio de sangre', 1952, 19.99, 11, 2, 'Novela de misterio clásico con tintes de drama psicológico. Una investigación profunda sobre un crimen que revela secretos oscuros de una familia. Intriga, suspense y giros inesperados.')
ON CONFLICT (isbn) DO NOTHING;

-- ============================================================================
-- DATOS DE PRUEBA - RELACIONES LIBROS-AUTORES
-- ============================================================================

INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 1, 1 FROM libros WHERE titulo = 'Cien años de soledad' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 2, 1 FROM libros WHERE titulo = 'Harry Potter y la Piedra Filosofal' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 3, 1 FROM libros WHERE titulo = 'Kafka en la orilla' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 4, 1 FROM libros WHERE titulo = 'Asesinato en el Expreso de Oriente' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 1, 1 FROM libros WHERE titulo = 'El amor en los tiempos del cólera' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 2, 1 FROM libros WHERE titulo = 'Harry Potter y la Cámara Secreta' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 3, 1 FROM libros WHERE titulo = 'Tokio Blues' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 4, 1 FROM libros WHERE titulo = 'Muerte en el Nilo' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 1, 1 FROM libros WHERE titulo = 'Memoria de mis putas tristes' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 2, 1 FROM libros WHERE titulo = 'Harry Potter y el Prisionero de Azkaban' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 3, 1 FROM libros WHERE titulo = 'La tierra de los espíritus' LIMIT 1;
INSERT INTO libros_autores (id_libro, id_autor, orden_autor) SELECT id_libro, 4, 1 FROM libros WHERE titulo = 'Testimonio de sangre' LIMIT 1;

-- ============================================================================
-- DATOS DE PRUEBA - RELACIONES LIBROS-GÉNEROS
-- ============================================================================

INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 1 FROM libros WHERE titulo = 'Cien años de soledad' UNION ALL SELECT id_libro, 7 FROM libros WHERE titulo = 'Cien años de soledad';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 4 FROM libros WHERE titulo = 'Harry Potter y la Piedra Filosofal' UNION ALL SELECT id_libro, 8 FROM libros WHERE titulo = 'Harry Potter y la Piedra Filosofal';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 2 FROM libros WHERE titulo = 'Kafka en la orilla' UNION ALL SELECT id_libro, 1 FROM libros WHERE titulo = 'Kafka en la orilla';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 3 FROM libros WHERE titulo = 'Asesinato en el Expreso de Oriente';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 5 FROM libros WHERE titulo = 'El amor en los tiempos del cólera' UNION ALL SELECT id_libro, 7 FROM libros WHERE titulo = 'El amor en los tiempos del cólera' UNION ALL SELECT id_libro, 1 FROM libros WHERE titulo = 'El amor en los tiempos del cólera';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 4 FROM libros WHERE titulo = 'Harry Potter y la Cámara Secreta' UNION ALL SELECT id_libro, 8 FROM libros WHERE titulo = 'Harry Potter y la Cámara Secreta' UNION ALL SELECT id_libro, 3 FROM libros WHERE titulo = 'Harry Potter y la Cámara Secreta';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 1 FROM libros WHERE titulo = 'Tokio Blues' UNION ALL SELECT id_libro, 5 FROM libros WHERE titulo = 'Tokio Blues' UNION ALL SELECT id_libro, 7 FROM libros WHERE titulo = 'Tokio Blues';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 3 FROM libros WHERE titulo = 'Muerte en el Nilo' UNION ALL SELECT id_libro, 7 FROM libros WHERE titulo = 'Muerte en el Nilo';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 1 FROM libros WHERE titulo = 'Memoria de mis putas tristes' UNION ALL SELECT id_libro, 5 FROM libros WHERE titulo = 'Memoria de mis putas tristes';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 4 FROM libros WHERE titulo = 'Harry Potter y el Prisionero de Azkaban' UNION ALL SELECT id_libro, 8 FROM libros WHERE titulo = 'Harry Potter y el Prisionero de Azkaban' UNION ALL SELECT id_libro, 3 FROM libros WHERE titulo = 'Harry Potter y el Prisionero de Azkaban';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 2 FROM libros WHERE titulo = 'La tierra de los espíritus' UNION ALL SELECT id_libro, 3 FROM libros WHERE titulo = 'La tierra de los espíritus';
INSERT INTO libros_generos (id_libro, id_genero) SELECT id_libro, 3 FROM libros WHERE titulo = 'Testimonio de sangre' UNION ALL SELECT id_libro, 1 FROM libros WHERE titulo = 'Testimonio de sangre';

-- ============================================================================
-- DATOS DE PRUEBA - RELACIONES LIBROS-CONCEPTOS
-- ============================================================================

INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 1, 'La magía y lo fantástico se entrelazan de forma natural con la realidad cotidiana de Macondo, creando una atmósfera onírica y surreal.' FROM libros WHERE titulo = 'Cien años de soledad';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 9, 'La familia Buendía está marcada por patrones de comportamiento repetitivo y disfunción generacional que se perpetúa a través de los años.' FROM libros WHERE titulo = 'Cien años de soledad';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 2, 'Harry descubre el mundo de la magia y debe aprender a controlar sus poderes mágicos mientras enfrenta fuerzas oscuras.' FROM libros WHERE titulo = 'Harry Potter y la Piedra Filosofal';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 6, 'Hogwarts es una escuela de aprendizaje mágico donde los jóvenes brujos desarrollan habilidades y enfrentan pruebas de madurez.' FROM libros WHERE titulo = 'Harry Potter y la Piedra Filosofal';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 8, 'La novela utiliza elementos surreales y oníricos para explorar la mente del protagonista y su percepción de la realidad.' FROM libros WHERE titulo = 'Kafka en la orilla';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 4, 'Kafka experimenta encuentros con mundos paralelos y realidades alternativas que desafían su comprensión del universo.' FROM libros WHERE titulo = 'Kafka en la orilla';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 3, 'Hércules Poirot, el famoso detective privado, debe utilizar su ingenio y psicología para resolver el crimen en el tren.' FROM libros WHERE titulo = 'Asesinato en el Expreso de Oriente';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 7, 'Un asesinato en el Expreso de Oriente presenta un complejo crimen clásico con múltiples sospechosos y secretos oscuros.' FROM libros WHERE titulo = 'Asesinato en el Expreso de Oriente';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 9, 'Las familias de Fermina y Florentino están marcadas por conflictos emocionales y expectativas sociales que separan a los amantes.' FROM libros WHERE titulo = 'El amor en los tiempos del cólera';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 1, 'La novela presenta elementos de realismo mágico aunque en un contexto más realista, con momentos de profunda introspección emocional.' FROM libros WHERE titulo = 'Tokio Blues';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 5, 'El misterio psicológico detrás del crimen en el Nilo revela motivaciones complejas y secretos familiares enterrados.' FROM libros WHERE titulo = 'Muerte en el Nilo';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 12, 'Encuentros paranormales con espíritus ancestrales que revelan verdades sobre el pasado y el presente de los personajes.' FROM libros WHERE titulo = 'La tierra de los espíritus';
INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) SELECT id_libro, 5, 'El análisis psicológico de los personajes revela misterios emocionales profundos detrás del crimen aparente.' FROM libros WHERE titulo = 'Testimonio de sangre';

-- ============================================================================
-- DATOS DE PRUEBA - IMÁGENES (12 portadas de libros)
-- ============================================================================

INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'cien-anos-portada.jpg', 'images/covers/cien-anos-portada.jpg', 'image/jpeg', 245000, true, 1 FROM libros WHERE titulo = 'Cien años de soledad' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'harry-potter-1-portada.jpg', 'images/covers/harry-potter-1-portada.jpg', 'image/jpeg', 198000, true, 1 FROM libros WHERE titulo = 'Harry Potter y la Piedra Filosofal' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'kafka-orilla-portada.jpg', 'images/covers/kafka-orilla-portada.jpg', 'image/jpeg', 267000, true, 1 FROM libros WHERE titulo = 'Kafka en la orilla' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'asesinato-expreso-portada.jpg', 'images/covers/asesinato-expreso-portada.jpg', 'image/jpeg', 182000, true, 1 FROM libros WHERE titulo = 'Asesinato en el Expreso de Oriente' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'amor-tiempos-colera-portada.jpg', 'images/covers/amor-tiempos-colera-portada.jpg', 'image/jpeg', 256000, true, 1 FROM libros WHERE titulo = 'El amor en los tiempos del cólera' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'harry-potter-2-portada.jpg', 'images/covers/harry-potter-2-portada.jpg', 'image/jpeg', 201000, true, 1 FROM libros WHERE titulo = 'Harry Potter y la Cámara Secreta' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'tokio-blues-portada.jpg', 'images/covers/tokio-blues-portada.jpg', 'image/jpeg', 223000, true, 1 FROM libros WHERE titulo = 'Tokio Blues' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'muerte-nilo-portada.jpg', 'images/covers/muerte-nilo-portada.jpg', 'image/jpeg', 187000, true, 1 FROM libros WHERE titulo = 'Muerte en el Nilo' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'memoria-putas-tristes-portada.jpg', 'images/covers/memoria-putas-tristes-portada.jpg', 'image/jpeg', 234000, true, 1 FROM libros WHERE titulo = 'Memoria de mis putas tristes' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'harry-potter-3-portada.jpg', 'images/covers/harry-potter-3-portada.jpg', 'image/jpeg', 209000, true, 1 FROM libros WHERE titulo = 'Harry Potter y el Prisionero de Azkaban' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'tierra-espiritus-portada.jpg', 'images/covers/tierra-espiritus-portada.jpg', 'image/jpeg', 278000, true, 1 FROM libros WHERE titulo = 'La tierra de los espíritus' LIMIT 1;
INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden) SELECT id_libro, 'testimonio-sangre-portada.jpg', 'images/covers/testimonio-sangre-portada.jpg', 'image/jpeg', 215000, true, 1 FROM libros WHERE titulo = 'Testimonio de sangre' LIMIT 1;