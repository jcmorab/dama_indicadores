*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de la GEIH
*Última modificación: 05/05/2026

**#1. Declaración de carpeta de trabajo
clear all
cd "C:\Users\juanc\OneDrive\Luker\2026\Sistema M&E\Rutinas\6_socioemocionales" // Directorio para ser modificado

**#2. Importe de bases de datos

import delimited using "pri.csv", clear varnames(1) stringcols(_all) encoding("UTF-8")
g nivel="primaria"
save primaria,replace

import delimited using "sec.csv", clear varnames(1) stringcols(_all) encoding("UTF-8")
g nivel="secundaria"
save secundaria,replace

import delimited using "med.csv", clear varnames(1) stringcols(_all) encoding("UTF-8")
g nivel="media"
save media,replace

use primaria, clear
append using secundaria
append using media

destring tri*,replace force
renvars tri*,prefix(prueba_)
g id=_n
reshape long prueba_,i(id)j(valor)string
drop if prueba_==.

replace valor = "Perseverancia"                     if valor == "tri_gr"
replace valor = "Regulación emocional"             if valor == "tri_re"
replace valor = "Autoeficacia académica"           if valor == "tri_aa"
replace valor = "Autopercepción general"           if valor == "tri_ag"
replace valor = "Acoso escolar"                    if valor == "tri_b"
replace valor = "Agresión escolar"                 if valor == "tri_ae"
replace valor = "Diversidad acciones"              if valor == "tri_da"
replace valor = "Diversidad actitudes"             if valor == "tri_dp"
replace valor = "Empatía"                          if valor == "tri_e"
replace valor = "Género"                           if valor == "tri_ge"
replace valor = "Asertividad"                      if valor == "tri_a"
replace valor = "Conducta prosocial"               if valor == "tri_cp"
replace valor = "Intimidad en la amistad"          if valor == "tri_ia"
replace valor = "Sentido de pertenencia con pares" if valor == "tri_pp"
replace valor = "Trabajo en equipo"                if valor == "tri_te"
replace valor = "Proyecto de vida"                 if valor == "tri_pv"
replace valor = "Seguimiento de la ley"            if valor == "tri_sl"
replace valor = "Toma de decisiones responsables"  if valor == "tri_dr"

**#3. Procesamientos

* Estado de habilidad
gen esthabilidad = ""
replace esthabilidad = "En riesgo (<= 45)"     if prueba_ <= 45
replace esthabilidad = "En proceso (45 - 55)"    if prueba_ > 45 & prueba_ <= 55
replace esthabilidad = "Prosperando (+55)"   if prueba_ > 55

sort esthabilidad valor 
contract grado valor esthabilidad
bys valor grado : egen total=sum(_freq)

rename valor indicador
rename grado categoria
rename est categoria_2
replace _freq=(_freq/total)*100

replace categoria="Decimo (10°)" if categoria=="10"
replace categoria="Once (11°)" if categoria=="11"
replace categoria="Cuarto (4°)" if categoria=="4"
replace categoria="Quinto (5°)" if categoria=="5"

g cod_entidad=17001
rename _ valor
g anio=2025
keep indicador categoria* anio valor cod_entidad
order indicador categoria* cod_entidad anio valor 
*sort cod_indicador categoria* cod_entidad anio valor 

export excel using "Indicadores FunLuker - socioemocionales.xlsx", sheet("base",replace) firstrow(variables)

***
**
*