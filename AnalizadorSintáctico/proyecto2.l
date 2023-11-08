%{
/********************************************************************
************************* ANALIZADOR LÉXICO *************************
*********************************************************************
 - Autores:
 	- Morales Ortega Carlos
 	- Vélez Grande Cinthya

 - Fecha de elaboración: 2/10/2023

 - Descripción: Este programa es un analizador léxico escrito en flex que 
 	reconoce los componentes léxicos pertenecientes a las siguientes clases:

 	Clase 	Descripción
 		0 	Operadores aritméticos + - / * %
		1 	Operadores lógicos (ver catalogo.txt).
		2 	Operadores relacionales (ver catalogo.txt).
		3 	Constantes numéricas enteras. Sólo en base 10. Si está con signo, encerrados entre ( ).
		4 	Palabras reservadas (ver catalogo.txt).
		5 	Identificadores. Inician con _ y le sigue una letra minúscula o mayúscula, después pueden contener letras
			minúsculas o mayúsculas, dígitos y _
		6 	Símbolos especiales ( ) { } ; , [ ] : #
		7 	Operadores de asignación (ver catalogo.txt).
		8 	Constantes cadenas. Encerradas entre comillas (“) cualquier secuencia de caracteres incluye salto de línea.
		9 	Operadores sobre cadenas (ver catalogo.txt).

********************************************************************/
#include <stdio.h>
#include <string.h>

/******************** DEFINICIÓN DE ESTRUCTURAS ********************/

/*
------------Estructuras diseñadas para la implementación de palabras reservadas y operadores------------
 - struct reservada: representa una palabra reservada a la que se le asigna un valor como identificador y la palabra que está representando.
 - struct operador: representa un operador al cual se le asigna un valor, que será como su identificador, y el símbolo que lo representa.
--------------------------------------------------------------------------------------------------------
*/

struct reservada{ 
	short valor;
	char palabra[10];
	char atomo[1];
};

struct operador{
	short valor;
	char simbolo[7];
	char atomo[1];
};


/*
------------Estructuras diseñadas para la implementación de la tabla de literales------------
 - struct cadena: representa una cadena dentro de la tabla de literales, consta de una posición y el dato que contiene es la cadena en sí.
 - struct nodoCadena: representa un nodo que formará parte de una lista ligada, contiene un elemento de tipo cadena como valor y se conecta con otro nodo del mismo tipo mediante un apuntador, será su nodo siguiente dentro de la lista.
 - struct listaCadenas: representa una lista conformada por nodos que contienen cadenas almacenadas. Contiene la referencia al nodo que es la cabeza de la lista y un entero que indica el tamaño de la lista.
---------------------------------------------------------------------------------------------
*/

struct cadena{
	int posicion;
	char *dato;
};

struct nodoCadena{
    struct cadena valor;
    struct nodoCadena* next;
};

struct listaCadenas{
	struct nodoCadena* head;
	int tamanio;
};


/*
------------Estructuras diseñadas para la implementación de la tabla de símbolos------------
 - struct identificador: representa un identificador dentro de la tabla de símbolos, consta de una posición, el nombre del identificador y el tipo que almacenará.
 - struct nodoIdentificador: representa un nodo que formará parte de una lista ligada, contiene un elemento de tipo simboloIdentificador como valor y se conecta con otro nodo del mismo tipo mediante un apuntador, el cual será su nodo siguiente dentro de la lista.
 - struct listaIdentificadores: representa una lista conformada por nodos que contienen identificadores como valor. Contiene la referencia al nodo que es la cabeza de la lista y un entero que indica el tamaño de la lista.
--------------------------------------------------------------------------------------------
*/

struct identificador{
	int posicion;
	char nombre[100];
	short tipo;
};

struct nodoIdentificador{
    struct identificador valor;
    struct nodoIdentificador* next;
};

struct listaIdentificadores{
	struct nodoIdentificador* head;
	int tamanio;
};


/*
------------Estructuras diseñadas para la implementación de la tabla de tokens------------
 - struct token: representa un token, contiene una clase y un valor, así como la referencia a otro token, para implementarlo como un nodo dentro de una lista.
 - struct ListaToken: representa una lista de tokens, contiene la referencia a un token que será el primero de la lista.
------------------------------------------------------------------------------------------
*/

struct token{
	short clase;
	int valor;
	struct token* next;
};

struct ListaToken{
	struct token* head;
};


/******************** DECLARACIÓN DE FUNCIONES ********************/

/*-------Funciones para la creación de catálogos-------*/

void crearCatalogos(FILE*);
void creaReservadas(struct reservada[], FILE*);
int agregarPalabra(struct reservada, FILE*);
void creaOpSobreCadenas(struct operador[], FILE*);
void creaOpLogicos(struct operador[], FILE*);
void creaOpRelacionales(struct operador[], FILE*);
void creaOpAsignacion(struct operador[], FILE*);
int agregarOperador(struct operador, FILE*);


/*-------Funciones para las búsquedas en catálogos-------*/

int buscaReservadas(struct reservada[], char*);
int buscaOperadores(struct operador[], int, char*);


/*-------Funciones para implementar la tabla de literales-------*/

struct cadena crearCadena(int, char*, int);
struct listaCadenas crearListaCadenas();
int addCadenaALista(struct listaCadenas*, char*,int);
void imprimirListaCadenas(struct listaCadenas);


/*-------Funciones para implementar la tabla de símbolos-------*/

struct identificador crearIdentificador(char*, int);
struct listaIdentificadores crearListaIdentificadores();
int addIdentificALista(struct listaIdentificadores*, char*);
int buscarIdentificador(struct listaIdentificadores, char*);
void imprimirListaIdent(struct listaIdentificadores);


/*-------Funciones para implementar la tabla de tokens-------*/

struct ListaToken crearListaToken();
void addFinalListaToken(struct ListaToken*, short, int);
void imprimirListaToken(struct ListaToken);

/*-------Función para obtener el valor ASCII de un carácter-------*/

int obtenerAscii(char*);

/*-------Función para convertir en entero una secuencia de carácteres-------*/
int convierteInt(char*);

/*-------Función para crear cadena---------------*/
void addCadenaFinal(char);

/********** DECLARACIÓN DE VARIABLES, ARREGLOS, ESTRUCTURAS Y APUNTADORES GLOBALES **********/

FILE *yyin;				// Apuntador al archivo de entrada para el analizador léxico.
char *cadenaFinal;		//Apuntador a una cadena que representa la cadena de átomos
int valorToken = 0;		// Variable auxiliar para guardar los valores de los tokens.
int numChar = 0;		// Variable auxiliar para almacenar el número de caracteres de una cadena.
unsigned char charToken;// Variable auxiliar para almacenar el valor en ascii
int N=-1;				//Variable para contar el número de caracteres en la cadena
int size=0;				//Variable auxiliar para llevar conteo de índices de la cadena
int contadorErrores=0;	//Variable que lleva el conteo de errores sintácticos
int indice=-1;			//Variable auxiliar para desplazar un índice sobre la cadena de átomos
char c;					//Variable auxiliar para almacenar el átomo leído

//Creación de los arreglos de estructuras correspondientes a los catálogos.

struct  reservada catalogoPalReservadas[11];	// Catálogo de palabras reservadas
struct  operador catalogoOpRelacionales[6];		// Catálogo de operadores relacionales
struct  operador catalogoOpLogicos[3];			// Catálogo de operadores lógicos
struct  operador catalogoOpCadenas[2];			// Catálogo de operadores sobre cadenas
struct  operador catalogoOpAsignacion[6];		// Catálogo de operadores de asignación


//Creación de las estructuras correspondientes a la tabla de símbolos, la tabla de literales y la lista de tokens.

struct listaIdentificadores tablaDeSimbolos;	//Tabla de símbolos (para almacenar identificadores)
struct listaCadenas tablaDeLiterales;			//Tabla de literales (para almacenar cadenas)
struct ListaToken tablaToken;					//Tabla de tokens


%}

