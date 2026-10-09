# dama_indicadores

Rutinas de la base de indicadores DAMA de la Fundación Luker.

Este repositorio guarda solo código. Los datos están en OneDrive, en `Sistema M&E/dama_indicadores/`, organizados en tres capas:

- **bronce**: archivos tal como llegan de la fuente. No se editan; una versión nueva se guarda al lado de la anterior.
- **plata**: una tabla por rutina, producida a partir de bronce.
- **oro**: la base consolidada que consume el tablero.

Además, `trabajo/` guarda los archivos intermedios de cada rutina (se pueden borrar, se regeneran al correrla) y `respaldo/` guarda copias de seguridad fechadas.

Los microdatos de GEIH, ICFES y estadísticas vitales no se copian a bronce por su tamaño. Siguen en `OneDrive/MD`; `bronce/MICRODATOS.md` indica qué archivos usa cada rutina.

## Cómo correr una rutina

1. Abrir Stata y correr `00_config.do`. Es el único archivo con rutas del computador.
2. Correr la rutina. Lee de bronce o de los microdatos, deja sus intermedios en `trabajo/<rutina>` y escribe su salida en `plata/`.

Comandos de usuario que deben estar instalados: `renvars`, `fs` y `dropmiss`.

## Rutinas

| Rutina | Insumo | Salida en plata | Indicadores |
|---|---|---|---|
| `1_coberturas_men` | `bronce/men_coberturas` | `coberturas_men.xlsx` | COBE_01 a 05 |
| `2_tasa_transito` | `bronce/men_transito_inmediato` | `tasa_transito.xlsx` | COBE_06 |
| `3_noes` | GEIH 2021 a 2025 | `noes.xlsx` | MLJ_10, MLJ_11 |
| `4_geih` | GEIH 2025 | `geih.xlsx` | ML_01 a 04, MLJ_01, MLJ_03 a 09 |
| `5_atal_utc` | `bronce/fundacion_fluidez_lectora`, `bronce/fundacion_utc` | `UTC ATAL.xlsx` | ATAL_01 a 04, UTC_02, UTC_03 |
| `6_socioemocionales` | `bronce/fundacion_socioemocionales` | `socioemocionales.xlsx` | 18 habilidades por grado, 2025 |
| `7_bajo_peso` | Estadísticas vitales | ninguna | ninguno |
| `8_saber_once/8_saber_once` | ICFES 2015 a 2025 | `saber_once.xlsx` | SABER_01 a 06 |
| `8_saber_once/9_saber_once_colegios` | ICFES 2015 a 2025 | `saber_once_colegios.xlsx` | SABER_08 a 13 |
| `9_beneficiarios` | `bronce/fundacion_beneficiarios` | ninguna | ninguno |
| `10_uso_tiempo` | GEIH 2021 a 2025 | `trabajo no remunerado.xlsx` | TNR_01, TNR_02 |

Los nombres de salida llevan el prefijo `Indicadores FunLuker - `.

## Estado

Las rutinas conservan la lógica original. En esta etapa solo se centralizaron las rutas en `00_config.do`; el historial de commits muestra la versión original y el cambio.

Las salidas siguen en el formato anterior (`categoria`, `categoria_2`). La adaptación al esquema acordado en `DAMA_agregacion_indicadores.pptx` y `DAMA_equivalencias_indicadores.xlsx` es la etapa siguiente.

Pendientes conocidos:

- `7_bajo_peso` no se adaptó. Calcula natalidad para la Gobernación de Caldas, escribe fuera del sistema y no corre: el `collapse` por año elimina `codptore` y `codmunre` antes del `merge`. Debe reescribirse para producir CV_04.
- `4_geih` asigna `anio = 2026` a la GEIH 2025 y procesa un solo año.
- `3_noes`: en el total de 14 a 17 años el numerador exige `jovenes==1` (15 a 28), así que cuenta de 15 a 17 mientras el denominador incluye los 14.
- `8_saber_once` y `9_saber_once_colegios` escriben el subconjunto en `categoria_2` y sexo, zona o naturaleza en `categoria`, al revés de la maestra.
- `6_socioemocionales` no produce CSOC_01 a 03: agrega por grado, sin colegio.
- `9_beneficiarios` es exploratoria.
- Sin rutina: CV_01 a 03, CV_05, ECO_01 y 02, POB_01 y 02, SABER_07, MLJ_02, UTC_01, CSOC_01 a 03 y GP_01 a 03. Sus datos están en la maestra (`bronce/maestra_historica`).
