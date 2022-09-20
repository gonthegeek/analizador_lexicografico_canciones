%{

int include_stack_ptr = 0;

#pragma warning(disable: 4996 6387 6011 6385)
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ctype.h>
#include <wchar.h>
#include <locale.h>



#define MAX_PALABRAS 5000
#define MAX_LONGITUD 200

unsigned int nivel_de_includes = 0;
char directorio[MAX_LONGITUD]="";
char archivo_de_entrada[MAX_LONGITUD]="";
char archivo_de_entrada1[MAX_LONGITUD]="";
char archivo_a_abrir[MAX_LONGITUD]="";
char archivo_a_abrir1[MAX_LONGITUD]="";
char genero[MAX_LONGITUD]="";
char artista[MAX_LONGITUD]="";
unsigned int bandera = 0;

typedef struct 
{
	char indice[MAX_LONGITUD];
	unsigned int cantidad;
	char palabra[MAX_LONGITUD];
} elemento;

void analiza_palabra_artista_encontrada(const char* palabra);
void analiza_indice(const char* palabra);
/* void ordena_diccionario(elemento* arreglo);
 */
elemento diccionarioGeneros[MAX_PALABRAS];
elemento diccionarioArtistas[MAX_PALABRAS];

unsigned int cuenta_palabras_generos_totales = 0;
unsigned int cuenta_palabras_artistas_totales = 0;
unsigned int cuenta_generos_totales = 0;
unsigned int cuenta_artistas_totales = 0;

#define MAX_INCLUDE_DEPTH 10
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH]; /* PILA para archivos */

%}

%option noyywrap
%option outfile="analizador_lex_canciones.c"

PALABRA             [A-ZÑÁÉÍÓÚa-zñáéíóú][A-ZÑÁÉÍÓÚa-zñáéíóú]+
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
	 	analiza_indice(yytext);
		bandera++;
	  }

{URL} { /* ir a abrir el archivo include */
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
	 	/*printf("Palabra: %s\n", yytext);*/
	 	analiza_palabra_artista_encontrada(yytext);
/* 		analiza_palabra_encontrada(yytext, diccionarioGeneros, genero, cuenta_generos_totales, cuenta_palabras_generos_totales);
 */	  }
","
.       printf("Caracter invalido %s\n",yytext);      
%%

int main( int argc, char* argv[] )
{
    setlocale(LC_ALL, ".UTF8");
	if ( argc == 3 )
	{
		strcpy(directorio, argv[1]);
		strcat(directorio, "\\");
		strcpy(archivo_de_entrada, argv[2]);
		strcpy(archivo_a_abrir, directorio);
		strcat(archivo_a_abrir, archivo_de_entrada);
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
	/*ordena_diccionario(diccionarioArtistas);*/
	printf("Listado de palabras encontradas por artista\n");
	for (unsigned int j = 1; j <= cuenta_palabras_artistas_totales; j++)
		printf("%s dice esta palabra % s un numero de %d veces\n",diccionarioArtistas[j].indice, diccionarioArtistas[j].palabra, diccionarioArtistas[j].cantidad);
	/* printf("Listado de palabras encontradas por genero\n");
	for (unsigned int j = 1; j <= cuenta_palabras_totales; j++)
		printf("En el genero %s , se dice esta palabra % s un numero de %d veces\n",diccionarioGeneros[j].indice, diccionarioGeneros[j].palabra, diccionarioGeneros[j].cantidad); */
	printf("%d\n", cuenta_palabras_artistas_totales);
	return(0);
}

void analiza_palabra_artista_encontrada(const char* palabra)
{
	bool esta = false;
	bool esta_indice = false;
	unsigned int posicion = 0;
	char palabra_a_analizar[MAX_LONGITUD];
	strcpy(palabra_a_analizar, palabra);
	for (unsigned int indice = 0; palabra_a_analizar[indice] != '\0'; ++indice){
		palabra_a_analizar[indice] = toupper(palabra_a_analizar[indice]);

	}
	for(unsigned int i = 1; i <= cuenta_palabras_artistas_totales; i++){
		printf("%d",i);
		if(!strcmp(diccionarioArtistas[i].indice, artista)){
				esta_indice = true;
				posicion = i;
				break;
			}
		else if (!strcmp(diccionarioArtistas[i].palabra, palabra_a_analizar))
		{
			esta = true;
			posicion = i;
			break;
		}
	}	
	if (esta_indice){	
		if (esta){
			diccionarioArtistas[posicion].cantidad++;
		}
		else
		{
			cuenta_palabras_artistas_totales++;
			diccionarioArtistas[cuenta_palabras_artistas_totales].cantidad = 1;
			strcpy(diccionarioArtistas[cuenta_palabras_artistas_totales].palabra, palabra_a_analizar);

		}
	} 
	else
	{
		cuenta_artistas_totales++;
		strcpy(diccionarioArtistas[cuenta_artistas_totales].indice, artista);
	}
	
}

void analiza_indice(const char* palabra)
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

/* void ordena_diccionario(elemento* arreglo)
{
	elemento elemento_temporal;
	for (unsigned int i = 1; i <= cuenta_palabras_totales - 1; i++)
		for (unsigned int j = i+1; j <= cuenta_palabras_totales; j++)
			if (strcmp(arreglo[i].palabra, arreglo[j].palabra) > 0)
			{
				elemento_temporal = arreglo[i];
				arreglo[i] = arreglo[j];
				arreglo[j] = elemento_temporal;
			}
	printf("hola");
} */