dig		[0-9]
espacios [\t\n ]
arit	(\+|-|\/|\*|%)
log		(&&|\|\||!)
rel		(>|<|=|!)=|>|<
cteNum	({dig})+|(\((\+|-)({dig})+\)) 
cad		(&|like)
palRes	inteiro|enquanto|quebrar|retorno|para|trocar|assinado|se|fazer|caso|flutuador
mayus	[A-Z]
minus	[a-z]
ident	_({mayus}|{minus})(_|{mayus}|{minus}|{dig})*
esp		(\(|\)|;|\{|\}|\[|\]|:|#|,)
asig	(\+|-|\*|\/|%)?=
tds		\"([^"])*\"

%%
{arit}		{
				valorToken= obtenerAscii(yytext);
				addCadenaFinal(*yytext);
				addFinalListaToken(&tablaToken, 0, valorToken);
			}
{log}		{
				valorToken= buscaOperadores(catalogoOpLogicos,(int)(sizeof(catalogoOpLogicos)/sizeof(struct operador)),yytext);
				addCadenaFinal(*catalogoOpLogicos[valorToken].atomo);
				addFinalListaToken(&tablaToken, 1, valorToken); 
			}
{rel}		{
				valorToken= buscaOperadores(catalogoOpRelacionales,(int)(sizeof(catalogoOpRelacionales)/sizeof(struct operador)),yytext);
				addCadenaFinal(*catalogoOpRelacionales[valorToken].atomo);
				addFinalListaToken(&tablaToken, 2, valorToken);
			}
{cteNum}	{
				valorToken=convierteInt(yytext);
				addCadenaFinal('n');
				addFinalListaToken(&tablaToken, 3, valorToken);
			}
{palRes}	{
				valorToken= buscaReservadas(catalogoPalReservadas,yytext);
				addCadenaFinal(*catalogoPalReservadas[valorToken].atomo);				
				addFinalListaToken(&tablaToken, 4, valorToken);
			}		
{cad}		{
				valorToken= buscaOperadores(catalogoOpCadenas,(int)(sizeof(catalogoOpCadenas)/sizeof(struct operador)),yytext);
				addCadenaFinal(*catalogoOpCadenas[valorToken].atomo);
				addFinalListaToken(&tablaToken, 9, valorToken);
			}
{ident}		{
				valorToken= addIdentificALista(&tablaDeSimbolos,yytext);
				addCadenaFinal('a');
				addFinalListaToken(&tablaToken, 5, valorToken);
			}
{esp}		{
				valorToken= obtenerAscii(yytext);
				addCadenaFinal(*yytext);
				addFinalListaToken(&tablaToken, 6, valorToken);
			}
{asig}		{
				valorToken= buscaOperadores(catalogoOpAsignacion,(int)(sizeof(catalogoOpAsignacion)/sizeof(struct operador)),yytext);
				addCadenaFinal(*catalogoOpAsignacion[valorToken].atomo);
				addFinalListaToken(&tablaToken, 7, valorToken);
			}
{tds}		{
				numChar=strlen(yytext);
				valorToken= addCadenaALista(&tablaDeLiterales,yytext,numChar);
				addCadenaFinal('v');
				addFinalListaToken(&tablaToken, 8, valorToken);
			}
{espacios}	{}
.			{printf("ERROR: %s no esta definido\n",yytext);}
%%


/*
----------Métodos para la creación de los catálogos----------
 - crearCatalogos: función que llama a todas las funciones correspondientes para la creación de todos los catálogos. Recibe el apuntador al archivo en el que se imprimirá el contenido de los catálogos.
 - creaReservadas: crea el catálogo de las palabras reservadas. Recibe la estructura en donde almacenará las palabras y el archivo al cual agregarlas.
 - agregarPalabra: agrega una palabra, que se pasa como parámetro, al archivo, igual enviado como parámetro, con un cierto formato de impresión.
 - creaOpSobreCadenas: crea el catálogo de los operadores sobre cadenas. Recibe la estructura en donde almacenará los símbolos y el archivo al cual agregarlos.
 - creaOpLogicos: crea el catálogo de los operadores lógicos.
 - creaOpRelacionales: crea el catálogo de los operadores relacionales.
 - creaOpAsignacion: crea el catálogo de los operadores de asignación.
 - agregarOperador: agrega un operador, que se pasa como parámetro, al archivo, igual enviado como parámetro, con un cierto formato de impresión.
--------------------------------------------------------------
*/

