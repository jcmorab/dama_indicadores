*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de NOES
*Última modificación: 03/05/2026

**#1. Declaración de carpeta de trabajo
clear all
cd "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos" // Directorio para ser modificado

* Txt
clear all
cd "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos"
local files: dir "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos" files "*.txt"

foreach file in `files' {
import delimited "`file'", clear
	contract ano codptore codmunre peso_nac
	destring ano codptore codmunre peso_nac,replace
	save "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\output\muni_`file'.dta",replace
}

* CSV
clear all
cd "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos"
local files: dir "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos" files "*.csv"

foreach file in `files' {
import delimited "`file'", clear
	contract ano codptore codmunre peso_nac
	destring ano codptore codmunre peso_nac,replace
	save "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\output\muni_`file'.dta",replace
}

* DTA
clear all
cd "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos"
local files: dir "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos" files "*.dta"

foreach file in `files' {
	use "`file'", clear
	renvars,lower
	contract ano codptore codmunre peso_nac
	destring ano codptore codmunre peso_nac,replace
	save "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\output\muni_`file'.dta",replace
}

*Ensamble
cd "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\output"
use muni_nac_2024.dta.dta,clear
g drop=1
fs *.dta
append using `r(files)'
drop if drop==1
drop drop

g bajo_peso    =_freq if peso_nac<=4
g bajo_peso_mzl=_freq if peso_nac<=4 & codptore==17 & codmunre==1
g nac=_freq
g nac_mzl=_freq if codptore==17 & codmunre==1

collapse (sum) bajo_peso bajo_peso_mzl nac nac_mzl,by(ano)



keep if ano>=2005 & ano<=2025

merge m:1 codptore codmunre using "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\etiquetas_mpio.dta" 
drop if _merge==2
drop _merge
rename _freq nacimientos

*Municipios
preserve 
keep if cod_dane_s!=""
merge 1:1 ano cod_dane_s using "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\mpio_poblacion_15_49.dta"
drop if _merge==2
drop _merge
g tasa_nacimiento=(nacimiento/mujer_15_49)*1000
keep dpto mpio ano nacimiento mujer_15_49 tasa_nacimiento
order ano dpto mpio nacimientos mujer_15_49 tasa_nacimiento
compress
renvars nacimientos mujer_15_49 tasa_nacimiento,prefix(i_)
g id=_n
reshape long i_,i(id)j(indicador)string
g unidad="N° nacimientos" if indicador=="nacimientos"
replace unidad="N° mujeres" if indicador=="mujer_15_49"
replace unidad="Tasa x 1.000 mujeres" if indicador=="tasa_nacimiento"

replace indicador="Nacimientos" if indicador=="nacimientos"
replace indicador="N° mujeres entre 15 y 49 años" if indicador=="mujer_15_49"
replace indicador="Tasa de fecundidad" if indicador=="tasa_nacimiento"
drop id
rename i_ valor
order ano dpto mpio indicador unidad valor
sort dpto mpio indicador ano
export excel using "C:\Users\juanc\OneDrive\Gobernación\2024 - 2027\Dashboards\Boletines dinámicos\Natalidad\datos_tablero.xlsx",sheet("mpios",replace) firstrow(variables)
restore

*Departamentos
preserve 
collapse (sum) nacimientos,by(ano codptore)
merge 1:1 ano codptore using "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\dpto_poblacion_15_49.dta"
drop if _merge==2
drop _merge
merge m:1 codptore using "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\etiquetas_dpto.dta"
g tasa_nacimiento=(nacimiento/mujer_15_49)*1000
keep dpto ano nacimiento mujer_15_49 tasa_nacimiento
drop if dpto==""

order ano dpto nacimientos mujer_15_49 tasa_nacimiento
compress
renvars nacimientos mujer_15_49 tasa_nacimiento,prefix(i_)
g id=_n
reshape long i_,i(id)j(indicador)string
g unidad="N° nacimientos" if indicador=="nacimientos"
replace unidad="N° mujeres" if indicador=="mujer_15_49"
replace unidad="Tasa x 1.000 mujeres" if indicador=="tasa_nacimiento"

replace indicador="Nacimientos" if indicador=="nacimientos"
replace indicador="N° mujeres entre 15 y 49 años" if indicador=="mujer_15_49"
replace indicador="Tasa de fecundidad" if indicador=="tasa_nacimiento"
drop id
rename i_ valor
order ano dpto indicador unidad valor
sort dpto indicador ano
save consolidado_dpto,replace
restore

*Colombia
preserve 
collapse (sum) nacimientos,by(ano)
merge 1:1 ano using "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\col_poblacion_15_49.dta"
drop if _merge==2
drop _merge

g tasa_nacimiento=(nacimiento/mujer_15_49)*1000
keep ano nacimiento mujer_15_49 tasa_nacimiento

order ano nacimientos mujer_15_49 tasa_nacimiento
compress
renvars nacimientos mujer_15_49 tasa_nacimiento,prefix(i_)
g id=_n
reshape long i_,i(id)j(indicador)string
g unidad="N° nacimientos" if indicador=="nacimientos"
replace unidad="N° mujeres" if indicador=="mujer_15_49"
replace unidad="Tasa x 1.000 mujeres" if indicador=="tasa_nacimiento"

replace indicador="Nacimientos" if indicador=="nacimientos"
replace indicador="N° mujeres entre 15 y 49 años" if indicador=="mujer_15_49"
replace indicador="Tasa de fecundidad" if indicador=="tasa_nacimiento"
drop id
rename i_ valor
order ano indicador unidad valor
sort indicador ano
format %20.0g valor
append using "C:\Users\juanc\OneDrive\MD\EEVV\Nacimientos\consolidado_dpto.dta" 
replace dpto="Colombia" if dpto==""
export excel using "C:\Users\juanc\OneDrive\Gobernación\2024 - 2027\Dashboards\Boletines dinámicos\Natalidad\datos_tablero.xlsx",sheet("dpto",replace) firstrow(variables)
restore
