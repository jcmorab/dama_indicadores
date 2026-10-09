*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de trabajo no remunerado (jóvenes de 15 a 28 años)
*Última modificación: 22/09/2026

*TNR_01: % de jóvenes que realizaron al menos una actividad de trabajo doméstico no remunerado en su hogar
*        (p3076 cocinar, lavar platos, poner la mesa · p3077 ropa · p3078 limpieza y mantenimiento)
*TNR_02: % de jóvenes que realizaron al menos una actividad de cuidado no remunerado en su hogar
*        (p3079 niños menores de 5 años · p3081 personas enfermas, con discapacidad o mayores · p3082 tareas escolares)

**#1. Declaración de carpeta de trabajo
clear all
cd "C:\Users\juanc\OneDrive\Luker\2026\Sistema M&E\Rutinas\10_uso_tiempo" // Directorio para ser modificado

**#2. Procesamientos

forvalues i=2021/2025  {
use "C:\Users\juanc\OneDrive\MD\GEIH\Archivos planos\bd`i'\GEIH_`i'_ampliada.dta",clear

g año=`i'
keep if p6040>=15 & p6040<=28

recode p3076s1 p3077s1 p3078s1 p3079s1 p3081s1 p3082s1 (1=100) (2=0) (else=.)

egen tnr01=rowmax(p3076s1 p3077s1 p3078s1)
egen tnr02=rowmax(p3079s1 p3081s1 p3082s1)

rename area cod_dane
destring cod_dane,replace force

foreach var of varlist tnr01 tnr02 {
	clonevar `var'_h=`var' if p3271==1
	clonevar `var'_m=`var' if p3271==2
}

collapse (mean) tnr01 tnr01_h tnr01_m tnr02 tnr02_h tnr02_m [pw=fex_c18/12],by(año cod_dane)

drop if cod_dane>80

renvars tnr*,prefix(codigo_)

g id=_n
reshape long codigo_,i(id)j(variable)string

g categoria="Total"
replace categoria="Hombre" if regexm(variable, "_h")
replace categoria="Mujer" if regexm(variable, "_m")

g       cod_indicador="TNR_01" if regexm(variable, "tnr01")
replace cod_indicador="TNR_02" if regexm(variable, "tnr02")

keep año cod_dane codigo_ categoria cod_indicador

save "TNR_`i'.dta",replace
}

use "TNR_2021.dta",clear
g drop=1
fs TNR_*.dta
append using `r(files)'
drop if drop==1
drop drop
replace cod_dane=cod_dane*1000+1

rename año anio
rename codigo_ valor
rename cod_dane cod_entidad

keep cod_indicador categoria anio valor cod_entidad
order cod_indicador categoria cod_entidad anio valor
sort cod_indicador categoria cod_entidad anio valor

export excel using "Indicadores FunLuker - trabajo no remunerado.xlsx", sheet("base",replace) firstrow(variables)

*** FIN
**
*