void crearCatalogos(FILE *fcatalogo){
	creaReservadas(catalogoPalReservadas,fcatalogo);
	creaOpRelacionales(catalogoOpRelacionales,fcatalogo);
	creaOpLogicos(catalogoOpLogicos,fcatalogo);
	creaOpSobreCadenas(catalogoOpCadenas,fcatalogo);
	creaOpAsignacion(catalogoOpAsignacion,fcatalogo);
}


void creaReservadas(struct reservada palabras[],FILE *archivo){	
	char listaNombres[][11]={"assinado","caso","enquanto","fazer",
							 "flutuador","inteiro","para","quebrar",
							 "retorno","se","trocar"};
	char atomos[][11]={"g","c","q","z",
							 "f","i","p","u",
							 "t","s","b"};
	fputs("-----Catalogo de Palabras Reservadas-----\n\tValor\tPalabra\n",archivo);

	for (int i=0; i<11; i++){
		palabras[i].valor=i;
		strcpy(palabras[i].palabra,listaNombres[i]);
		strcpy(palabras[i].atomo,atomos[i]);
		agregarPalabra(palabras[i],archivo);
	}
	fputs("\n",archivo);
}


int agregarPalabra(struct reservada pal,FILE *archivo){
	char snum[5];
	sprintf(snum, "%d", pal.valor);
	fputs("\t",archivo);
	fputs(strcat(snum,"\t"),archivo);
	fputs(pal.palabra,archivo);
	fputs("\n",archivo);
	return 1;
}


void creaOpSobreCadenas(struct operador opsSobreCadena[],FILE *archivo){
	
	fputs("\n-----Catalogo de Operadores sobre Cadenas-----\n\tValor\tSimbolo\n",archivo);

	opsSobreCadena[0].valor=0;
	strcpy(opsSobreCadena[0].simbolo,"&");
	strcpy(opsSobreCadena[0].atomo,"&");
	agregarOperador(opsSobreCadena[0],archivo);

	opsSobreCadena[1].valor=1;
	strcpy(opsSobreCadena[1].simbolo,"like");
	strcpy(opsSobreCadena[1].atomo,"l");
	agregarOperador(opsSobreCadena[1],archivo);
	fputs("\n",archivo);
}


void creaOpLogicos(struct operador logico[],FILE *archivo){
	char simbolos[][3]={"&&","||","!"};
	char atomos[][3]={"h","j","!"};
	fputs("\n-----Catalogo de Operadores Logicos-----\n\tValor\tSimbolo\n",archivo);
							 
	for (int i=0; i<3; i++){
		logico[i].valor=i;
		strcpy(logico[i].simbolo,simbolos[i]);
		strcpy(logico[i].atomo,atomos[i]);
		agregarOperador(logico[i],archivo);

	}	
	fputs("\n",archivo);
}


void creaOpRelacionales(struct operador relacionales[],FILE *archivo){
	
	char simbolos[][6]={"==","!=",">","<",">=","<="};
	char atomos[][6]={"e","d",">","<","m","w"};
	fputs("\n-----Catalogo de Operadores Relacionales-----\n\tValor\tSimbolo\n",archivo);
							 
	for (int i=0; i<6; i++){
		relacionales[i].valor=i;
		strcpy(relacionales[i].simbolo,simbolos[i]);
		strcpy(relacionales[i].atomo,atomos[i]);
		agregarOperador(relacionales[i],archivo);
	}
	fputs("\n",archivo);
}


void creaOpAsignacion(struct operador asignaciones[],FILE *archivo){
	
	char simbolos[][6]={"=","+=","-=","*=","/=","%="};
	char atomos[][6]={"=","x","y","k","r","o"};
	fputs("\n-----Catalogo de Operadores de Asignación-----\n\tValor\tSimbolo\n",archivo);

	for (int i=0; i<6; i++){
		asignaciones[i].valor=i;
		strcpy(asignaciones[i].simbolo,simbolos[i]);
		strcpy(asignaciones[i].atomo,atomos[i]);
		agregarOperador(asignaciones[i],archivo);
	}
	fputs("\n",archivo);
}


int agregarOperador(struct operador op,FILE *archivo){
	char snum[5];
	sprintf(snum, "%d", op.valor);
	fputs("\t",archivo);
	fputs(strcat(snum,"\t"),archivo);
	fputs(op.simbolo,archivo);
	fputs("\n",archivo);
	return 1;
}


/*
----------Métodos para implementar búsquedas en los catálogos----------
 - buscaReservadas: devuelve la posición en la que se encuentra la palabra buscada, enviada como parámetro, dentro de la estructura de palabras que se pasa como parámetro también.
 - buscaOperadores: devuelve la posición en la que se encuentra el operador buscado dentro de una estructura de operadores. Recibe como parámetros la estructura en la cual realizará la búsqueda, la longitud de dicha estructura y el símbolo a localizar.
-----------------------------------------------------------------------
*/

int buscaReservadas(struct reservada palabras[],char *busca){
	for(int i=0; i<11;i++){
		if(strcmp(palabras[i].palabra,busca)==0)
			return palabras[i].valor;
	}
	return -1;
}


int buscaOperadores(struct operador listaOperadores[],int longitud,char *busca){
	for(int i=0; i<longitud;i++){
		if(strcmp(listaOperadores[i].simbolo,busca)==0)
			return listaOperadores[i].valor;
	}
	return -1;
}


