*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de educación ATAL y UTC
*Última modificación: 07/09/2026

**#1. Declaración de carpeta de trabajo
*Las rutas se definen en 00_config.do
clear all
if "$dama" == "" {
	display as error "Primero corra 00_config.do"
	exit 198
}
capture mkdir "$trabajo/05_atal_utc"
cd "$trabajo/05_atal_utc"

**#2. Procesamientos

**##2.1 Fluidez lectora
import excel "$bronce/luker_fluidez_lectora/FLUIDEZ_LECTURA_ANONIMIZADO.xlsx", sheet("Sheet1") firstrow clear
destring valor grado anio,replace
lab define grado 1"Primero"2"Segundo"3"Tercero"4"Cuarto"5"Quinto"
lab values grado grado

**###2.1.1 Prueba de entrada palabras leidas por minuto & Prueba de salida palabras leidas por minuto

*Instituciones
preserve
collapse valor ,by(prueba anio institucion_educativa grado)

g cod_entidad=17001
g entidad="Manizales"
rename (pruebaesq institucion_educativa grado valor) (indicador categoría categoría_2 dato)

tab indicador
g cod_indicador="ATAL_03" if indicador=="entrada"
replace cod_indicador="ATAL_04" if indicador=="salida"

sort indicador categoría categoría_2 anio
drop indicador
save ATAL_1,replace
restore

*Total
preserve
collapse valor ,by(prueba anio grado)

g cod_entidad=17001
g entidad="Manizales"
rename (pruebaesq grado valor) (indicador categoría_2 dato)
g categoría="Total"

tab indicador
g cod_indicador="ATAL_03" if indicador=="entrada"
replace cod_indicador="ATAL_04" if indicador=="salida"

sort indicador categoría categoría_2 anio
drop indicador
save ATAL_2,replace
restore


**###2.1.2 Estudiantes que alcanzan el nivel estándar o avanzado - Salida & Estudiantes que alcanzan el nivel estándar o avanzado - Entrada

*Instituciones
preserve
g satisfactorio_avanzado=(estandar=="Avanzado"|estandar=="Satisfactorio")
g total_alumnos=1

collapse (sum) satisfactorio total ,by(prueba anio institucion_educativa grado)

g cod_entidad=17001
g entidad="Manizales"
g dato=(satisfactorio_avanzado/total)*100
rename (pruebaesq institucion_educativa grado ) (indicador categoría categoría_2)

tab indicador
g cod_indicador="ATAL_01" if indicador=="entrada"
replace cod_indicador="ATAL_02" if indicador=="salida"

sort indicador categoría categoría_2 anio
drop indicador satisfactorio_avanzado total_alumnos
save ATAL_3,replace
restore

*Total
preserve
g satisfactorio_avanzado=(estandar=="Avanzado"|estandar=="Satisfactorio")
g total_alumnos=1

collapse (sum) satisfactorio total ,by(prueba anio grado)
g categoría="Total"

g cod_entidad=17001
g entidad="Manizales"
g dato=(satisfactorio_avanzado/total)*100
rename (pruebaesq grado ) (indicador categoría_2)

tab indicador
g cod_indicador="ATAL_01" if indicador=="entrada"
replace cod_indicador="ATAL_02" if indicador=="salida"

sort indicador categoría categoría_2 anio
drop indicador satisfactorio_avanzado total_alumnos
save ATAL_4,replace
restore

**##2.2 Universidad en tu colegio
import excel "$bronce/luker_utc/bd_historica_utc.xlsx", sheet("Sheet1") firstrow clear
keep año categoría dato indicador categoría2
rename (año categoría dato indicador categoría2) ( ano categoría dato indicador categoría_2)
save UTC_historico,replace

import excel "$bronce/luker_utc/LA_U_EN_TU_COLEGIO_ANONIMIZADO.xlsx", sheet("Sheet1") firstrow clear

preserve
g dato=1
collapse (sum) dato,by(ano institucion_educativa)
rename institucion_educativa categoría
g indicador="Matrícula técnica UTC por institución educativa"
g categoría_2="Colegio"
save UTC_1,replace
restore

preserve
g dato=1
collapse (sum) dato,by(ano x_institucion_de_educacion_super)
rename x_institucion_de_educacion_super categoría
g indicador="Matrícula técnica UTC por institución educativa"
g categoría_2="Universidad / Instituto técnico o tecnológico"
save UTC_2,replace
restore

preserve
g dato=1
collapse (sum) dato,by(ano programa_tecnico)
rename programa_tecnico categoría
g indicador="Matrícula técnica UTC por programa"
g categoría_2="Na"
save UTC_3,replace
restore

use UTC_1,clear
append using UTC_2
append using UTC_3
append using UTC_historico

tab indicador
g cod_indicador="UTC_02" if indicador=="Matrícula técnica UTC por institución educativa"
replace cod_indicador="UTC_03" if indicador=="Matrícula técnica UTC por programa"
replace categoría_2="" if categoría_2=="Na"
g cod_entidad=17001
g entidad="Manizales"

rename (ano) (anio)
sort indicador categoría categoría_2 anio
drop indicador

save UTC_total,replace
erase UTC_1.dta 
erase UTC_2.dta 
erase UTC_3.dta
erase UTC_historico.dta

**#3 Exporte de indicadores
use ATAL_1,clear
append using ATAL_2
append using ATAL_3
append using ATAL_4
decode categoría_2,gen(x)
drop categoría_2
rename x categoría_2
order categoría_2,a(categoría)
append using UTC_total
rename (categoría categoría_2 dato) (categoria categoria_2 valor)
order cod_indicador categoria categoria_2 cod_entidad entidad anio valor
compress
dropmiss,force
export excel using "$plata/05_atal_utc.xlsx",sheet("base",replace)firstrow(variables)

*** FIN
**
*