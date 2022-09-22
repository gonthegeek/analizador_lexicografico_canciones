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



#define MAX_PALABRAS 15000
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

FILE *fptArtistas;
FILE *fptGeneros;

unsigned int cuenta_palabras_generos=0;
unsigned int cuenta_palabras_artistas=0;
unsigned int cuenta_palabras_generos_totales=0;
unsigned int cuenta_palabras_artistas_totales=0;


typedef struct 
{
	char indice[MAX_LONGITUD];
	unsigned int cantidad;
	char palabra[MAX_LONGITUD];
} elemento;

void analiza_palabra_por_artista_encontrada(const char* palabra);
void analiza_palabra_por_genero_encontrada(const char* palabra);
void analiza_indice_canciones(const char* palabra);
void ordena_diccionarios(void);

elemento diccionarioGeneros[MAX_PALABRAS];
elemento diccionarioArtistas[MAX_PALABRAS];



#define MAX_INCLUDE_DEPTH 10
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
	 	analiza_indice_canciones(yytext);
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
	 	//printf("Palabra: %s\n", yytext);
	 	analiza_palabra_por_artista_encontrada(yytext);
		analiza_palabra_por_genero_encontrada(yytext);
  }
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
	fptArtistas=fopen("ListadoArtistas.csv", "a+");
	fprintf(fptArtistas,"Artista,Palabra,Cantidad\n");
	fptGeneros=fopen("ListadoGeneros.csv", "a+");
	fprintf(fptGeneros,"Genero,Palabra,Cantidad\n");
	/*printf("\nOrdenando diccionario\nOrdenando");
	ordena_diccionarios(); */
	printf("\nListado de palabras encontradas por artista\n");
	for (unsigned int j = 1; j <= cuenta_palabras_artistas; j++){
		fprintf(fptArtistas,"%s,%s,%d\n",diccionarioArtistas[j].indice, diccionarioArtistas[j].palabra, diccionarioArtistas[j].cantidad);
		printf("Indice %d", j); 
	}
	printf("Listado de palabras encontradas por genero\n");
	for (unsigned int j = 1; j <= cuenta_palabras_generos; j++){
		fprintf(fptGeneros,"%s,%s,%d\n", diccionarioGeneros[j].indice, diccionarioGeneros[j].palabra, diccionarioGeneros[j].cantidad);
		printf("Indice %d", j); 
	}
	fclose(fptArtistas);
	fclose(fptGeneros);
	return(0);
}

void analiza_palabra_por_artista_encontrada(const char* palabra)
{
	bool esta = false;
	bool esta_indice = false;
	unsigned int posicion = 0;
	char palabra_a_analizar[MAX_LONGITUD];
	strcpy(palabra_a_analizar, palabra);
	for (unsigned int cuenta_palabras_artistas = 0; palabra_a_analizar[cuenta_palabras_artistas] != '\0'; ++cuenta_palabras_artistas)
		palabra_a_analizar[cuenta_palabras_artistas] = toupper(palabra_a_analizar[cuenta_palabras_artistas]);
	for(unsigned int i = 1; i <= cuenta_palabras_artistas; i++){
		if(!strcmp(diccionarioArtistas[i].indice, artista)){
		if (!strcmp(diccionarioArtistas[i].palabra, palabra_a_analizar)){
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

	if(esta_indice){
		if(esta){
			diccionarioArtistas[posicion].cantidad++;
		}
	}
	else{
		if(cuenta_palabras_artistas <1){
			strcpy(diccionarioArtistas[0].indice, artista);
			diccionarioArtistas[0].cantidad = 1;
			strcpy(diccionarioArtistas[0].palabra, palabra_a_analizar);
			}
		else{
			strcpy(diccionarioArtistas[cuenta_palabras_artistas].indice, artista);
			diccionarioArtistas[cuenta_palabras_artistas].cantidad = 1;
			strcpy(diccionarioArtistas[cuenta_palabras_artistas].palabra, palabra_a_analizar);
			}
		cuenta_palabras_artistas++;
	}
}

void analiza_palabra_por_genero_encontrada(const char* palabra)
{
	bool esta = false;
	bool esta_indice = false;
	unsigned int posicion = 0;
	char palabra_a_analizar[MAX_LONGITUD];
	strcpy(palabra_a_analizar, palabra);
	for (unsigned int cuenta_palabras_generos = 0; palabra_a_analizar[cuenta_palabras_generos] != '\0'; ++cuenta_palabras_generos)
		palabra_a_analizar[cuenta_palabras_generos] = toupper(palabra_a_analizar[cuenta_palabras_generos]);
	for(unsigned int i = 1; i <= cuenta_palabras_generos; i++){
					
		if(!strcmp(diccionarioGeneros[i].indice, genero)){
		if (!strcmp(diccionarioGeneros[i].palabra, palabra_a_analizar)){
			if(!strcmp(diccionarioGeneros[i].indice, genero))
				{
					esta_indice = true;
				}
			esta = true;
			posicion = i;
			break;
		}}
	}

	if(esta_indice){
		if(esta){
			diccionarioGeneros[posicion].cantidad++;
		}
	}
	else{
		if(cuenta_palabras_generos <1){
			strcpy(diccionarioGeneros[0].indice, genero);
			diccionarioGeneros[0].cantidad = 1;
			strcpy(diccionarioGeneros[0].palabra, palabra_a_analizar);
			}
		else{
			strcpy(diccionarioGeneros[cuenta_palabras_generos].indice, genero);
			diccionarioGeneros[cuenta_palabras_generos].cantidad = 1;
			strcpy(diccionarioGeneros[cuenta_palabras_generos].palabra, palabra_a_analizar);
			}
		cuenta_palabras_generos++;
	}
}

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

void ordena_diccionarios(void)
{
	elemento elemento_temporal;
	for (unsigned int i = 1; i <= cuenta_palabras_artistas - 1; i++)
		for (unsigned int j = i+1; j <= cuenta_palabras_artistas; j++)
			if (strcmp(diccionarioArtistas[i].palabra, diccionarioArtistas[j].palabra) > 0)
			{
				printf(".");
				elemento_temporal = diccionarioArtistas[i];
				diccionarioArtistas[i] = diccionarioArtistas[j];
				diccionarioArtistas[j] = elemento_temporal;
			}
	for (unsigned int i = 1; i <= cuenta_palabras_generos - 1; i++)
		for (unsigned int j = i+1; j <= cuenta_palabras_generos; j++)
			if (strcmp(diccionarioGeneros[i].palabra, diccionarioGeneros[j].palabra) > 0)
			{
				elemento_temporal = diccionarioGeneros[i];
				diccionarioGeneros[i] = diccionarioGeneros[j];
				diccionarioGeneros[j] = elemento_temporal;
			}
} 