/*
----------Métodos para la implementación de la tabla de literales----------
 - crearCadena: devuelve una estructura de tipo cadena, asignando a sus miembros la posición y el contenido indicados como parametros.
 - crearListaCadenas: devuelve una estructura de tipo listaCadenas, con sus miembros head y tamanio inicializados, es decir, crea una lista de nodos que tendrán la abstracción de cadenas como valor.
 - addCadenaALista: añade al final de la lista, cuya dirección se indica como primer paŕametro, un nodo que contenga la cadena que se pasa como segundo parámetro, también recibe el tamaño de dicha cadena como tercer parámetro. Devuelve la posición dentro de la lista en la que se añadió la cadena.
 - imprimirListaCadenas: muestra en pantalla los valores de la posición y el contenido para cada cadena almacenada en la lista recibida como parámetro.
---------------------------------------------------------------------------
*/


struct cadena crearCadena(int posicion,char *contenido,int tamanio){
	struct cadena nuevaCadena;
	nuevaCadena.posicion = posicion;
	nuevaCadena.dato = (char*)malloc(tamanio*sizeof(char));
	strncpy(nuevaCadena.dato,contenido+1,tamanio-2);
	return nuevaCadena;
}


struct listaCadenas crearListaCadenas(){
	struct listaCadenas lista;
	lista.head = NULL;
	lista.tamanio= 0;
	return lista;
}


int addCadenaALista(struct listaCadenas *lista, char *contenido,int tamanio) {
	struct nodoCadena *nuevoNodo = (struct nodoCadena*)malloc(sizeof(struct nodoCadena));
	nuevoNodo->valor = crearCadena(lista->tamanio,contenido,tamanio);
	nuevoNodo->next = NULL;

	if(lista->head==NULL){
    	lista->head = nuevoNodo;
	}else{
		struct nodoCadena *current = lista->head;
		while (current->next != 0) {
       		current = current->next;
 		}
 		current->next = nuevoNodo;
	}
	lista->tamanio++;
	return nuevoNodo->valor.posicion;
}


void imprimirListaCadenas(struct listaCadenas lista) {
    if(lista.head==NULL){
    	printf("\nLA LISTA ESTA VACIA \n");
    }else{
    	printf("Posic.\tCadena\n");
    	struct nodoCadena *current = lista.head;
		while (current != 0) {
        	printf("\n%d\t%s\n------------------",current->valor.posicion,current->valor.dato);
			current = current->next;
   	 	}
	}
}


/*
----------Métodos para la implementación de la tabla de símbolos----------
 - crearIdentificador: devuelve una estructura de tipo identificador, asignando a sus miembros la posición y el nombre del identificador indicados como parametros. El tipo se inicializa con -1.
 - crearListaIdentificadores: devuelve una estructura de tipo listaIdentificadores, con sus miembros head y tamanio inicializados con null y 0, respectivamente. Crea una lista de nodos que tendrán la abstracción de identificadores como valor.
 - addIdentificALista: añade el identificador con el nombre que se pasa como parámetro a una lista de identificadores (cuya dirección se pasa como primer paŕametro), únicamente en caso de que este no se encuentre dentro de la misma, de lo contrario, no lo agrega. La función devuelve la posición en la que se encuentre el identificador dentro de la lista.
 - buscarIdentificador: busca la posición en la que se ubica el identificador, cuyo nombre se pasa como parámetro, dentro de una lista, que también se indica como parámetro. En caso de estar vacía la lista, se indica y retorna un 0, en caso de haberlo encontrado regresa la posición el la que lo encontró y en caso de no haberlo localizado retorna un -1.
 - imprimirListaIdent: muestra en pantalla los valores de la posición, el nombre y el tipo para cada cadena almacenada en la lista de identificadores recibida como parámetro.
---------------------------------------------------------------------------
*/

struct identificador crearIdentificador(char *nombre,int posicion){
	struct identificador creado;
	creado.posicion = posicion;
	creado.tipo = -1;
	strcpy(creado.nombre,nombre);
	return creado;
}

struct listaIdentificadores crearListaIdentificadores(){
	struct listaIdentificadores lista;
	lista.head = NULL;
	lista.tamanio = 0;
	return lista;
}


int addIdentificALista(struct listaIdentificadores *lista, char *nombre){

	int posicion = buscarIdentificador(*lista,nombre);

	if(lista->head==NULL){
		struct nodoIdentificador *nodo = (struct nodoIdentificador*)malloc(sizeof(struct nodoIdentificador));
		nodo->valor = crearIdentificador(nombre,posicion);; 	
    	nodo->next = NULL;
    	lista->head = nodo;
    	lista->tamanio++;
    	return nodo->valor.posicion;
	}else if(posicion==-1){
		struct nodoIdentificador *current = lista->head;
		while (current->next != 0){
       		current = current->next;
 		}
		struct nodoIdentificador *nuevoNodo;
		nuevoNodo = (struct nodoIdentificador*)malloc(sizeof(struct nodoIdentificador));
    	nuevoNodo->valor = crearIdentificador(nombre,lista->tamanio);
    	nuevoNodo->next = NULL;
 		current->next = nuevoNodo;
 		lista->tamanio++;
 		return nuevoNodo->valor.posicion;
	}else{
		return posicion;
	}
}


int buscarIdentificador(struct listaIdentificadores lista,char *busca){
    if(lista.head==NULL){
    	return 0;
    }else{
    	struct nodoIdentificador *tempo = lista.head;
    	int cont=0;
   		while (tempo != NULL) {
   			if(strcmp(tempo->valor.nombre,busca)==0)
   				return cont;	
   			cont++;
			tempo = tempo->next;
   	 	}
   	 	return -1;
	}
}


void imprimirListaIdent(struct listaIdentificadores lista){
    if(lista.head==NULL){
    	printf("\nLA LISTA ESTA VACIA \n");
    }
    else{
    	printf("Posic.\tNombre\t\tTipo\n");
    	struct nodoIdentificador *current = lista.head;
		while (current != 0) {
        	printf("\n%d\t%s\t\t%d\n",current->valor.posicion,current->valor.nombre,current->valor.tipo);
			current = current->next;
   	 	}
	}
}

