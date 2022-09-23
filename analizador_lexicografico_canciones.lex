%{

#pragma warning(disable: 4996 6387 6011 6385)
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ctype.h>
#include <wchar.h>
#include <locale.h>


//definiciones de directiva
#define MAX_PALABRAS 15000
#define MAX_LONGITUD 200
#define MAX_INCLUDE_DEPTH 10


// variable globaless
int include_stack_ptr = 0;
unsigned int nivel_de_includes = 0;
char directorio[MAX_LONGITUD]="";
char archivo_de_entrada[MAX_LONGITUD]="";
char archivo_de_entrada1[MAX_LONGITUD]="";
char archivo_a_abrir[MAX_LONGITUD]="";
char archivo_a_abrir1[MAX_LONGITUD]="";
char genero[MAX_LONGITUD]="";
char artista[MAX_LONGITUD]="";
unsigned int bandera = 0;

//apuntador para los archivos
FILE *fptArtistas;
FILE *fptGeneros;

//contadores de palabras por diccionario
unsigned int cuenta_palabras_generos=0;
unsigned int cuenta_palabras_artistas=0;

//definicion de estructuras
typedef struct 
{
	char indice[MAX_LONGITUD];
	unsigned int cantidad;
	char palabra[MAX_LONGITUD];
} elemento;

//definicion de funciones
void analiza_palabra_por_artista_encontrada(const char* palabra);
void analiza_palabra_por_genero_encontrada(const char* palabra);
void analiza_indice_canciones(const char* palabra);
void ordena_diccionarios(void);

//definicion de diccionarios
elemento diccionarioGeneros[MAX_PALABRAS];
elemento diccionarioArtistas[MAX_PALABRAS];

//Definicion de variable de flex
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH]; /* PILA para archivos */

%}


%option noyywrap
%option outfile="analizador_lex_canciones.c"

PALABRA             [A-ZÑÁÉÍÓÚÜa-zñáéíóúü][A-ZÑÁÉÍÓÚÜa-zñáéíóúü]+
NO_CERO             [1-9]
DIGITOS             [0-9]
NUMERO_ENTERO       {NO_CERO}{DIGITOS}*
GUION               [_]
NUMERO_ENTERO_GUION {GUION}{NUMERO_ENTERO}
PALABRA_GUION       {GUION}{PALABRA}
NOMBRE              {PALABRA}{PALABRA_GUION}*{NUMERO_ENTERO_GUION}*
NOMBRE_DIAGONAL     {NOMBRE}[/]
EXTENSION           [.]{PALABRA}
URL                 {NOMBRE_DIAGONAL}*{NOMBRE}{EXTENSION}

%x ANALIZADOR

%%


{NOMBRE} {
		//funcion al encontrar el token NOMBRE 
	 	analiza_indice_canciones(yytext);
		bandera++;
	  }

{URL} { //funcion al encontrar el token url 
	/* ir a abrir el archivo include */
			if ( include_stack_ptr >= MAX_INCLUDE_DEPTH )
			{
			    printf("Archivos include sobrepasan la profundidad maxima\n" );
			    exit(1);
			}
			yytext;
            strcpy(archivo_de_entrada1, yytext);
            strcpy(archivo_a_abrir1, directorio);
            strcat(archivo_a_abrir1, archivo_de_entrada1);
            yyin = fopen(archivo_a_abrir1, "r" );
			if (!yyin )
			{
			   printf("Error al abrir el archivo %s\n",archivo_a_abrir1 );
			   exit(1);
			}
			printf("Cambiando la lectura al archivo %s\n",archivo_a_abrir1 );
			include_stack[include_stack_ptr++]=YY_CURRENT_BUFFER;
			yy_switch_to_buffer(yy_create_buffer( yyin, YY_BUF_SIZE ) );
			if (include_stack_ptr > nivel_de_includes)
				nivel_de_includes = include_stack_ptr;
			//Empezar las regla exclusiva de flex
			BEGIN(ANALIZADOR);
		}

<<EOF>> { /* Si se detecta el fin de archivo se retorna */
		if ( --include_stack_ptr < 0 )
		    yyterminate();
		else
		{
			yy_delete_buffer( YY_CURRENT_BUFFER );
			yy_switch_to_buffer( include_stack[include_stack_ptr] );
			printf("Cerrando el archivo %s\n",archivo_a_abrir1 );
		}
		BEGIN(INITIAL);
	}


<ANALIZADOR>{PALABRA} {
		//funciones al encontrar el token PALABRA cuando esta la regla exclusiva activa de ANALIZADOR 
	 	//printf("Palabra: %s\n", yytext);
	 	analiza_palabra_por_artista_encontrada(yytext);
		analiza_palabra_por_genero_encontrada(yytext);
  }
","
.       printf("Caracter invalido %s\n",yytext);      
%%

