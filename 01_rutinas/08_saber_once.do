**********************************
*FUNDACIÓN LUKER
*Procesamiento de pruebas Saber 11
*Juan Carlos Mora Betancourt
*juancarlosmorab@outlook.com
*20/05/2025
**********************************

*1. Definición de directorios
*Las rutas se definen en 00_config.do
clear all
if "$dama" == "" {
	display as error "Primero corra 00_config.do"
	exit 198
}
capture mkdir "$trabajo/08_saber_once"
cd "$trabajo/08_saber_once"
set dp period

*2. Creación de base global preliminar
use "$icfes/examen_saber_11_20151.txt.dta",clear
append using "$icfes/examen_saber_11_20152.txt.dta"
keep periodo estu_genero cole_area_ubicacion cole_naturaleza punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_agregado cole_cod_mcpio_ubicacion estu_grado


forvalues i=2016/2025 {
append using "$icfes/examen_saber_11_`i'1.txt.dta",keep(periodo estu_genero cole_area_ubicacion cole_naturaleza punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_agregado cole_cod_mcpio_ubicacion estu_grado)
append using "$icfes/examen_saber_11_`i'2.txt.dta",keep(periodo estu_genero cole_area_ubicacion cole_naturaleza punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_agregado cole_cod_mcpio_ubicacion estu_grado)
}

*3. Selección de ciudades de análisis
rename cole_cod_mcpio_ubicacion cod_dane_n
tostring periodo,gen(Periodo)
gen año=substr(Periodo,1,4)
destring año,replace

keep if estu_agregado=="S"

keep if cod_dane_n==63001 | cod_dane_n==8001 | cod_dane_n==11001 | cod_dane_n==68001 | cod_dane_n==76001 | cod_dane_n==13001 | cod_dane_n==54001 | cod_dane_n==18001 | cod_dane_n==73001 | cod_dane_n==17001 | cod_dane_n==5001 | cod_dane_n==23001 | cod_dane_n==41001 | cod_dane_n==52001 | cod_dane_n==66001 | cod_dane_n==19001 | cod_dane_n==27001 | cod_dane_n==44001 | cod_dane_n==47001 | cod_dane_n==70001 | cod_dane_n==15001 | cod_dane_n==20001 | cod_dane_n==50001

*5. Cálculo de estadísticas descriptivas
g Total="Total"

foreach var of varlist punt_c_naturales punt_global punt_ingles punt_lectura_critica punt_matematicas punt_sociales_ciudadanas {
g s_`var'=`var' if estu_grado!=25 & estu_grado!=26 & estu_grado!=27
g c_`var'=`var' if estu_grado==25 | estu_grado==26 | estu_grado==27
rename `var' t_`var'
}

replace cole_area_ubicacion="URBANO" if cole_area_ubicacion=="URBANA"

*La carpeta de trabajo ya se fijó al inicio

foreach var of varlist Total estu_genero cole_naturaleza cole_area_ubicacion  {
preserve
collapse (mean) t_* s_* c_* ,by(año cod_dane_n `var')
drop if `var'==""
rename `var'  categoria
save "`var'",replace
restore	
}

use Total,clear
append using estu_genero
append using cole_naturaleza
append using cole_area_ubicacion

g id=_n 
reshape long t_punt_ s_punt_ c_punt_, i(id) j(prueba)string
drop id

replace prueba = "SABER_01" if prueba == "c_naturales"
replace prueba = "SABER_02" if prueba == "global"
replace prueba = "SABER_03" if prueba == "ingles"
replace prueba = "SABER_04" if prueba == "lectura_critica"
replace prueba = "SABER_05" if prueba == "matematicas"
replace prueba = "SABER_06" if prueba == "sociales_ciudadanas"

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
keep cod_indicador categoria* anio valor cod_entidad
order cod_indicador categoria* cod_entidad anio valor 
sort cod_indicador categoria* cod_entidad anio valor 
drop if cod_entidad==0

export excel using "$plata/08_saber_once.xlsx",sheet("base",replace)firstrow(variables)

*** FIN
**
*