/*
------------------- FUNCIONES PARA GENERAR LA CADENA -----------------------
*/

void addCadenaFinal(char a){
	size++;
	N++;
	cadenaFinal = (char *)realloc(cadenaFinal, size * sizeof(char));
	cadenaFinal[N]=a;
}



/*
----------Métodos para la implementación de la tabla de tokens----------
 - crearListaToken: devuelve una estructura de tipo ListaToken con su miembro head inicializado con null.
 - addFinalListaToken: añade un nuevo token a la lista de tokens; para ello, se pasa como parámetro la dirección de la lista donde se agregará, así como la clase y el valor que contendrá el token.
 - imprimirListaToken: muestra el contenido de los tokens pertenecientes a la lista que se pasa como parámetro, muestra el índice del token, la clase y el valor.
------------------------------------------------------------------------
*/


struct ListaToken crearListaToken(){
	struct ListaToken lista;
	lista.head = NULL;
	return lista;
}


void addFinalListaToken(struct ListaToken *lista, short clase, int valor){
	if(lista->head==NULL){
		struct token *nodoToken = (struct token*)malloc(sizeof(struct token));
		nodoToken->clase = clase;
		nodoToken->valor = valor;
    	nodoToken->next = NULL;
    	lista->head = nodoToken;
	}else{
		struct token *current = lista->head;
		while (current->next != 0) {
       		current = current->next;
 		}
		struct token *nuevotoken;
		nuevotoken = (struct token*)malloc(sizeof(struct token));
    	nuevotoken->clase = clase;
		nuevotoken->valor = valor;
    	nuevotoken->next = NULL;
 		current->next = nuevotoken;
	}	
}


void imprimirListaToken(struct ListaToken listaToken){
    int i=0;
	if(listaToken.head==NULL){
    	printf("\nLA LISTA ESTA VACIA \n");
    }
    else{
    	struct token *current = listaToken.head;
		printf("Clase\tValor\n");
   		while (current != 0) {
        	printf("%d\t%d\n",current->clase,current->valor);
			current = current->next;
			i++;
   	 	}
	}
}


/*
----------Método para mostrar las tablas creadas----------
 - mostrarTablas: desde esta función se llama a las funciones correspondientes para hacer la impresión del contenido de la tabla de literales, de símbolos y de tokens que se han llenado durante la ejecución.
----------------------------------------------------------
*/

void mostrarTablas(){
	printf("\n\n-------Tabla de LITERALES-------\n");
	imprimirListaCadenas(tablaDeLiterales);
	printf("\n\n-------Tabla de SIMBOLOS-------\n");
	imprimirListaIdent(tablaDeSimbolos);
	printf("\n\n-------Tabla de TOKENS-------\n");
	imprimirListaToken(tablaToken);
	printf("\n");
}

/*
----------Método para obtener valor ASCII -----------
 - obtenerAscii: Obtiene el ASCII del caracter enviado como parḿetro.
-----------------------------------------------------
*/

int obtenerAscii(char *convierte){
	int aux;
	if(strcmp(convierte,"(")==0)
		aux= 40;
	else if (strcmp(convierte,")")==0)
		aux=41;
	else if (strcmp(convierte,"{")==0)
		aux=123;
	else if (strcmp(convierte,"}")==0)
		aux=125;
	else if (strcmp(convierte,";")==0)
		aux=59;
	else if (strcmp(convierte,",")==0)
		aux=44;
	else if (strcmp(convierte,"[")==0)
		aux=91;
	else if (strcmp(convierte,"]")==0)
		aux=93;
	else if (strcmp(convierte,":")==0)
		aux=58;
	else if (strcmp(convierte,"#")==0)
		aux=35;
	else if (strcmp(convierte,"+")==0)
		aux=43;
	else if (strcmp(convierte,"-")==0)
		aux=45;
	else if (strcmp(convierte,"/")==0)
		aux=47;
	else if (strcmp(convierte,"*")==0)
		aux=42;
	else if (strcmp(convierte,"%")==0)
		aux=37;
	else aux=0;
	return aux;
}

/*
----------Método para convertir un número de caracter a int-----------
 - convierteInt: Convierte un número en formato de cadena de carácteres (que se pasa como parámetro) a un elemento de tipo int.
----------------------------------------------------------------------
*/

int convierteInt(char cadena[]){
	int tam=strlen(cadena)/sizeof(char);
	int i,j,num=0;
	if(cadena[0]=='('){
		if(cadena[1]=='+'){
			i=2;
			j=0;
			char auxChar[tam-3];
			while(cadena[i]!=')'){
				auxChar[j]=cadena[i];
				i++;
				j++;
			}
			num= atoi(auxChar);
			return num;
		}else{
			i=1;
			j=0;
			char auxChar[tam-2];
			while(cadena[i]!=')'){
				auxChar[j]=cadena[i];
				i++;
				j++;
			}
			num= atoi(auxChar);
			return num;
		}
	}else{
		num= atoi(cadena);
	}
	
	return num;
}



/*
------Función para retornar un carácter leído de la cadena de átomos------
*/

char get_char(){
  if(indice <= size){
		indice++;
		return cadenaFinal[indice];
	}else{
		return '$';
	}
}

/*
------Función para mostrar un error sintáctico------
*/

void print_error(char const *msj_error){
  printf("----------------------------\n");
  printf("** ERROR en el atomo %i: %c\n",indice,cadenaFinal[indice]);
  printf(msj_error);
  contadorErrores++;
  //c=get_char(); /*CHECAR*/
}




/*
----------Funciones para implementar el Analizador Sintactico-----------
*/

void AnalizadorSintactico(){
	c=get_char();
	Program();
	
	printf("----------------------------\n");
	if(contadorErrores==0)
		printf("-> El programa fuente analizado es sintacticamente corecto :)\n");
	else
		printf("-> El programa fuente analizado NO es sintacticamente corecto :(\n");
	printf("----------------------------\n");
}


