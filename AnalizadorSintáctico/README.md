# ¿Cómo compilar desde Linux?

1. Se requiere tener una versión de gcc y flex
2. En terminal escrbir
    $ flex "archivo.l" 
3. Comilar con gcc el archivo "lex.yy.c" generado
    $ gcc lex.yy.c -lfl
4. Ejecutar "a.out" y pasarle como argumento el archivo .c, .txt, o
    que contenga las pruebas a realizar. Ejemplo:
    $ ./a.out pruebas.txt
5. Se generará un archivo "catalogo.txt" con los catálogos y se mostrará
    en terminal posibles errores, tablas, cadena, etc.

