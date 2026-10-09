*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de beneficiarios de programas de educación
*Última modificación: 07/09/2026

**#1. Declaración de carpeta de trabajo
clear all
cd "C:\Users\juanc\OneDrive\Luker\2026\Sistema M&E\Rutinas\9_beneficiarios" // Directorio para ser modificado

import delimited "df_utc_anonimizado.csv",clear
tab ano
duplicates report ano id_anonimo

import excel "df_egra_manizales_anonimizado.xlsx", sheet("Sheet1") firstrow clear
keep if prueba=="entrada"
duplicates report ano id_anonimo
keep if calificador=="Lectura Pasaje"
tab ano

import excel "df_beneficiarios.xlsx", sheet("Sheet1") firstrow clear
destring valor grado anio,replace
lab define grado 1"Primero"2"Segundo"3"Tercero"4"Cuarto"5"Quinto"
lab values grado grado

***
**
*