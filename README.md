# dama_indicadores

Sistema de indicadores DAMA de la Fundación Luker. Reúne indicadores de contexto socioeconómico, educación y gestión de proyectos para Manizales y un grupo de ciudades de comparación.

Este repositorio contiene el código y los catálogos. Los datos se almacenan por fuera, organizados en tres capas:

- **bronce**: fuentes originales, sin modificar.
- **plata**: una tabla por rutina de procesamiento.
- **oro**: base consolidada para consulta.

```
00_config.do      rutas de trabajo
rutinas/          procesamiento en Stata, de bronce a plata
catalogos/        indicadores, entidades, proyectos y reglas de traducción
consolidacion/    construcción y validación de oro, en Python
```

## Uso

Rutinas (Stata): definir las rutas en `00_config.do`, correrlo y luego correr la rutina.

Construcción de oro (Python 3 con pandas y openpyxl):

```
python consolidacion/construir_oro.py --dama <carpeta de datos>
```

El proceso valida la base antes de escribirla y no escribe nada si alguna validación falla.

## Base consolidada

| Tabla | Contenido |
|---|---|
| `datos` | `cod_indicador`, `cod_entidad`, `anio`, `sexo`, `zona`, `naturaleza`, `grado`, `edad`, `subconjunto`, `valor` |
| `datos_gestion` | `cod_indicador`, `cod_proyecto`, `cod_entidad`, `anio`, `valor` |
| `indicadores` | nombre, dimensión, sección, fuente, unidad de medida y periodicidad de cada indicador |
| `entidades` | municipios, departamentos, colegios e instituciones, con código DANE o SNIES cuando existe |
| `proyectos` | proyectos y programas de la Fundación |

Las dimensiones que no aplican a un indicador toman el valor `Total`. La base guarda desagregaciones de una dimensión a la vez (por sexo, por zona o por naturaleza del plantel), no cruces entre ellas.

Fuentes: DANE, ICFES, Ministerio de Educación Nacional, Ministerio de Salud y Protección Social, Ministerio de Defensa y registros administrativos de la Fundación Luker.