int main( int argc, char* argv[] )
{
	//Habilitamos que se pueda ver carateres especiales del español
    setlocale(LC_ALL, ".UTF8");
	if ( argc == 3 )
	{
		strcpy(directorio, argv[1]);
		strcat(directorio, "\\");
		strcpy(archivo_de_entrada, argv[2]);
		strcpy(archivo_a_abrir, directorio);
		strcat(archivo_a_abrir, archivo_de_entrada);
		//Abrimos indice de canciones
		yyin = fopen(archivo_a_abrir, "r" );
		if (yyin)
		{
			printf("Directorio de trabajo: %s\n", directorio);
			printf("Leyendo del archivo: %s\n", archivo_de_entrada);
		}
	}
	else
	{
		printf("Este programa solo lee de un archivo no puede leer de una entrada de teclado");
		return(1);
	}
	yylex();
	//Abrimos un archivo csv por cada diccionario y le ponemos encabezado
	fptArtistas=fopen("ListadoArtistas.csv", "a+");
	fprintf(fptArtistas,"Artista,Palabra,Cantidad\n");
	fptGeneros=fopen("ListadoGeneros.csv", "a+");
	fprintf(fptGeneros,"Genero,Palabra,Cantidad\n");
	//La funcion de ordenacion esta comentada debido a que por la longitud de los diccionarios se tarda mas de 2 horas en ordenarlos
	/* printf("\nOrdenando diccionario\nOrdenando");
	ordena_diccionarios(); */
	printf("\nListado de palabras encontradas por artista\n");
	//Por cada elemento del diccionario imprimimos en el archivo el artista o genero, la palabra y las veces que la dice
	//Mostramos en consola la bandera en la que se va para que el usuario sepa que sigue funcionando el programa
	for (unsigned int j = 1; j <= cuenta_palabras_artistas; j++){
		fprintf(fptArtistas,"%s,%s,%d\n",diccionarioArtistas[j].indice, diccionarioArtistas[j].palabra, diccionarioArtistas[j].cantidad);
		printf("Indice %d\n", j); 
	}
	printf("Listado de palabras encontradas por genero\n");
	for (unsigned int j = 1; j <= cuenta_palabras_generos; j++){
		fprintf(fptGeneros,"%s,%s,%d\n", diccionarioGeneros[j].indice, diccionarioGeneros[j].palabra, diccionarioGeneros[j].cantidad);
		printf("Indice %d\n", j); 
	}
	fclose(fptArtistas);
	fclose(fptGeneros);
	return(0);
}

//funcion que agrega artista y palabra al diccionarioArtistas
void analiza_palabra_por_artista_encontrada(const char* palabra)
{
	//Bandera para saber si existe la palabra
	bool esta = false;
	//Bandera para saber si existe el indice en este caso artista
	bool esta_indice = false;
	unsigned int posicion = 0;
	char palabra_a_analizar[MAX_LONGITUD];
	strcpy(palabra_a_analizar, palabra);
	//Pasamos todas las palabras a mayusculas para facilidad a la hora de comparar
	for (unsigned int cuenta_palabras_artistas = 0; palabra_a_analizar[cuenta_palabras_artistas] != '\0'; ++cuenta_palabras_artistas)
		palabra_a_analizar[cuenta_palabras_artistas] = toupper(palabra_a_analizar[cuenta_palabras_artistas]);
	//Recorremos el diccionario por cada elemento que tenemos
	for(unsigned int i = 1; i <= cuenta_palabras_artistas; i++){
		//Verificamos que el artista este en esa posicion
		if(!strcmp(diccionarioArtistas[i].indice, artista)){
			//Verificamos que la palabra este en esa posicion de ser asi se almacena la posicion y se cambia la bandera de si existe
			if (!strcmp(diccionarioArtistas[i].palabra, palabra_a_analizar)){
				/*Se vuelve a verificar que en ese elemento se encuentre el mismo artista, esto se hace ya que por la forma en la que esta la estructura 
				ya que cada elemento tiene el artista que le corresponde, la palabra y la cantidad de veces que lo ha dicho, si no se tuviera esa validacion 
				si existiera la palabra en otro artista tomaria esa posicion */
				if(!strcmp(diccionarioArtistas[i].indice, artista))
					{
						esta_indice = true;
					}
				esta = true;
				posicion = i;
				break;
			}
		}
	}

	//Validamos la bandera de si se encuentra el indice
	if(esta_indice){
		// En caso de ser positivo, se valida que la palabra exista
		if(esta){
			//Cuando es positivo se agrega uno a la cantidad
			diccionarioArtistas[posicion].cantidad++;
		}
	}
	//EN caso de que no se encuentre el indice
	else{
		//Se valida el valor del contador de palabra si es menor que uno
		if(cuenta_palabras_artistas <1){
			//Se guarda tanto el artista como la palabra en el indice 0
			strcpy(diccionarioArtistas[0].indice, artista);
			diccionarioArtistas[0].cantidad = 1;
			strcpy(diccionarioArtistas[0].palabra, palabra_a_analizar);
			}
		else{
			//Se guarda tanto el artista como la palabra en el indice en donde este el contaodr
			strcpy(diccionarioArtistas[cuenta_palabras_artistas].indice, artista);
			diccionarioArtistas[cuenta_palabras_artistas].cantidad = 1;
			strcpy(diccionarioArtistas[cuenta_palabras_artistas].palabra, palabra_a_analizar);
			}
		//Aumentamos el contador
		cuenta_palabras_artistas++;
	}
}

