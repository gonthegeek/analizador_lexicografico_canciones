%{
#pragma warning(disable: 4996 6387 6011 6385)
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ctype.h>
#include <wchar.h>
#include <locale.h>

void analiza_palabra_encontrada(const char* palabra);
void ordena_diccionario(void);

#define MAX_PALABRAS 5000
#define MAX_LONGITUD 200

char directorio[MAX_LONGITUD]="";
char archivo_de_entrada[MAX_LONGITUD]="";
char archivo_a_abrir[MAX_LONGITUD]="";

typedef struct 
{
	unsigned int cantidad;
	char palabra[MAX_LONGITUD];
} elemento;

elemento diccionario[MAX_PALABRAS];
unsigned int cuenta_palabras_totales = 0;

#define MAX_INCLUDE_DEPTH 2
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH]; /* PILA para archivos */

unsigned int include_stack_ptr = 0;
%}

%option noyywrap
%option outfile="analizador_lex_canciones.c"


PALABRA [A-ZÑÁÉÍÓÚa-zñáéíóú][A-ZÑÁÉÍÓÚa-zñáéíóú]+

%%

{PALABRA} {
	 	printf("Palabra: %s\n", yytext);
	 	analiza_palabra_encontrada(yytext);
	  }

.       printf("Caracter invalido: %s\n", yytext);
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
	ordena_diccionario();
	printf("Listado de palabras encontradas\n");
	for (unsigned int j = 1; j <= cuenta_palabras_totales; j++)
		printf("% s tiene %d repeticiones en el archivo\n", diccionario[j].palabra, diccionario[j].cantidad);
	printf("\nListado de citas por fecha\n");
	return(0);
}

void analiza_palabra_encontrada(const char* palabra)
{
	bool esta = false;
	unsigned int posicion = 0;
	char palabra_a_analizar[MAX_LONGITUD];
	strcpy(palabra_a_analizar, palabra);
	for (unsigned int indice = 0; palabra_a_analizar[indice] != '\0'; ++indice)
		palabra_a_analizar[indice] = toupper(palabra_a_analizar[indice]);
	for(unsigned int i = 1; i <= cuenta_palabras_totales; i++)
		if (!strcmp(diccionario[i].palabra, palabra_a_analizar))
		{
			esta = true;
			posicion = i;
			break;
		}
	if (esta)
		diccionario[posicion].cantidad++;
	else
	{
		cuenta_palabras_totales++;
		diccionario[cuenta_palabras_totales].cantidad = 1;
		strcpy(diccionario[cuenta_palabras_totales].palabra, palabra_a_analizar);
	}
}

void ordena_diccionario(void)
{
	elemento elemento_temporal;
	for (unsigned int i = 1; i <= cuenta_palabras_totales - 1; i++)
		for (unsigned int j = i+1; j <= cuenta_palabras_totales; j++)
			if (strcmp(diccionario[i].palabra, diccionario[j].palabra) > 0)
			{
				elemento_temporal = diccionario[i];
				diccionario[i] = diccionario[j];
				diccionario[j] = elemento_temporal;
			}
}