void Program(){
	if(c=='f' || c=='i'|| c=='g'){
		Func();
		otraFunc();
	}else{
		print_error("En la produccion <Program> se esperaba alguno de estos atomos: f i g\n");
		return;	
	}
}


void otraFunc(){
	if(c=='f' || c=='i'|| c=='g'){
		Func();
		otraFunc();
	}else if(c=='$'){
		return;
	}else{
		print_error("En la produccion <otraFunc> se esperaba alguno de estos atomos: f i g $\n");
		return;	
	}
}


void Func(){
	if(c=='f' || c=='i'|| c=='g'){
		TipoF();
		
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <Func> se esperaba el atomo: a\n");

		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Func> se esperaba el atomo: (\n");

		listArg();

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Func> se esperaba el atomo: )\n");

		if(c=='{')
			c=get_char();
		else
			print_error("En la produccion <Func> se esperaba el atomo: {\n");

		Cuerpo();

		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <Func> se esperaba el atomo: }\n");
	}else{
		print_error("En la produccion <Func> se esperaba alguno de estos atomos: f i g\n");
		return;	
	}
}


void TipoF(){
	if(c=='f' || c=='i'){
		Tipo();
	}else if(c=='g'){
		c=get_char();
	}else{
		print_error("En la produccion <TipoF> se esperaba alguno de estos atomos: f i g\n");
		return;	
	}
}


void listArg(){
	if(c=='f' || c=='i'){
		Tipo();
		
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <listArg> se esperaba el atomo: a\n");

		otroArg();
	}else if(c==')'){
		return;
	}else{
		print_error("En la produccion <listArg> se esperaba alguno de estos atomos: f i )\n");
		return;	
	}
}


void otroArg(){
	if(c==','){
		c=get_char();

		Tipo();
		
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <otroArg> se esperaba el atomo: a\n");
			
		otroArg();
	}else if(c==')'){
		return;
	}else{
		print_error("En la produccion <otroArg> se esperaba alguno de estos atomos: , )\n");
		return;	
	}
}


void Cuerpo(){
	if(c=='f' || c=='i'){
		listDecl();
		listaS();
	}else{
		print_error("En la produccion <Cuerpo> se esperaba alguno de estos atomos: f i\n");
		return;	
	}
}


void listDecl(){
	if(c=='a' || c=='u' || c=='t' || c=='b' || c=='q' || c=='z' || c=='s' || c=='p' || c=='[' || c=='}'){
		return;
	}else if(c=='f' || c=='i'){
		Decl();
		listDecl();
	}else{
		print_error("En la produccion <listDecl> se esperaba alguno de estos atomos: f i a u t b q z s p [ }\n");
		return;	
	}
}


void Decl(){
	if(c=='f' || c=='i'){
		Tipo();
		
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <Decl> se esperaba el atomo: a\n");
			
		valorIni();
		listaVar();

		if(c==';')
			c=get_char();
		else
			print_error("En la produccion <Decl> se esperaba el atomo: ;\n");
	}else{
		print_error("En la produccion <Decl> se esperaba alguno de estos atomos: f i\n");
		return;	
	}
}


void Tipo(){
	if(c=='f'){
		c=get_char();
	}else if(c=='i'){
		c=get_char();
	}else{
		print_error("En la produccion <Tipo> se esperaba alguno de estos atomos: f i\n");
		return;	
	}
}


void valorIni(){
	if(c=='='){
		c=get_char();
		tipoVal();
	}else if(c==',' || c==';'){
		return;
	}else{
		print_error("En la produccion <valorIni> se esperaba alguno de estos atomos: = , ;\n");
		return;	
	}
}


void listaVar(){
	if(c==','){
		c=get_char();
		
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <listaVar> se esperaba el atomo: a\n");
		
		valorIni();
		listaVar();
	}else if(c==';'){
		return;
	}else{
		print_error("En la produccion <listaVar> se esperaba alguno de estos atomos: , ;\n");
		return;	
	}
}


void tipoVal(){
	if(c=='n'){
		c=get_char();
	}else if(c=='v'){
		c=get_char();
	}else{
		print_error("En la produccion <tipoVal> se esperaba alguno de estos atomos: n v\n");
		return;	
	}
}


void Asig(){
	if(c=='a'){
		c=get_char();
		
		opArit();
		E();
		
		if(c==';')
			c=get_char();
		else
			print_error("En la produccion <Asig> se esperaba el atomo: ;\n");

	}else if(c=='v'){
		c=get_char();
	}else{
		print_error("En la produccion <Asig> se esperaba alguno de estos atomos: a v\n");
		return;	
	}
}


void opArit(){
	if(c=='=' || c=='x' || c=='y' || c=='k' || c=='r' || c=='o'){
		c=get_char();
	}else{
		print_error("En la produccion <opArit> se esperaba alguno de estos atomos: = x y k r o\n");
		return;	
	}
}


void E(){
	if(c=='(' || c=='a' || c=='n' || c=='['){
		T();
		EP();
	}else{
		print_error("En la produccion <E> se esperaba alguno de estos atomos: ( a n [\n");
		return;	
	}
}


void EP(){
	if(c==';' || c==')' || c=='>' || c=='<' || c=='e' || c=='d' || c=='m' || c=='w' || c=='h' || c=='j' || c==','){
		return;
	}else if(c=='+' || c=='-'){
		c=get_char();
		T();
		EP();
	}else{
		print_error("En la produccion <EP> se esperaba alguno de estos atomos: + - ; ) > <  e d m w h j ,\n");
		return;	
	}
}

void T(){
	if(c=='(' || c=='a' || c=='n' || c=='['){
		F();
		TP();
	}else{
		print_error("En la produccion <T> se esperaba alguno de estos atomos: ( a n [\n");
		return;	
	}
}


