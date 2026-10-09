*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de cobertura del MEN
*Última modificación: 03/05/2026

**#1. Declaración de carpeta de trabajo
*Las rutas se definen en 00_config.do
clear all
if "$dama" == "" {
	display as error "Primero corra 00_config.do"
	exit 198
}
capture mkdir "$trabajo/02_tasa_transito"
cd "$trabajo/02_tasa_transito"

**#2. Procesamientos
local files: dir "$bronce/men_transito" files "*.xlsx"

foreach file in `files' {
import excel "$bronce/men_transito/`file'", sheet("TTI_MUNICIPIOS") allstring clear
keep if C!=""

ds
local usados
foreach v in `r(varlist)' {
    local x = ustrregexra(ustrlower(ustrregexra(ustrnormalize(strtrim(`v'[1]),"nfd"),"\p{Mark}","")),"[^a-z0-9]+","_")
    local x = ustrregexra("`x'","^_|_$","")
    if regexm("`x'","^[0-9]") local x = "v_`x'"
    local x = substr("`x'",1,32)
    local b "`x'"
    local i=1
    while `: list x in usados' {
        local ++i
        local x = substr("`b'",1,30)+"_`i'"
    }
    local usados `usados' `x'
    rename `v' `x'
}

g codigo="`file'.dta"
drop in 1
destring _all, replace ignore(",") force
keep codigo cod_municipio tasa*
g id=_n
reshape long tasa_de_transito_inmediato_,i(id)j(anio)
drop id
save "`file'.dta", replace

clear
}

use amazonas.xlsx.dta,clear
g drop=1
fs *.dta
append using `r(files)'
drop if drop==1
drop drop
compress
drop codigo

rename tasa valor
rename cod_municipio cod_entidad
keep if cod_entidad==63001 | cod_entidad==8001 | cod_entidad==11001 | cod_entidad==68001 | cod_entidad==76001 | cod_entidad==13001 | cod_entidad==54001 | cod_entidad==18001 | cod_entidad==73001 | cod_entidad==17001 | cod_entidad==5001 | cod_entidad==23001 | cod_entidad==41001 | cod_entidad==52001 | cod_entidad==66001 | cod_entidad==19001 | cod_entidad==27001 | cod_entidad==44001 | cod_entidad==47001 | cod_entidad==70001 | cod_entidad==15001 | cod_entidad==20001 | cod_entidad==50001

replace valor=valor*100

g cod_indicador="COBE_06"
g categoria="Total"
g categoria_2=""

keep cod_indicador categoria* anio valor cod_entidad
order cod_indicador categoria* cod_entidad anio valor 
sort cod_indicador categoria* cod_entidad anio valor 

export excel using "$plata/02_tasa_transito.xlsx",sheet("base",replace)firstrow(variables)

*** FIN
**
*