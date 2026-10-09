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

## Catálogos

Los catálogos están en `catalogos/` y se editan a mano; cada cambio queda en el historial del repositorio.

- `indicadores.csv`: los 59 indicadores del esquema acordado, con la tabla de destino y los códigos de origen.
- `entidades.csv`: municipios, departamentos, 88 colegios, 12 oferentes de UTC, agrupaciones y Colombia. `cod_oficial` guarda el código DANE o SNIES cuando existe.
- `proyectos.csv`: los 48 proyectos de gestión y los 49 programas técnicos de UTC (`PT001` a `PT049`).
- `asignacion_columnas.csv`: traduce cada combinación (`cod_indicador`, `categoria`, `categoria_2`) de la maestra a su código nuevo, su entidad, su proyecto y sus dimensiones.
- `recodificacion_entidades.csv`: cinco colegios que en 2015 aparecen con otro código en el ICFES.
- `cruce_colegios.csv`: nombre de cada colegio en la maestra y el código DANE asignado.

`consolidacion/preparar_catalogos.py` deja registro de cómo se armaron a partir del libro de equivalencias.

## Construcción de oro

```
python consolidacion/construir_oro.py --dama "C:/Users/juanc/OneDrive/Luker/2026/Sistema M&E/dama_indicadores"
```

Requiere pandas y openpyxl. Lee la maestra de `bronce/maestra_historica`, aplica los catálogos, valida y escribe en `oro/` las tablas `datos`, `datos_gestion`, `indicadores`, `entidades` y `proyectos`, más un reporte en `oro/reportes/`. Si una validación falla no escribe nada. La versión anterior de oro se copia a `oro/historico/<fecha>/`.

Validaciones: llave única, valores no vacíos, dimensiones con valores permitidos, códigos de indicador, entidad y proyecto existentes en los catálogos, todo indicador con datos y porcentajes entre 0 y 100. Las tasas de cobertura pueden superar 100 y solo se informan; las de crecimiento quedan fuera de esa regla.

## Estado

Oro está construido desde la maestra con el esquema acordado: 108.634 filas en `datos` (52 indicadores) y 1.360 en `datos_gestion` (7 indicadores).

Las rutinas conservan la lógica original y sus salidas siguen en el formato anterior (`categoria`, `categoria_2`). Mientras no se adapten, oro se alimenta de la maestra.

Pendientes conocidos:

- CE Rural La Palma tiene un código provisional (17001905) hasta obtener su código DANE.
- Ocho oferentes de UTC no tienen código SIET; usan código interno.
- Cuatro proyectos no tienen línea: P007, P017, P018 y P025.
- `7_bajo_peso` no se adaptó. Calcula natalidad para la Gobernación de Caldas, escribe fuera del sistema y no corre: el `collapse` por año elimina `codptore` y `codmunre` antes del `merge`. Debe reescribirse para producir CV_04.
- `4_geih` asigna `anio = 2026` a la GEIH 2025 y procesa un solo año.
- `3_noes`: en el total de 14 a 17 años el numerador exige `jovenes==1` (15 a 28), así que cuenta de 15 a 17 mientras el denominador incluye los 14.
- `8_saber_once` y `9_saber_once_colegios` escriben el subconjunto en `categoria_2` y sexo, zona o naturaleza en `categoria`, al revés de la maestra.
- `6_socioemocionales` no produce CSOC_01 a 03: agrega por grado, sin colegio.
- `9_beneficiarios` es exploratoria.
- Sin rutina: CV_01 a 03, CV_05, ECO_01 y 02, POB_01 y 02, SABER_07, MLJ_02, UTC_01, CSOC_01 a 03 y GP_01 a 03.