void TP(){
	if(c=='+' || c=='-' || c==';' || c==')' || c=='>' || c=='<' || c=='e' || c=='d' || c=='m' || c=='w' || c=='h' || c=='j' || c==','){
		return;
	}else if(c=='*' || c=='/' || c=='%'){
		c=get_char();
		F();
		TP();
	}else{
		print_error("En la produccion <TP> se esperaba alguno de estos atomos: * / % + - ; ) > <  e d m w h j ,\n");
		return;	
	}
}

void F(){
	if(c=='('){
		c=get_char();
		
		E();

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <F> se esperaba el atomo: )\n");

	}else if(c=='a' || c=='n'){
		c=get_char();
	}else if(c=='['){
		Llama();
	}else{
		print_error("En la produccion <F> se esperaba alguno de estos atomos: ( a n [\n");
		return;	
	}
}


void R(){
	if(c=='(' || c=='a' || c=='n' || c=='['){
		E();

		opRel();

		E();
	}else{
		print_error("En la produccion <R> se esperaba alguno de estos atomos: ( a n [\n");
		return;	
	}
}


void opRel(){
	if(c=='>' || c=='<' || c=='e' || c=='d' || c=='m' || c=='w'){
		c=get_char();
		return;
	}else{
		print_error("En la produccion <opRel> se esperaba alguno de estos atomos: > < e d m w\n");
		return;	
	}
}


void Sent(){
	if(c=='a'){
		Asig();
	}else if(c=='u'){
		Q();
	}else if(c=='t'){
		Ret();
	}else if(c=='b'){
		Trocar();
	}else if(c=='q'){
		Enq();
	}else if(c=='z'){
		Faz();
	}else if(c=='s'){
		Se();
	}else if(c=='p'){
		Para();
	}else if(c=='['){
		Llama();
	}else{
		print_error("En la produccion <Sent> se esperaba alguno de estos atomos: a u t b q z s p [\n");
		return;	
	}
}


void listaS(){
	if(c=='}' || c=='#'){
		return;
	}else if(c=='a' || c=='u' || c=='t' || c=='b' || c=='q' || c=='z' || c=='s' || c=='p' || c=='['){
		Sent();
		listaS();
	}else{
		print_error("En la produccion <listaS> se esperaba alguno de estos atomos: } # a u t b q z s p [\n");
		return;	
	}
}


void expLogica(){
	if(c=='(' || c=='a' || c=='n' || c=='['){
		R();
		expLog();
	}else if(c=='!'){
		c=get_char();
		expRel();
	}else{
		print_error("En la produccion <expLogica> se esperaba alguno de estos atomos: ! ( a n [\n");
		return;	
	}
}


void expLog(){
	if(c=='h' || c=='j'){
		opLog();
		R();
	}else if(c==')'){
		return;
	}else{
		print_error("En la produccion <expLog> se esperaba alguno de estos atomos: h j )\n");
		return;	
	}
}


void expRel(){
	if(c=='{'){
		c=get_char();

		R();
		
		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <expRel> se esperaba el atomo: }\n");

	}else if(c=='(' || c=='a' || c=='n' || c=='['){
		E();
	}else{
		print_error("En la produccion <expRel> se esperaba alguno de estos atomos: { ( a n [\n");
		return;	
	}
}


void opLog(){
	if(c=='h' || c=='j'){
		c=get_char();
	}else{
		print_error("En la produccion <opLog> se esperaba alguno de estos atomos: h j\n");
		return;	
	}
}


// <Enq> -> q(<expLogica>)#<listaS># 
void Enq(){
	if(c=='q'){
		c=get_char();
		
		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Enq> se esperaba el atomo: (\n");

		expLogica();

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Enq> se esperaba el atomo: )\n");
		
		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Enq> se esperaba el atomo: #\n");

		listaS();

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Enq> se esperaba el atomo: #\n");
		return;
	}else{
		print_error("En la produccion <Enq> se esperaba el atomo: q\n");
		return;
	}
}

//<Se> → s(<expLogica>)#<listaS>#
void Se(){
	if(c=='s'){
		c=get_char();
		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Se> se esperaba el atomo: (\n");

		expLogica();

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Se> se esperaba el atomo: )\n");
		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Se> se esperaba el atomo: #\n");

		listaS();

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Se> se esperaba el atomo: #\n");
		return;
	}else{
		print_error("En la produccion <Se> se esperaba el atomo: s\n");
		return;
	}
}

//Q → u;
void Q(){
	if(c=='u'){
		c=get_char();
		if(c==';')
			c=get_char();
		else
			print_error("En la produccion <Q> se esperaba el atomo: ;\n");
		return;
	}else{
		print_error("En la produccion <Q> se esperaba el atomo: u\n");
	}
}

//<Faz>→ z#<listas>#q(<expLogica>);
void Faz(){
	if(c=='z'){
		c=get_char();
		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Faz> se esperaba el atomo: #\n");

		listaS();

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Faz> se esperaba el atomo: #\n");
		if(c=='q')
			c=get_char();
		else
			print_error("En la produccion <Faz> se esperaba el atomo: q\n");
		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Faz> se esperaba el atomo: (\n");

		expLogica();

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Faz> se esperaba el atomo: )\n");
		if(c==';')
			c=get_char();
		else
			print_error("En la produccion <Faz> se esperaba el atomo: ;\n");
		return;
	}else{
		print_error("En la produccion <Faz> se esperaba el atomo: z\n");
		return;
	}
}

//<Ret> → t<valRet>;
void Ret(){
	if(c=='t'){
		c=get_char();
		
		valRet();

		if(c==';')
			c=get_char();
		else
			print_error("En la produccion <Ret> se esperaba el atomo: ;\n");
		
		return;
	}else{
		print_error("En la produccion <Ret> se esperaba el atomo: t\n");
		return;
	}
}

