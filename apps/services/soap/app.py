import os
from typing import Any, Dict, List, Tuple

import psycopg
from dotenv import load_dotenv
from flasgger import Swagger
from flask import Flask, jsonify, request
from flask_cors import CORS
from psycopg.rows import dict_row

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
swagger = Swagger(
    app,
    template={
        "swagger": "2.0",
        "info": {
            "title": "Library Catalog API",
            "description": "Microservicio para gestionar libros de una librería en línea.",
            "version": "1.0.0",
        },
        "basePath": "/",
        "schemes": ["http", "https"],
        "consumes": ["application/json"],
        "produces": ["application/json"],
    },
)


def get_db_config() -> Dict[str, Any]:
    return {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "5432")),
        "dbname": os.getenv("DB_NAME", "library_db"),
        "user": os.getenv("DB_USER", "library_user"),
        "password": os.getenv("DB_PASSWORD", "libraryApp"),
    }


def get_connection():
    return psycopg.connect(**get_db_config(), row_factory=dict_row)


def to_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "y", "on"}
    return bool(value)


def fetch_related_data(conn, book_id: str) -> Dict[str, Any]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT a.id_autor, a.nombre, a.apellido
            FROM libros_autores la
            JOIN autores a ON a.id_autor = la.id_autor
            WHERE la.id_libro = %s
            ORDER BY la.orden_autor, a.apellido, a.nombre
            """,
            (book_id,),
        )
        authors = [
            {
                "id_autor": row["id_autor"],
                "nombre": row["nombre"],
                "apellido": row["apellido"],
                "nombre_completo": f"{row['nombre']} {row['apellido']}".strip(),
            }
            for row in cur.fetchall()
        ]

        cur.execute(
            """
            SELECT g.id_genero, g.nombre
            FROM libros_generos lg
            JOIN generos g ON g.id_genero = lg.id_genero
            WHERE lg.id_libro = %s
            ORDER BY g.nombre
            """,
            (book_id,),
        )
        genres = [{"id_genero": row["id_genero"], "nombre": row["nombre"]} for row in cur.fetchall()]

        cur.execute(
            """
            SELECT c.id_concepto, c.termino, lc.definicion
            FROM libros_conceptos lc
            JOIN conceptos c ON c.id_concepto = lc.id_concepto
            WHERE lc.id_libro = %s
            ORDER BY c.termino
            """,
            (book_id,),
        )
        concepts = [
            {
                "id_concepto": row["id_concepto"],
                "termino": row["termino"],
                "definicion": row["definicion"],
            }
            for row in cur.fetchall()
        ]

        cur.execute(
            """
            SELECT id_imagen, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden
            FROM imagenes
            WHERE id_libro = %s
            ORDER BY es_portada DESC, orden ASC, created_at ASC
            """,
            (book_id,),
        )
        images = [
            {
                "id_imagen": row["id_imagen"],
                "nombre_archivo": row["nombre_archivo"],
                "ruta_archivo": row["ruta_archivo"],
                "tipo_mime": row["tipo_mime"],
                "tamaño_bytes": row["tamaño_bytes"],
                "es_portada": to_bool(row["es_portada"]),
                "orden": row["orden"],
            }
            for row in cur.fetchall()
        ]

    return {"authors": authors, "genres": genres, "concepts": concepts, "images": images}


def serialize_book(conn, book_row: Dict[str, Any]) -> Dict[str, Any]:
    related = fetch_related_data(conn, str(book_row["id_libro"]))
    return {
        "id_libro": str(book_row["id_libro"]),
        "isbn": book_row["isbn"],
        "titulo": book_row["titulo"],
        "year_publicacion": book_row["year_publicacion"],
        "precio": float(book_row["precio"]),
        "stock": int(book_row["stock"]),
        "id_formato": book_row["id_formato"],
        "formato": book_row["formato"],
        "descripcion": book_row["descripcion"],
        "autores": related["authors"],
        "generos": related["genres"],
        "conceptos": related["concepts"],
        "imagenes": related["images"],
    }


def fetch_books(conn, filters: List[Tuple[str, str, List[Any]]] | None = None):
    sql = """
        SELECT l.id_libro, l.isbn, l.titulo, l.year_publicacion, l.precio, l.stock, l.id_formato,
               l.descripcion, f.nombre AS formato
        FROM libros l
        LEFT JOIN formatos f ON f.id_formato = l.id_formato
    """
    params: List[Any] = []
    clauses: List[str] = []

    if filters:
        for field, operator, values in filters:
            if field == "author":
                clauses.append(
                    "EXISTS (SELECT 1 FROM libros_autores la JOIN autores a ON a.id_autor = la.id_autor WHERE la.id_libro = l.id_libro AND a.nombre ILIKE %s)"
                )
                params.append(f"%{values[0]}%")
            elif field == "genre":
                clauses.append(
                    "EXISTS (SELECT 1 FROM libros_generos lg JOIN generos g ON g.id_genero = lg.id_genero WHERE lg.id_libro = l.id_libro AND g.nombre ILIKE %s)"
                )
                params.append(f"%{values[0]}%")
            elif field == "concept":
                clauses.append(
                    "EXISTS (SELECT 1 FROM libros_conceptos lc JOIN conceptos c ON c.id_concepto = lc.id_concepto WHERE lc.id_libro = l.id_libro AND c.termino ILIKE %s)"
                )
                params.append(f"%{values[0]}%")
            else:
                if operator == "like":
                    clauses.append(f"l.{field} ILIKE %s")
                    params.append(f"%{values[0]}%")
                elif operator == "eq":
                    clauses.append(f"l.{field} = %s")
                    params.append(values[0])
                elif operator == "in":
                    placeholders = ", ".join(["%s"] * len(values))
                    clauses.append(f"l.{field} IN ({placeholders})")
                    params.extend(values)

    if clauses:
        sql += " WHERE " + " AND ".join(clauses)

    sql += " ORDER BY l.titulo ASC"

    with conn.cursor() as cur:
        cur.execute(sql, params)
        rows = cur.fetchall()

    return [serialize_book(conn, row) for row in rows]


def normalize_author(author_value: Any) -> Tuple[str, str]:
    if isinstance(author_value, dict):
        nombre = (author_value.get("nombre") or author_value.get("first_name") or "").strip()
        apellido = (author_value.get("apellido") or author_value.get("last_name") or "").strip()
        if not apellido and " " in nombre:
            nombre, apellido = nombre.rsplit(" ", 1)
        return nombre, apellido
    if isinstance(author_value, str):
        text = author_value.strip()
        if " " in text:
            nombre, apellido = text.rsplit(" ", 1)
            return nombre.strip(), apellido.strip()
        return text.strip(), ""
    raise ValueError("Author format invalid")


def ensure_format(conn, formato: Any) -> int:
    if formato is None or str(formato).strip() == "":
        raise ValueError("The format is required")

    if isinstance(formato, int):
        with conn.cursor() as cur:
            cur.execute("SELECT id_formato FROM formatos WHERE id_formato = %s", (formato,))
            row = cur.fetchone()
            if not row:
                raise ValueError("Format not found")
            return row["id_formato"]

    nombre = str(formato).strip()
    with conn.cursor() as cur:
        cur.execute("SELECT id_formato FROM formatos WHERE nombre = %s", (nombre,))
        row = cur.fetchone()
        if row:
            return row["id_formato"]
        cur.execute(
            "INSERT INTO formatos (nombre, descripcion) VALUES (%s, %s) RETURNING id_formato",
            (nombre, f"Formato generado: {nombre}"),
        )
        row = cur.fetchone()
        return row["id_formato"]


def ensure_author(conn, author_value: Any) -> int:
    nombre, apellido = normalize_author(author_value)
    with conn.cursor() as cur:
        if nombre and apellido:
            cur.execute(
                "SELECT id_autor FROM autores WHERE nombre = %s AND apellido = %s",
                (nombre, apellido),
            )
            row = cur.fetchone()
            if row:
                return row["id_autor"]
            cur.execute(
                "INSERT INTO autores (nombre, apellido) VALUES (%s, %s) RETURNING id_autor",
                (nombre, apellido),
            )
            row = cur.fetchone()
            return row["id_autor"]

        cur.execute("SELECT id_autor FROM autores WHERE nombre = %s LIMIT 1", (nombre,))
        row = cur.fetchone()
        if row:
            return row["id_autor"]

        cur.execute(
            "INSERT INTO autores (nombre, apellido) VALUES (%s, %s) RETURNING id_autor",
            (nombre, ""),
        )
        row = cur.fetchone()
        return row["id_autor"]


def ensure_genre(conn, genre_value: Any) -> int:
    nombre = str(genre_value).strip()
    with conn.cursor() as cur:
        cur.execute("SELECT id_genero FROM generos WHERE nombre = %s", (nombre,))
        row = cur.fetchone()
        if row:
            return row["id_genero"]
        cur.execute(
            "INSERT INTO generos (nombre, descripcion) VALUES (%s, %s) RETURNING id_genero",
            (nombre, f"Género generado: {nombre}"),
        )
        row = cur.fetchone()
        return row["id_genero"]


def ensure_concept(conn, term: Any, definition: str = "") -> int:
    termino = str(term).strip()
    with conn.cursor() as cur:
        cur.execute("SELECT id_concepto FROM conceptos WHERE termino = %s", (termino,))
        row = cur.fetchone()
        if row:
            return row["id_concepto"]
        cur.execute("INSERT INTO conceptos (termino) VALUES (%s) RETURNING id_concepto", (termino,))
        row = cur.fetchone()
        return row["id_concepto"]


def assign_relations(
    conn,
    book_id: str,
    authors: List[Any] | None = None,
    genres: List[Any] | None = None,
    concepts: List[Dict[str, Any]] | None = None,
    images: List[Dict[str, Any]] | None = None,
):
    with conn.cursor() as cur:
        if authors:
            for idx, author_value in enumerate(authors, start=1):
                author_id = ensure_author(conn, author_value)
                cur.execute(
                    "INSERT INTO libros_autores (id_libro, id_autor, orden_autor) VALUES (%s, %s, %s) ON CONFLICT (id_libro, id_autor) DO NOTHING",
                    (book_id, author_id, idx),
                )

        if genres:
            for genre_value in genres:
                genre_id = ensure_genre(conn, genre_value)
                cur.execute(
                    "INSERT INTO libros_generos (id_libro, id_genero) VALUES (%s, %s) ON CONFLICT (id_libro, id_genero) DO NOTHING",
                    (book_id, genre_id),
                )

        if concepts:
            for concept in concepts:
                term = concept.get("term") or concept.get("termino") or concept.get("name")
                definition = concept.get("definition") or concept.get("definicion") or ""
                if not term:
                    continue
                concept_id = ensure_concept(conn, term, definition)
                cur.execute(
                    "INSERT INTO libros_conceptos (id_libro, id_concepto, definicion) VALUES (%s, %s, %s) ON CONFLICT (id_libro, id_concepto) DO UPDATE SET definicion = EXCLUDED.definicion",
                    (book_id, concept_id, definition),
                )

        if images:
            for idx, image in enumerate(images, start=1):
                file_name = image.get("nombre_archivo") or image.get("file_name") or f"cover_{idx}.jpg"
                path = image.get("ruta_archivo") or image.get("path") or image.get("url") or ""
                mime = image.get("tipo_mime") or image.get("mime_type") or "image/jpeg"
                size = image.get("tamaño_bytes") or image.get("size_bytes") or 0
                is_cover = to_bool(image.get("es_portada") or image.get("is_portada") or (idx == 1))
                cur.execute(
                    """
                    INSERT INTO imagenes (id_libro, nombre_archivo, ruta_archivo, tipo_mime, tamaño_bytes, es_portada, orden)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (id_libro, es_portada) WHERE es_portada = true DO UPDATE SET
                        nombre_archivo = EXCLUDED.nombre_archivo,
                        ruta_archivo = EXCLUDED.ruta_archivo,
                        tipo_mime = EXCLUDED.tipo_mime,
                        tamaño_bytes = EXCLUDED.tamaño_bytes,
                        orden = EXCLUDED.orden
                    """,
                    (book_id, file_name, path, mime, size, is_cover, idx),
                )


def parse_book_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    if not payload:
        raise ValueError("Request body is required")

    isbn = payload.get("isbn") or payload.get("ISBN")
    titulo = payload.get("titulo") or payload.get("title")
    year_publicacion = payload.get("year_publicacion") or payload.get("publication_year") or payload.get("year")
    precio = payload.get("precio") or payload.get("price")
    stock = payload.get("stock")
    descripcion = payload.get("descripcion") or payload.get("description")
    formato = payload.get("id_formato") or payload.get("formato") or payload.get("format")

    if not isbn or not titulo or precio is None or stock is None:
        raise ValueError("isbn, titulo, precio and stock are required")

    return {
        "isbn": str(isbn).strip(),
        "titulo": str(titulo).strip(),
        "year_publicacion": int(year_publicacion) if year_publicacion not in (None, "") else None,
        "precio": float(precio),
        "stock": int(stock),
        "descripcion": descripcion,
        "formato": formato,
        "authors": payload.get("authors") or payload.get("autores") or [],
        "genres": payload.get("genres") or payload.get("generos") or [],
        "concepts": payload.get("concepts") or payload.get("conceptos") or [],
        "images": payload.get("images") or payload.get("imagenes") or [
            {"nombre_archivo": "cover.jpg", "ruta_archivo": "images/covers/default.jpg", "es_portada": True}
        ],
    }


@app.route("/health", methods=["GET"])
def health():
        """
        Health check
        ---
        tags:
            - System
        responses:
            200:
                description: Service health status
                schema:
                    type: object
                    properties:
                        status:
                            type: string
                        service:
                            type: string
                        database:
                            type: string
        """
    return jsonify({"status": "ok", "service": "library_service", "database": get_db_config()["dbname"]})


@app.route("/books", methods=["GET"])
def list_books():
        """
        List books
        ---
        tags:
            - Books
        responses:
            200:
                description: List of books
                schema:
                    type: object
                    properties:
                        count:
                            type: integer
                        results:
                            type: array
                            items:
                                type: object
        """
    conn = None
    try:
        conn = get_connection()
        books = fetch_books(conn)
        return jsonify({"count": len(books), "results": books}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
    finally:
        if conn is not None:
            conn.close()


@app.route("/books/search", methods=["GET"])
def search_books():
        """
        Search books
        ---
        tags:
            - Books
        parameters:
            - in: query
                name: titulo
                type: string
                required: false
            - in: query
                name: isbn
                type: string
                required: false
            - in: query
                name: author
                type: string
                required: false
            - in: query
                name: genre
                type: string
                required: false
            - in: query
                name: concept
                type: string
                required: false
        responses:
            200:
                description: Books matching the filters
        """
    conn = None
    try:
        conn = get_connection()
        filters: List[Tuple[str, str, List[Any]]] = []
        allowed = {"isbn", "titulo", "year_publicacion", "precio", "stock", "author", "genre", "concept"}

        for key in allowed:
            if key in request.args:
                value = request.args.get(key)
                if value is not None and value != "":
                    if key in {"author", "genre", "concept"}:
                        filters.append((key, "like", [value]))
                    else:
                        filters.append((key, "eq", [value]))

        if "attribute" in request.args and "value" in request.args:
            attribute = request.args.get("attribute")
            value = request.args.get("value")
            if attribute == "titulo":
                filters.append(("titulo", "like", [value]))
            elif attribute == "isbn":
                filters.append(("isbn", "eq", [value]))
            elif attribute == "author":
                filters.append(("author", "like", [value]))
            elif attribute == "genre":
                filters.append(("genre", "like", [value]))
            elif attribute == "concept":
                filters.append(("concept", "like", [value]))

        books = fetch_books(conn, filters)
        return jsonify({"count": len(books), "results": books}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
    finally:
        if conn is not None:
            conn.close()


@app.route("/books/<book_id>", methods=["GET"])
def get_book(book_id: str):
        """
        Get book by id
        ---
        tags:
            - Books
        parameters:
            - in: path
                name: book_id
                type: integer
                required: true
        responses:
            200:
                description: Book found
            404:
                description: Book not found
        """
    conn = None
    try:
        conn = get_connection()
        books = fetch_books(conn, [("id_libro", "eq", [book_id])])
        if not books:
            return jsonify({"error": "Book not found"}), 404
        return jsonify(books[0]), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
    finally:
        if conn is not None:
            conn.close()


@app.route("/books", methods=["POST"])
def create_book():
        """
        Create book
        ---
        tags:
            - Books
        parameters:
            - in: body
                name: body
                required: true
                schema:
                    type: object
                    required:
                        - isbn
                        - titulo
                        - precio
                        - stock
                    properties:
                        isbn:
                            type: string
                        titulo:
                            type: string
                        descripcion:
                            type: string
                        precio:
                            type: number
                        stock:
                            type: integer
                        formato:
                            type: string
                        authors:
                            type: array
                            items:
                                type: object
        responses:
            201:
                description: Book created successfully
            500:
                description: Error creating book
        """
    conn = None
    payload = request.get_json(silent=True)
    try:
        data = parse_book_payload(payload)
        conn = get_connection()
        with conn.transaction():
            with conn.cursor() as cur:
                formato_id = ensure_format(conn, data["formato"])
                cur.execute(
                    """
                    INSERT INTO libros (isbn, titulo, year_publicacion, precio, stock, id_formato, descripcion)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_libro
                    """,
                    (
                        data["isbn"],
                        data["titulo"],
                        data["year_publicacion"],
                        data["precio"],
                        data["stock"],
                        formato_id,
                        data["descripcion"],
                    ),
                )
                book_id = cur.fetchone()["id_libro"]

            assign_relations(
                conn,
                str(book_id),
                authors=data.get("authors"),
                genres=data.get("genres"),
                concepts=data.get("concepts"),
                images=data.get("images"),
            )

        result = fetch_books(conn, [("id_libro", "eq", [str(book_id)])])
        return jsonify({"message": "Book created successfully", "book": result[0]}), 201
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
    finally:
        if conn is not None:
            conn.close()


@app.route("/books/<book_id>", methods=["PUT"])
def update_book(book_id: str):
        """
        Update book
        ---
        tags:
            - Books
        parameters:
            - in: path
                name: book_id
                type: integer
                required: true
            - in: body
                name: body
                required: true
                schema:
                    type: object
        responses:
            200:
                description: Book updated successfully
            500:
                description: Errors during update
        """
    conn = None
    payload = request.get_json(silent=True)
    try:
        data = parse_book_payload(payload)
        conn = get_connection()
        with conn.transaction():
            with conn.cursor() as cur:
                formato_id = ensure_format(conn, data["formato"])
                cur.execute(
                    """
                    UPDATE libros
                    SET isbn = %s,
                        titulo = %s,
                        year_publicacion = %s,
                        precio = %s,
                        stock = %s,
                        id_formato = %s,
                        descripcion = %s
                    WHERE id_libro = %s
                    RETURNING id_libro
                    """,
                    (
                        data["isbn"],
                        data["titulo"],
                        data["year_publicacion"],
                        data["precio"],
                        data["stock"],
                        formato_id,
                        data["descripcion"],
                        book_id,
                    ),
                )
                if cur.rowcount == 0:
                    raise ValueError("Book not found")

            with conn.cursor() as cur:
                cur.execute("DELETE FROM libros_autores WHERE id_libro = %s", (book_id,))
                cur.execute("DELETE FROM libros_generos WHERE id_libro = %s", (book_id,))
                cur.execute("DELETE FROM libros_conceptos WHERE id_libro = %s", (book_id,))
                cur.execute("DELETE FROM imagenes WHERE id_libro = %s", (book_id,))

            assign_relations(
                conn,
                book_id,
                authors=data.get("authors"),
                genres=data.get("genres"),
                concepts=data.get("concepts"),
                images=data.get("images"),
            )

        result = fetch_books(conn, [("id_libro", "eq", [book_id])])
        return jsonify({"message": "Book updated successfully", "book": result[0]}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
    finally:
        if conn is not None:
            conn.close()


@app.route("/books/<book_id>", methods=["DELETE"])
def delete_book(book_id: str):
        """
        Delete book
        ---
        tags:
            - Books
        parameters:
            - in: path
                name: book_id
                type: integer
                required: true
        responses:
            200:
                description: Book deleted successfully
            404:
                description: Book not found
        """
    conn = None
    try:
        conn = get_connection()
        with conn.transaction():
            with conn.cursor() as cur:
                cur.execute("DELETE FROM libros WHERE id_libro = %s", (book_id,))
                if cur.rowcount == 0:
                    return jsonify({"error": "Book not found"}), 404
        return jsonify({"message": "Book deleted successfully", "id_libro": book_id}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
    finally:
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=False)
