"""Generate the XML catalog from the PostgreSQL library database."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import xml.etree.ElementTree as ET
from xml.dom import minidom

import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row

ROOT_DIR = Path(__file__).resolve().parents[1]
SERVICE_DIR = ROOT_DIR / "apps" / "services" / "soap"
DEFAULT_OUTPUT = SERVICE_DIR / "library.xml"


def get_connection():
    load_dotenv(SERVICE_DIR / ".env")
    return psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "library_db"),
        user=os.getenv("DB_USER", "library_user"),
        password=os.getenv("DB_PASSWORD", "libraryApp"),
        row_factory=dict_row,
    )


def add_text(parent: ET.Element, tag: str, value) -> ET.Element:
    element = ET.SubElement(parent, tag)
    if value is not None:
        element.text = str(value)
    return element


def fetch_books(connection):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT l.id_libro, l.isbn, l.titulo, l.year_publicacion,
                   l.precio, l.stock, f.nombre AS formato, l.descripcion
            FROM libros l
            JOIN formatos f ON f.id_formato = l.id_formato
            ORDER BY l.titulo
            """
        )
        books = cursor.fetchall()

        for book in books:
            book_id = book["id_libro"]
            cursor.execute(
                """
                SELECT CONCAT(a.nombre, ' ', a.apellido) AS nombre
                FROM libros_autores la
                JOIN autores a ON a.id_autor = la.id_autor
                WHERE la.id_libro = %s
                ORDER BY la.orden_autor NULLS LAST, a.apellido, a.nombre
                """,
                (book_id,),
            )
            book["autores"] = cursor.fetchall()

            cursor.execute(
                """
                SELECT g.nombre
                FROM libros_generos lg
                JOIN generos g ON g.id_genero = lg.id_genero
                WHERE lg.id_libro = %s
                ORDER BY g.nombre
                """,
                (book_id,),
            )
            book["generos"] = cursor.fetchall()

            cursor.execute(
                """
                SELECT c.termino, lc.definicion
                FROM libros_conceptos lc
                JOIN conceptos c ON c.id_concepto = lc.id_concepto
                WHERE lc.id_libro = %s
                ORDER BY c.termino
                """,
                (book_id,),
            )
            book["conceptos"] = cursor.fetchall()

            cursor.execute(
                """
                SELECT ruta_archivo
                FROM imagenes
                WHERE id_libro = %s
                ORDER BY es_portada DESC, orden ASC NULLS LAST, created_at
                """,
                (book_id,),
            )
            book["imagenes"] = cursor.fetchall()

    return books


def build_xml(books) -> ET.ElementTree:
    root = ET.Element("library")
    catalog = ET.SubElement(root, "catalog")
    books_element = ET.SubElement(catalog, "books")

    for book in books:
        book_element = ET.SubElement(books_element, "book")
        add_text(book_element, "isbn", book["isbn"])
        add_text(book_element, "title", book["titulo"])

        authors = book["autores"]
        author_text = ", ".join(author["nombre"].strip() for author in authors)
        add_text(book_element, "author", author_text)
        add_text(book_element, "publicationYear", book["year_publicacion"])

        genres_element = ET.SubElement(book_element, "genres")
        for genre in book["generos"]:
            add_text(genres_element, "genre", genre["nombre"])

        add_text(book_element, "price", book["precio"])
        add_text(book_element, "stock", book["stock"])
        add_text(book_element, "format", book["formato"])
        add_text(book_element, "description", book["descripcion"])

        images_element = ET.SubElement(book_element, "images")
        for image in book["imagenes"]:
            image_element = ET.SubElement(images_element, "image")
            add_text(image_element, "path", image["ruta_archivo"])

        concepts_element = ET.SubElement(book_element, "concepts")
        for concept in book["conceptos"]:
            concept_element = ET.SubElement(concepts_element, "concept")
            add_text(concept_element, "term", concept["termino"])
            add_text(concept_element, "definition", concept["definicion"])

    return ET.ElementTree(root)


def write_xml(tree: ET.ElementTree, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    raw_xml = ET.tostring(tree.getroot(), encoding="utf-8")
    pretty_xml = minidom.parseString(raw_xml).toprettyxml(indent="  ", encoding="UTF-8")
    stylesheet = b'<?xml-stylesheet href="library.xsl" type="text/xsl"?>\n'
    output_path.write_bytes(pretty_xml.replace(b'?>\n', b'?>\n' + stylesheet, 1))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"XML output path (default: {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()

    with get_connection() as connection:
        books = fetch_books(connection)
    write_xml(build_xml(books), args.output)
    print(f"Generated {len(books)} books in {args.output}")


if __name__ == "__main__":
    main()
