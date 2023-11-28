#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// Inicializar los punteros de cadenas a NULL
char *cadena = NULL;  
char *salida = NULL;
char *errores=NULL;
//caracteres especiales que se ocuparon
char pila =254;
char fin=180;
//Declaración de funciones 
void error();
void edo0();
void edo1();
void edo2();
void edo3();
void edo4();
void edo5();
void edo6();
void edo7();
void edo8();
void edo9();
void ver();
//Contadores globales 
int i=0;
int j=2;
int e=0;


int main() {
   
    size_t longitud = 0;  // Inicializar la longitud de la cadena

    // Solicitar al usuario que ingrese la cadena
    printf("Ingresa la cadena, recuerde agregar %c al final: ",fin);
    // Utilizar getline para leer una línea de entrada
    getline(&cadena, &longitud, stdin);
    salida = (char *)malloc(2*strlen(cadena) * sizeof(char));
    salida[0]=254;
    salida[1]='0';
    // Mandar a llamar el analizador
    ver(); 
    edo0();
    // Liberar la memoria de los arreglos
    free(cadena);
    free(salida);
    free(errores);

    return 0;
}


void edo0() //estado 0 de la tabla de parser 
{
    if (cadena[i]=='a') // si se lee una a de la cadena
    {
        i+=1;
        salida[j]='a'; // Escribe el valor al que apunta la cadena a la pila
        j++;
        salida[j]='3'; //Escribe a que estado irá según la tabla
        j++;
        ver();// Imprime en pantalla lo que ha ocurrido en la cadena y la pila
        edo3(); //Manda al estado correspondiente según la tabla
    }
    else
    {
        if (cadena[i]=='(') // si se lee un ( de la cadena
        {
            i+=1;
            salida[j]='(';// Escribe el valor al que apunta la cadena a la pila
            j++;
            salida[j]='2';//Escribe a que estado irá según la tabla
            j++;
            ver();// Imprime en pantalla lo que ha ocurrido en la cadena y la pila
            edo2();//Manda al estado correspondiente según la tabla
        }
        else //Llama a la función error
        {
            e=2; //numero de posibles caracteres 
            errores = (char *)malloc(e * sizeof(char)); // asignación de memoria  
            errores[0]='a';
            errores[1]='(';
            error();// Llama a la función error
        }
    }
}

void edo1() // Estado 1 de la tabla de parser sigue el comportamiento similar al anterior
{

    if (cadena[i]==fin)
    {
        i+=1;
        salida[j]=fin;
        j++;
        salida[j]='4';
        j++;
        ver();
        edo4();
    }
    else
    {
         e=1;
        errores = (char *)malloc(e * sizeof(char));
        errores[0]=fin;
        error();
    }
}

void edo2() // Estado 2 de la tabla de parser sigue el comportamiento similar al anterior
{
    if (cadena[i]=='a')
    {
        i+=1;
        salida[j]='a';
        j++;
        salida[j]='3';
        j++;
        ver();
        edo3();
    }
    else
    {
        if (cadena[i]=='(')
        {
            i+=1;
            salida[j]='(';
            j++;
            salida[j]='2';
            j++;
            ver();
            edo2();
        }
        else
        {
            e=2;
            errores = (char *)malloc(e * sizeof(char));
            errores[0]='a';
            errores[1]='(';
            error();
        }
    }
}

void edo3() // Estado 3 de la tabla de parser es un estado de reducción
{
    if(salida[j-3]=='0') // Revisa si el estado del valor anterior al Handle es 0
    {
        j-=2; // "Borra" el handle
        salida[j]='E'; // Sustituye por la reducción correspondiente
        j++;
        salida[j]='1'; //Escribe estado correspondiente según el estado anterior al handle
        j++;
        ver();// Imprime en pantalla lo que ha ocurrido en la cadena y la pila
        edo1();//Manda al estado correspondiente según el estado anterior al handle
    }
    if(salida[j-3]=='2') // Revisa si el estado del valor anterior al Handle es 2
    {
        j-=2;
        salida[j]='E';// Sustituye por la reducción correspondiente
        j++;
        salida[j]='6';//Escribe estado correspondiente según el estado anterior al handle
        j++;
        ver();// Imprime en pantalla lo que ha ocurrido en la cadena y la pila
        edo6();//Manda al estado correspondiente según el estado anterior al handle
    }
    if(salida[j-3]=='8')// Revisa si el estado del valor anterior al Handle es 8
    {
        j-=2;
        salida[j]='E';// Sustituye por la reducción correspondiente
        j++;
        salida[j]='9';//Escribe estado correspondiente según el estado anterior al handle
        j++;
        ver();// Imprime en pantalla lo que ha ocurrido en la cadena y la pila
        edo9();//Manda al estado correspondiente según el estado anterior al handle
    }
}