//<valRet> → E
//<valRet> → {<expCad>}
//<valRet> → ξ
void valRet(){
	if(c=='(' || c=='a' || c=='n' || c=='['){
		E();
		return;
	}else if(c=='{'){
		c=get_char();
		expCad();
		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <valRet> se esperaba el atomo: }\n");
		return;
	}else if(c==';'){
		return;
	}else{
		print_error("En la produccion <valRet> se esperaba alguno de estos atomos: ( a n [ { ;\n");
		return;
	}
}

//<expCad> → a<opCad>
//<expCad> → v<opCad>
void expCad(){
	if(c=='a'){
		c=get_char();
		opCad();
		return;
	}else if(c=='v'){
		c=get_char();
		opCad();
		return;
	}else{
		print_error("En la produccion <expCad> se esperaba alguno de estos atomos: a v\n");
		return;
	}
}

//<opCad> → l <expCad>
//<opCad> → h <expCad>
//<opCad> → ξ
void opCad(){
	if(c=='l'){
		c=get_char();
		expCad();

	}else if(c=='h'){
		c=get_char();
		expCad();
	}else if(c==']'){
		return;
	}else{
		print_error("En la produccion <expCad> se esperaba alguno de estos atomos: l h ]\n");
		return;
	}
}

//<Para> → pa[n,n]#<listaS>#
void Para(){
	if(c=='p'){
		c=get_char();
		
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: a\n");

		if(c=='[')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: [\n");
		if(c=='n')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: n\n");
		if(c==',')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: ,\n");

		if(c=='n')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: n\n");
		if(c==']')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: ]\n");

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: #\n");

		listaS();

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Para> se esperaba el atomo: #\n");
		return;
	}else{
		print_error("En la produccion <Para> se esperaba el atomo: p\n");
		return;
	}
}

//<Trocar> → b(a):#c(n){<listaS>}<casos>#
void Trocar(){
	if(c=='b'){
		c=get_char();
		
		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: (\n");

		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: a\n");
		
		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: )\n");
		
		if(c==':')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: :\n");

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: #\n");
		
		if(c=='c')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: c\n");

		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: (\n");

		if(c=='n')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: n\n");

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: )\n");

		if(c=='{')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: {\n");

		listaS();

		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: }\n");

		casos();

		if(c=='#')
			c=get_char();
		else
			print_error("En la produccion <Trocar> se esperaba el atomo: #\n");
		return;
	}else{
		print_error("En la produccion <Trocar> se esperaba el atomo: b\n");
		return;
	}
}

//<casos> → ξ
//<casos> → c(n){<listaS>}<casos>
//<casos> → (){<listaS>}<casos>
void casos(){
	if(c=='c'){
		c=get_char();
		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: (\n");

		if(c=='n')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: n\n");
		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: )\n");
		if(c=='{')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: {\n");
		listaS();
		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: }\n");
		casos();
		return;
	}else if(c=='('){
		c=get_char();
		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: )\n");

		if(c=='{')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: {\n");

		listaS();

		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <casos> se esperaba el atomo: }\n");
		casos();
		return;
	}else if(c=='#'){
		return;
	}
	else{
		print_error("En la produccion <expCad> se esperaba alguno de estos atomos: c ( #\n");
		return;
	}
}
//<Llama> → [a(<listP>)]
void Llama(){
	if(c=='['){
		c=get_char();
		if(c=='a')
			c=get_char();
		else
			print_error("En la produccion <Llama> se esperaba el atomo: a\n");

		if(c=='(')
			c=get_char();
		else
			print_error("En la produccion <Llama> se esperaba el atomo: (\n");

		listP();

		if(c==')')
			c=get_char();
		else
			print_error("En la produccion <Llama> se esperaba el atomo: )\n");
		if(c==']')
			c=get_char();
		else
			print_error("En la produccion <Llama> se esperaba el atomo: ]\n");
		return;
	}else{
		print_error("En la produccion <Llama> se esperaba el atomo: [\n");
		return;
	}
}

//<listP> → ξ
//<listP> → E<Param>
//<listP> → {<expCad>}<Param>
void listP(){
	if(c=='{'){
		c=get_char();
		expCad();
		
		if(c=='}')
			c=get_char();
		else
			print_error("En la produccion <listP> se esperaba el atomo: }\n");
		Param();
		return;
	}else if(c=='(' || c=='a' || c=='n' || c=='['){
		E();
		Param();
		return;
	}else if(c==')'){
		return;
	}
	else{
		print_error("En la produccion <listP> se esperaba alguno de estos atomos: ( a n [ { )");
		return;
	}
}

//<Param> → ,<listP>
//<Param> → ξ
void Param(){
	if(c==','){
		c=get_char();
		listP();
		return;
	}else if(c==')'){
		return;
	}
	else{
		print_error("En la produccion <Param> se esperaba alguno de estos atomos: , )");
		return;
	}
}


/*
----------Función principal del programa-----------
 Recibe el apuntador a una cadana con el nombre del archivo que va a analizar.
 Crea el archivo correspondiente a los catálogos, así como los catálogos en sí y abre el archivo a analizar, 
 de ser válido, crea la tabla de símbolos y de literales y realiza el análisis; en caso contrario, notifica
 que no logró abrir el archivo.
-----------------------------------------------------
*/

int main(int argc, char *argv[]){

	FILE *fcatalogo;

	fcatalogo=fopen("catalogo.txt","w+");

	crearCatalogos(fcatalogo);

	if ( (yyin=fopen(argv[1],"r"))==NULL){
		printf("No se pudo abrir el archivo %s",argv[1]);
		return 1;
	}
	else{
		tablaDeSimbolos = crearListaIdentificadores();
		tablaDeLiterales = crearListaCadenas();
		printf("Se abrio correctamente el archivo %s\n",argv[1]);
		cadenaFinal = (char *)malloc(size * sizeof(char));
		yylex();
		addCadenaFinal('$');
		AnalizadorSintactico();
		mostrarTablas();
		printf("\nCadena Generada: \n%s\n",cadenaFinal);
		free(cadenaFinal);		
	}
	fclose(fcatalogo);

	fclose(yyin);
	return 0;
}
