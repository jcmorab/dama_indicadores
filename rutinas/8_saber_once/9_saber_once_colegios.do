**********************************
*FUNDACIÓN LUKER
*Procesamiento de pruebas Saber 11
*Juan Carlos Mora Betancourt
*juancarlosmorab@outlook.com
*20/05/2025
**********************************

*1. Definición de directorios
clear all
cd "C:\Users\juanc\OneDrive\MD\ICFES"
set dp period

*2. Creación de base global preliminar
use "examen_saber_11_20151.txt.dta",clear
append using "examen_saber_11_20152.txt.dta"
keep cole_cod_dane_establecimiento cole_nombre_establecimiento periodo estu_genero cole_area_ubicacion cole_naturaleza punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_agregado cole_cod_mcpio_ubicacion estu_grado


forvalues i=2016/2025 {
append using "examen_saber_11_`i'1.txt.dta",keep(cole_cod_dane_establecimiento cole_nombre_establecimiento periodo estu_genero cole_area_ubicacion cole_naturaleza punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_agregado cole_cod_mcpio_ubicacion estu_grado)
append using "examen_saber_11_`i'2.txt.dta",keep(cole_cod_dane_establecimiento cole_nombre_establecimiento periodo estu_genero cole_area_ubicacion cole_naturaleza punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_agregado cole_cod_mcpio_ubicacion estu_grado)
}

*3. Selección de ciudades de análisis
rename cole_cod_mcpio_ubicacion cod_dane_n
tostring periodo,gen(Periodo)
gen año=substr(Periodo,1,4)
destring año,replace

keep if estu_agregado=="S"

keep if cod_dane_n==17001 

drop cod_dane_n 
rename cole_cod_dane_establecimiento cod_dane_n
rename cole_nombre_establecimiento entidad

*5. Cálculo de estadísticas descriptivas
g Total="Total"

foreach var of varlist punt_c_naturales punt_global punt_ingles punt_lectura_critica punt_matematicas punt_sociales_ciudadanas {
g s_`var'=`var' if estu_grado!=25 & estu_grado!=26 & estu_grado!=27
g c_`var'=`var' if estu_grado==25 | estu_grado==26 | estu_grado==27
rename `var' t_`var'
}

replace cole_area_ubicacion="URBANO" if cole_area_ubicacion=="URBANA"

cd "C:\Users\juanc\OneDrive\Luker\2026\Sistema M&E\Rutinas\8_saber_once"

foreach var of varlist Total estu_genero cole_naturaleza cole_area_ubicacion  {
preserve
collapse (mean) t_* s_* c_* ,by(año cod_dane_n entidad `var')
drop if `var'==""
rename `var'  categoria
save "`var'_col",replace
restore	
}

use Total_col,clear
append using estu_genero_col
append using cole_naturaleza_col
append using cole_area_ubicacion_col
format %20.0g cod_dane_n

g id=_n 
reshape long t_punt_ s_punt_ c_punt_, i(id) j(prueba)string
drop id

replace prueba = "SABER_08" if prueba == "c_naturales"
replace prueba = "SABER_09" if prueba == "global"
replace prueba = "SABER_10" if prueba == "ingles"
replace prueba = "SABER_11" if prueba == "lectura_critica"
replace prueba = "SABER_12" if prueba == "matematicas"
replace prueba = "SABER_13" if prueba == "sociales_ciudadanas"

renvars t_punt_ s_punt_ c_punt_,prefix(cat_)
g id=_n 
reshape long cat_, i(id) j(categoria_2)string
drop id

replace categoria_2="Solo ciclos" if categoria_2=="c_punt_"
replace categoria_2="Solo once" if categoria_2=="s_punt_"
replace categoria_2="Total" if categoria_2=="t_punt_"

replace categoria="Mujer" if categoria=="F"
replace categoria="Hombre" if categoria=="M"
replace categoria="No oficial" if categoria=="NO OFICIAL"
replace categoria="Oficial" if categoria=="OFICIAL"
replace categoria="Rural" if categoria=="RURAL"
replace categoria="Urbano" if categoria=="URBANO"

rename año anio
destring anio,replace
rename prueba cod_indicador
rename cod_dane_n cod_entidad
rename cat_ valor
drop if valor==.
keep cod_indicador categoria* anio valor cod_entidad entidad
order cod_indicador categoria* cod_entidad entidad anio valor 
sort cod_indicador categoria* cod_entidad entidad anio valor 
drop if cod_entidad==0

export excel using "Indicadores FunLuker - saber_once_colegios.xlsx",sheet("base",replace)firstrow(variables)

*** FIN
**
*