void edo4() // Estado 4, estado de aceptación 
{
    if (i==strlen(cadena)-1) //Si el contador que es el apuntado de la cadena ha llegado al final
    {
        printf("\n Acepta"); // imprime que se acepta 
    }
}

void edo5() //Estado 5 comportamiento similar al estado 0
{
    if (cadena[i]==')')
    {
        i+=1;
        salida[j]=')';
        j++;
        salida[j]='7';
        j++;
        ver();
        edo7();
    }
    else
    {
        if (cadena[i]==',')
        {
            i+=1;
            salida[j]=',';
            j++;
            salida[j]='8';
            j++;
            ver();
            edo8();
        }
        else
        {
            e=2;
            errores = (char *)malloc(e * sizeof(char));
            errores[0]=')';
            errores[1]=',';
            error();
        }
    }
}

void edo6()//Estado 6 de reducción 
{
    j-=2;//Se borra el handle
    salida[j]='L';//Se sustituye por la reducción
    j++;
    salida[j]='5';//Como solo hay un caso para el estado en toda la tabla se escribe ese estado 
    j++;
    ver();//imprime en pantalla lo ocurrido 
    edo5(); // se manda al estado de la tabla   
}

void edo7()//Estado 7 comportamiento similar al estado 3
{
    if(salida[j-7]=='0')
    {
        j-=6;//El handle es de 6 caracteres en la pila
        salida[j]='E';
        j++;
        salida[j]='1';
        j++;
        ver();
        edo1();
    }
    if(salida[j-7]=='2')
    {
        j-=6;
        salida[j]='E';
        j++;
        salida[j]='6';
        j++;
        ver();
        edo6();
    }
    if(salida[j-7]=='8')
    {
        j-=6;
        salida[j]='E';
        j++;
        salida[j]='9';
        j++;
        ver();
        edo9();
    }
}

void edo8()//Estado 8 comportamiento similar al estado 3
{
    if (cadena[i]=='a')
    {
        i+=1;
        salida[j]='a';
        j++;
        salida[j]='3';
        j++;
        ver();
        edo3();
    }
    else
    {
        if (cadena[i]=='(')
        {
            i+=1;
            salida[j]='(';
            j++;
            salida[j]='2';
            j++;
            ver();
            edo2();
        }
        else
        {
            e=2;
            errores = (char *)malloc(e * sizeof(char));
            errores[0]='a';
            errores[1]='(';
            error();
        }
    }
}

void edo9()//Estado 9 comportamiento similar al estado 6
{
    j-=6; //El handle es de 6 caracteres en la pila 
    salida[j]='L';
    j++;
    salida[j]='5';
    j++;
    ver();
    edo5();
}


void error() //función de error  
{
    printf("\n Se ha encontrado un error en la posicion %d se esperaba: ",i);
    for(int k=0; k<e;k++) //Ciclo que itera sobre la cadena de errores
    {
        printf("%c", errores[k]);
    }
}

void ver() // Funcion para ver 
{
    printf("\n"); //imprime un salto de linea
    for(int k=i;k<strlen(cadena);k++) //itera para ver lo que queda en la cadena
    {
        printf("%c",cadena[k]);
    }
    printf("\t \t"); // imprime 2 tabuladores
    for(int k=0;k<j;k++) // itera para ver lo que hay en la pila 
    {
        printf("%c",salida[k]);
    }
}