//funcion que agrega genero y palabra al diccionarioGenero
void analiza_palabra_por_genero_encontrada(const char* palabra)
{
	//Bandera para saber si existe la palabra
	bool esta = false;
	//Bandera para saber si existe el indice en este caso artista
	bool esta_indice = false;
	unsigned int posicion = 0;
	char palabra_a_analizar[MAX_LONGITUD];
	strcpy(palabra_a_analizar, palabra);
	//Pasamos todas las palabras a mayusculas para facilidad a la hora de comparar
	for (unsigned int cuenta_palabras_generos = 0; palabra_a_analizar[cuenta_palabras_generos] != '\0'; ++cuenta_palabras_generos)
		palabra_a_analizar[cuenta_palabras_generos] = toupper(palabra_a_analizar[cuenta_palabras_generos]);
	//Recorremos el diccionario por cada elemento que tenemos
	for(unsigned int i = 1; i <= cuenta_palabras_generos; i++){
		//Verificamos que el genero este en esa posicion
		if(!strcmp(diccionarioGeneros[i].indice, genero)){
		//Verificamos que la palabra este en esa posicion de ser asi se almacena la posicion y se cambia la bandera de si existe
		if (!strcmp(diccionarioGeneros[i].palabra, palabra_a_analizar)){
			/*Se vuelve a verificar que en ese elemento se encuentre el mismo artista, esto se hace ya que por la forma en la que esta la estructura 
				ya que cada elemento tiene el artista que le corresponde, la palabra y la cantidad de veces que lo ha dicho, si no se tuviera esa validacion 
				si existiera la palabra en otro artista tomaria esa posicion */
			if(!strcmp(diccionarioGeneros[i].indice, genero))
				{
					esta_indice = true;
				}
			esta = true;
			posicion = i;
			break;
		}}
	}
	//Validamos la bandera de si se encuentra el indice
	if(esta_indice){
		// En caso de ser positivo, se valida que la palabra exista
		if(esta){
			//Cuando es positivo se agrega uno a la cantidad
			diccionarioGeneros[posicion].cantidad++;
		}
	}
	//EN caso de que no se encuentre el indice
	else{
		//Se valida el valor del contador de palabra si es menor que uno
		if(cuenta_palabras_generos <1){
			//Se guarda tanto el artista como la palabra en el indice 0
			strcpy(diccionarioGeneros[0].indice, genero);
			diccionarioGeneros[0].cantidad = 1;
			strcpy(diccionarioGeneros[0].palabra, palabra_a_analizar);
			}
		else{
			//Se guarda tanto el artista como la palabra en el indice en donde este el contaodr
			strcpy(diccionarioGeneros[cuenta_palabras_generos].indice, genero);
			diccionarioGeneros[cuenta_palabras_generos].cantidad = 1;
			strcpy(diccionarioGeneros[cuenta_palabras_generos].palabra, palabra_a_analizar);
			}
		//Aumentamos el contador
		cuenta_palabras_generos++;
	}
}

//Funcion que analiza el indice de canciones para poder guardar el genero y la palabra en variable y usarla en las demas funciones
void analiza_indice_canciones(const char* palabra)
{
	switch(bandera){
		case 1:
			strcpy(genero, palabra);
			break;
		case 2:
			strcpy(artista, palabra);
			break;
		case 3:
			bandera = 0;
		default:
			break;
	}
}

//Se ordena por metodo burbuja sin embargo no es practico ya que la lomgitud de los diccinarios es muy grande que hace que se lleve horas en acabar un diccionario
void ordena_diccionarios(void)
{
	elemento elemento_temporal;
	unsigned int contador=0;
	unsigned int contador1=0;

	for (unsigned int i = 1; i <= cuenta_palabras_artistas - 1; i++)
		for (unsigned int j = i+1; j <= cuenta_palabras_artistas; j++)
			if(!strcmp(diccionarioArtistas[i].indice,diccionarioArtistas[j].indice)){
			if (strcmp(diccionarioArtistas[i].palabra, diccionarioArtistas[j].palabra) > 0)
			{
				printf("Artista %d vez", contador);
				elemento_temporal = diccionarioArtistas[i];
				diccionarioArtistas[i] = diccionarioArtistas[j];
				diccionarioArtistas[j] = elemento_temporal;
				contador++;
			}
			}
	for (unsigned int i = 1; i <= cuenta_palabras_generos - 1; i++)
		for (unsigned int j = i+1; j <= cuenta_palabras_generos; j++)
			if(!strcmp(diccionarioGeneros[i].indice,diccionarioGeneros[j].indice)){
			if (strcmp(diccionarioGeneros[i].palabra, diccionarioGeneros[j].palabra) > 0)
			{
				printf("Genero %d vez", contador1);

				elemento_temporal = diccionarioGeneros[i];
				diccionarioGeneros[i] = diccionarioGeneros[j];
				diccionarioGeneros[j] = elemento_temporal;
				contador1;
			}
} 
}