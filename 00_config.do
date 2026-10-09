*Fundación Luker: Dirección de estrategia e innovación.
*Sistema de indicadores DAMA: configuración de rutas
*Se corre una vez al abrir Stata, antes de cualquier rutina.
*Es el único archivo con rutas del computador. Para trabajar desde otro equipo,
*o para pasar los datos a Google Drive, solo se modifica este archivo.

**#1. Raíz de los datos y de los microdatos, por usuario de Windows
if "`c(username)'" == "juanc" {
	global dama "C:/Users/juanc/OneDrive/Luker/2026/Sistema M&E/dama_indicadores"
	global md   "C:/Users/juanc/OneDrive/MD"
}

if "$dama" == "" {
	display as error "El usuario `c(username)' no tiene rutas definidas en 00_config.do"
	exit 198
}

**#2. Capas del sistema
global bronce  "$dama/bronce"
global plata   "$dama/plata"
global oro     "$dama/oro"
global trabajo "$dama/trabajo"

**#3. Microdatos, fuera del sistema por su tamaño (ver bronce/MICRODATOS.md)
global geih  "$md/GEIH/Archivos planos"
global icfes "$md/ICFES"

display as text "Rutas cargadas: $dama"
