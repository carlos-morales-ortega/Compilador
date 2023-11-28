#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE* archivo;

char cadena[100]; 
char pila[200]={254,'0'};


void obtenerCadena();

int main(int argc, char *argv[]) {

    archivo=fopen(argv[1],"r");
    
    if ((archivo==NULL)){
        printf("No se pudo abrir el archivo %s\n", argv[1]);
        return 1;
    }else{
        printf("Se abrio correctamente el archivo %s\n", argv[1]);
        obtenerCadena();
        imprime();
    }

    fclose(archivo);
    return 0;

}

void obtenerCadena(){
    int i=0;
    char caracter;
    while((caracter = fgetc(archivo)) != '$')
	    {
            cadena[i]=caracter;
            i++;
	    }

    printf("Cadena introducida: %s\n",cadena);
}

void imprime(){
    
    printf("%s",cadena);
    
    printf("\t \t"); // imprime 2 tabuladores
    printf("%s\n",pila);
    
}