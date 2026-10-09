# dama_indicadores

Sistema de indicadores DAMA de la Fundación Luker. Reúne indicadores de contexto socioeconómico, educación y gestión de proyectos para Manizales y un grupo de ciudades de comparación.

Este repositorio contiene el código y los catálogos. Los datos se almacenan por fuera, en tres capas:

```
01_bronce   fuentes originales, sin modificar
02_plata    una tabla por rutina
03_oro      base consolidada para consulta
```

## Repositorio

```
00_config.do        rutas de trabajo
01_rutinas/         procesamiento en Stata, de bronce a plata
02_catalogos/       indicadores, entidades, proyectos y reglas de traducción
03_consolidacion/   construcción y validación de oro, en Python
```

## Uso

Rutinas: correr `00_config.do` y luego la rutina. Cada rutina escribe en plata un archivo con su mismo nombre.

Oro (Python 3 con pandas y openpyxl):

```
python 03_consolidacion/construir_oro.py --dama <carpeta de datos>
```

El proceso valida la base y no escribe nada si alguna validación falla.

## Base consolidada

| Tabla | Contenido |
|---|---|
| `datos` | `cod_indicador`, `cod_entidad`, `anio`, `sexo`, `zona`, `naturaleza`, `grado`, `edad`, `subconjunto`, `valor` |
| `datos_gestion` | `cod_indicador`, `cod_proyecto`, `cod_entidad`, `anio`, `valor` |
| `indicadores` | nombre, dimensión, sección, fuente, unidad de medida y periodicidad |
| `entidades` | municipios, departamentos, colegios e instituciones, con código DANE o SNIES cuando existe |
| `proyectos` | proyectos y programas de la Fundación |

Las dimensiones que no aplican toman el valor `Total`. La base guarda desagregaciones de una dimensión a la vez, no cruces entre ellas.

Fuentes: DANE, ICFES, Ministerio de Educación Nacional, Ministerio de Salud y Protección Social, Ministerio de Defensa y registros administrativos de la Fundación Luker.
