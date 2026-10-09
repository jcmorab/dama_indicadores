*Fundación Luker: Dirección de estrategia e innovación.
*Ensamble de indicadores de la GEIH
*Última modificación: 03/05/2026

**#1. Declaración de carpeta de trabajo
*Las rutas se definen en 00_config.do
clear all
if "$dama" == "" {
	display as error "Primero corra 00_config.do"
	exit 198
}
capture mkdir "$trabajo/4_geih"
cd "$trabajo/4_geih"

**#2. Procesamientos
use "$geih/bd2025/GEIH_2025_ampliada.dta",clear

g año=2026
g PET=(p6040>=15)
g PEA=(oci==1 | dsi==1)

destring area,replace
*lab define area 76"Cali AM"73"Ibagué"70"Sincelejo"68"Bucaramanga"66"Pereira"63"Armenia"54"Cúcuta"52"Pasto"50"Villavicencio"47"Santa Marta"44"Riohacha"41"Neiva"27"Quibdó"23"Montería"20"Valledupar"19"Popayán"18"Florencia"17"Manizales"15"Tunja"13"Cartagena"11"Bogotá DC"8"Barranquilla"5"Medellín"
*lab values area area

destring rama2d_r4,replace
/*sector informal*/
gen anios=per-1
gen oficio_c8_2d="."
replace oficio_c8_2d = substr(oficio_c8, 1, 2) 
destring oficio_c8_2d, replace

gen formal=. if p6430==3
replace formal=0 if p6430==6
replace formal=1 if (rama2d_r4== 84 |   rama2d_r4== 99)
replace formal=0 if p6430==8 

/*asalariados*/
replace formal=1 if p6430 ==2
replace formal=1 if (p6430 ==1 |  p6430 ==7) & (p3045s1==1)
replace formal=1 if (p6430 ==1 |  p6430 ==7) & ((p3045s1==2  | p3045s1==9 ) & p3046 == 1)
replace formal=0 if (p6430 ==1  | p6430 ==7) & ((p3045s1==2 | p3045s1==9 ) & p3046 == 2)
replace formal=1 if (p6430 ==1 |  p6430 ==7) & ((p3045s1==2 | p3045s1==9 ) & p3046 == 9) & (p3069>= 4)
replace formal=0 if (p6430 ==1  | p6430 ==7) & ((p3045s1==2 | p3045s1==9 ) & p3046 == 9) & (p3069 <= 3)

/*independientes*/
/*sin negocio*/
replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & p3065==1
replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & (p3065==2 | p3065==9) & p3066==1
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & (p3065==2 |  p3065==9) & p3066==2
replace formal=1 if (p6430 ==5) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & (p3065==2 | p3065==9) & p3066==9 & p3069 >= 4
replace formal=0 if (p6430 ==5) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & (p3065==2  | p3065==9) & p3066==9 & p3069 <= 3
replace formal=1 if (p6430 ==4) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & (p3065==2  | p3065==9) & p3066==9 & (oficio_c8_2d >=00 &  oficio_c8_2d <=20)
replace formal=0 if (p6430 ==4) & (p6765 ==1 |p6765 ==2 |p6765 ==3 |p6765 ==4 |p6765 ==5 |p6765 ==6 |p6765 ==8) & (p3065==2  | p3065==9) & p3066==9 & (oficio_c8_2d >=21)

/*con negocio*/
/*con registro mercantil*/
replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==1 & p3067s1==1 & p3067s2 >= anios
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==1 & p3067s1==1 & p3067s2 < anios
replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==1
replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==3 & (oficio_c8_2d >=00 &  oficio_c8_2d <=20)
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==3 & (oficio_c8_2d >=21)
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==2
replace formal=1 if (p6430 ==4 ) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==9 & (oficio_c8_2d >=00 &  oficio_c8_2d <=20)
replace formal=0 if (p6430 ==4 ) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==9 & (oficio_c8_2d >=21)
replace formal=1 if (p6430 ==5 ) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==9 & p3069 >= 4 
replace formal=0 if (p6430 ==5 ) & (p6765 == 7) & p3067==1 & p3067s1==2 & p6775==9 & p3069 <= 3 


/*sin registro mercantil*/

replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==2 & p6775 ==1 & p3068==1
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==2 & p6775 ==1 & p3068==2
replace formal=1 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==2 & p6775 ==3 & (oficio_c8_2d >=00 &  oficio_c8_2d <=20)
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==2 & p6775 ==3 & (oficio_c8_2d >=21)
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==2 & p6775==1 & p3068==9
replace formal=0 if (p6430 ==4 | p6430 ==5) & (p6765 == 7) & p3067==2 & p6775==2
replace formal=1 if (p6430 ==5) & (p6765 == 7) & p3067==2 & p6775==9 & p3069 >= 4
replace formal=0 if (p6430 ==5) & (p6765 == 7) & p3067==2 & p6775==9 & p3069 <= 3
replace formal=1 if (p6430 ==4) & (p6765 == 7) & p3067==2 & p6775==9 & (oficio_c8_2d >=00 &  oficio_c8_2d <=20)
replace formal=0 if (p6430 ==4) & (p6765 == 7) & p3067==2 & p6775==9 & (oficio_c8_2d >=21)

/*salud*/

gen salud=0
replace salud=1 if (p6430 ==1 | p6430 ==2 | p6430 ==3 | p6430 ==7 ) & (p6100 ==1 |p6100 ==2) & (p6110 ==1 | p6110 ==2 | p6110 ==4)
replace salud=1 if (p6430 ==1 | p6430 ==2 | p6430 ==3 | p6430 ==7 ) & (p6100==9) & (p6450==2)
replace salud=1 if (p6430 ==1 | p6430 ==2 | p6430 ==3 | p6430 ==7 ) & (p6110==9) & (p6450==2)


/*pensión*/

gen pension=0
replace pension=1 if (p6430 ==1 | p6430 ==2 | p6430 ==3 | p6430 ==7 ) & p6920==3
replace pension=1 if (p6430 ==1 | p6430 ==2 | p6430 ==3 | p6430 ==7 ) & p6920==1 & (p6930 ==1 |p6930 ==2 |p6930 ==3) & (p6940 ==1 | p6940 ==3)

/*ocupación informal*/

gen ei=0 
replace ei=formal if (p6430 ==4 | p6430 ==5)
replace ei=1 if (p6430 ==1 | p6430 ==2 | p6430 ==3 | p6430 ==7 ) & salud==1 & pension==1
replace ei=1 if p6430==4 & (rama2d_r4==84 | rama2d_r4==99)


g joven = (p6040>=15 & p6040<=28)
g oci_joven=oci  if (p6040>=15 & p6040<=28)
g dsi_joven=dsi  if (p6040>=15 & p6040<=28)
g pea_joven =PEA   if (p6040>=15 & p6040<=28)
g pet_joven=PET  if (p6040>=15 & p6040<=28)
g fft_joven=fft if (p6040>=15 & p6040<=28)
g oci_informal=oci if formal==0
g dsi_mujer=dsi if p3271==2
g pea_mujer=PEA   if p3271==2
g ft_juvenil=1 if joven==1 & (oci==1 | dsi==1)
g fft_juvenil=fft if joven==1

collapse (sum) dsi_mujer pea_mujer joven dsi PET oci oci_joven dsi_joven pea_joven PEA pet_joven fft oci_informal ft_juvenil fft_juvenil [pw=fex_c18/12],by(año area)
drop if area>=80

g ML_01=oci
g ML_02=(dsi/PEA)*100
g ML_03=(dsi_mujer/pea_mujer)*100
g ML_04=(oci_informal/oci)*100
g MLJ_01=ft_juvenil
g MLJ_03=dsi_joven
g MLJ_04=pet_joven
g MLJ_05=fft_juvenil
g MLJ_06=oci_joven
g MLJ_07=(dsi_joven/pea_joven)*100
g MLJ_08=(oci_joven/pet_joven)*100
g MLJ_09=(pea_joven/pet_joven)*100

keep año area ML*
renvars ML*,prefix(valor)
g id=_n
reshape long valor,i(id)j(cod_indicador)string

rename año anio
rename area cod_entidad

replace cod_entidad=cod_entidad*1000+1
order cod_indicador,b(cod_entidad)
drop id
g categoria="Total"
g categoria_2=""

keep cod_indicador categoria* anio valor cod_entidad
order cod_indicador categoria* cod_entidad anio valor 
sort cod_indicador categoria* cod_entidad anio valor 
drop if cod_entidad==0

export excel using "$plata/Indicadores FunLuker - geih.xlsx", sheet("base",replace) firstrow(variables)

***
**
*