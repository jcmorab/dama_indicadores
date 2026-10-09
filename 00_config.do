*Fundación Luker: Dirección de estrategia e innovación.
*Sistema de indicadores DAMA: rutas de trabajo
*Se corre una vez al abrir Stata, antes de cualquier rutina.

**#1. Carpeta de datos y microdatos, por usuario de Windows
if "`c(username)'" == "juanc" {
	global dama "C:/Users/juanc/OneDrive/Luker/dama_indicadores"
	global md   "C:/Users/juanc/OneDrive/MD"
}

if "$dama" == "" {
	display as error "El usuario `c(username)' no tiene rutas definidas en 00_config.do"
	exit 198
}

**#2. Capas
global bronce "$dama/01_bronce"
global plata  "$dama/02_plata"
global oro    "$dama/03_oro"

**#3. Microdatos
global geih  "$md/GEIH/Archivos planos"
global icfes "$md/ICFES"

**#4. Archivos intermedios, en la carpeta temporal del sistema
local tmp = subinstr("`c(tmpdir)'", "\", "/", .)
if substr("`tmp'", -1, 1) == "/" local tmp = substr("`tmp'", 1, length("`tmp'") - 1)
global trabajo "`tmp'/dama_indicadores"
capture mkdir "$trabajo"

display as text "Rutas cargadas: $dama"
