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
capture mkdir "$trabajo/1_coberturas_men"
cd "$trabajo/1_coberturas_men"

**#2. Procesamientos

**##2.1 Selección de variables de interés
import excel "$bronce/men_coberturas/MEN_ESTADISTICAS_EN_EDUCACION_EN_PREESCOLAR,_BÁSICA_Y_MEDIA_POR_MUNICIPIO_20260511.xlsx", sheet("Data") firstrow clear

keep AÑO CÓDIGO_MUNICIPIO COBERTURA_NETA_TRANSICIÓN COBERTURA_NETA_PRIMARIA COBERTURA_NETA_SECUNDARIA COBERTURA_NETA_MEDIA DESERCIÓN

**##2.2 Organización de base de datos
renvars COBERTURA_NETA_TRANSICIÓN COBERTURA_NETA_PRIMARIA COBERTURA_NETA_SECUNDARIA COBERTURA_NETA_MEDIA DESERCIÓN,prefix(valor)

g id=_n
reshape long valor,i(id)j(cod_indicador)string
drop id
replace cod_indicador="COBE_01" if  cod_indicador=="COBERTURA_NETA_MEDIA"
replace cod_indicador="COBE_02" if  cod_indicador=="COBERTURA_NETA_TRANSICIÓN"
replace cod_indicador="COBE_03" if  cod_indicador=="COBERTURA_NETA_PRIMARIA"
replace cod_indicador="COBE_04" if  cod_indicador=="COBERTURA_NETA_SECUNDARIA"
replace cod_indicador="COBE_05" if  cod_indicador=="DESERCIÓN"
destring CÓDIGO_MUNICIPIO,gen(cod_entidad)

g categoria="Total"
g categoria_2=""

rename AÑO anio
destring anio,replace
keep cod_indicador categoria* anio valor cod_entidad
order cod_indicador categoria* cod_entidad anio valor 
sort cod_indicador categoria* cod_entidad anio valor 
drop if cod_entidad==0

keep if cod_entidad==63001 | cod_entidad==8001 | cod_entidad==11001 | cod_entidad==68001 | cod_entidad==76001 | cod_entidad==13001 | cod_entidad==54001 | cod_entidad==18001 | cod_entidad==73001 | cod_entidad==17001 | cod_entidad==5001 | cod_entidad==23001 | cod_entidad==41001 | cod_entidad==52001 | cod_entidad==66001 | cod_entidad==19001 | cod_entidad==27001 | cod_entidad==44001 | cod_entidad==47001 | cod_entidad==70001 | cod_entidad==15001 | cod_entidad==20001 | cod_entidad==50001

export excel using "$plata/Indicadores FunLuker - coberturas_men.xlsx",sheet("base",replace)firstrow(variables)

*** FIN
**
*