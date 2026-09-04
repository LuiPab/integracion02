1.- Escribe un microservicio en Flask (no usar blueprints) con una conexion a la base de datos de Postgres para generar endpoint y realizar las operaciones CRUD de libros. Depositalos en /apps/services/soap/ 

2.- Usa como referencia el esquema de base de datos /library/db/schema.sql y el diseño del XML definido en /apps/services/soap/library.xsl

3.- El microservicio debe de mostrar todos los libros, un libro, buscar por atributos, modificar un libro, borrar un libro y actualizar un libro.

4.- Toma en consideracion el problema CORS ya que este servicio sera accedido mediante clientes fuera de dominio

5.- Considera los siguientes datos de Postgres: db: library_db, usuario: library_user y password: libraryApp. Usa las variables de entorno .env.example para no exponer las credenciales del servicio.