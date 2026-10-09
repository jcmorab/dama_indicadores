*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de NOES
*Última modificación: 03/05/2026

**#1. Declaración de carpeta de trabajo
clear all
cd "C:\Users\juanc\OneDrive\Luker\2026\Sistema M&E\Rutinas\3_noes" // Directorio para ser modificado

**#2. Procesamientos

forvalues i=2021/2025  {

use "C:\Users\juanc\OneDrive\MD\GEIH\Archivos planos\bd`i'\GEIH_`i'_ampliada.dta",clear

g año=`i'
g población=1

g jovenes=1 if (p6040>=15 & p6040<=28)
g jovenes_14_17=1 if (p6040>=14 & p6040<=17)

g joven_hombre=1 if (p6040>=15 & p6040<=28) & p3271==1
g joven_hombre_14_17=1 if (p6040>=14 & p6040<=17) & p3271==1

g joven_mujer=1 if (p6040>=15 & p6040<=28) & p3271==2
g joven_mujer_14_17=1 if (p6040>=14 & p6040<=17) & p3271==2

g noe=1 if (((dsi==1 | fft==1) & p6170==2) & jovenes==1) & jovenes==1
g noe_hombre=1 if (((dsi==1 | fft==1) & p6170==2) & p3271==1) & jovenes==1
g noe_mujer=1 if (((dsi==1 | fft==1) & p6170==2) & p3271==2) & jovenes==1

g noe_14_17=1 if (((dsi==1 | fft==1) & p6170==2) & jovenes==1) & jovenes_14_17==1
g noe_hombre_14_17=1 if (((dsi==1 | fft==1) & p6170==2) & p3271==1) & jovenes_14_17==1
g noe_mujer_14_17=1 if (((dsi==1 | fft==1) & p6170==2) & p3271==2) & jovenes_14_17==1

rename area cod_dane
destring cod_dane,replace force
collapse (sum) población joven* noe* [pw=fex_c18/12],by(año cod_dane)

g per_total=(noe/ jovenes)*100
g per_hombre=(noe_hombre/ joven_hombre)*100
g per_mujer=(noe_mujer/ joven_mujer)*100

g per_total_14_17=(noe_14_17/ jovenes_14_17)*100
g per_hombre_14_17=(noe_hombre_14_17/ joven_hombre_14_17)*100
g per_mujer_14_17=(noe_mujer_14_17/ joven_mujer_14_17)*100

drop if cod_dane>80
g cod_indicador="MLJ_10"
keep año cod_dane noe* per*
renvars noe* per*,prefix(codigo_)

g id=_n
reshape long codigo_,i(id)j(variable)string

g categoria="Total"
replace categoria="Hombre" if variable=="per_hombre" | variable=="noe_hombre" | variable=="noe_hombre_14_17"| variable=="per_hombre_14_17"
replace categoria="Mujer" if variable=="per_mujer" | variable=="noe_mujer"| variable=="noe_mujer_14_17"| variable=="per_mujer_14_17"

g cod_indicador="MLJ_10" if variable=="per_hombre" | variable=="per_mujer" | variable=="per_total"| variable=="per_total_14_17"|variable=="per_hombre_14_17"|variable=="per_mujer_14_17"

replace cod_indicador="MLJ_11" if variable=="noe_hombre" | variable=="noe_mujer" | variable=="noe"|variable=="noe_hombre_14_17" | variable=="noe_mujer_14_17" | variable=="noe_14_17"

g categoria2="14 - 17" if regexm(variable, "14_17")
replace categoria2="15 - 28" if categoria2==""

save "NOE_`i'.dta",replace
}

use "NOE_2021.dta",clear
g drop=1
fs *.dta
append using `r(files)'
drop if drop==1
drop drop
replace cod_dane=cod_dane*1000+1
order cod_indicador,b(cod_dane)
drop id variable
rename categoria2 categoria_2

rename año anio
rename codigo_ valor
rename cod_dane cod_entidad

keep cod_indicador categoria* anio valor cod_entidad
order cod_indicador categoria* cod_entidad anio valor 
sort cod_indicador categoria* cod_entidad anio valor 
drop if cod_entidad==0

export excel using "Indicadores FunLuker - noes.xlsx", sheet("base",replace) firstrow(variables)

*** FIN
**
*