"""Construye la capa oro con el esquema acordado.

Toma la maestra (bronce/maestra_historica) y le aplica los catálogos de catalogos/:
asignacion_columnas.csv traduce cada combinación (cod_indicador, categoria, categoria_2)
a su código nuevo, su entidad, su proyecto y sus dimensiones.

Salida en oro/:
  datos.csv           cod_indicador, cod_entidad, anio, sexo, zona, naturaleza, grado, edad, subconjunto, valor
  datos_gestion.csv   cod_indicador, cod_proyecto, cod_entidad, anio, valor
  indicadores.csv, entidades.csv, proyectos.csv
  reportes/construccion_<fecha>.md

Si alguna validación falla, el script se detiene y no escribe nada.

Uso:
  python consolidacion/construir_oro.py --dama "C:/Users/juanc/OneDrive/Luker/2026/Sistema M&E/dama_indicadores"
"""
import argparse
import datetime as dt
import shutil
from pathlib import Path

import pandas as pd

REPO = Path(__file__).resolve().parents[1]
CAT = REPO / "catalogos"
MAESTRA = "bronce/maestra_historica/Indicadores FunLuker - Base maestra DAMA.xlsx"

DIMENSIONES = {
    "sexo": {"Total", "Hombre", "Mujer"},
    "zona": {"Total", "Urbano", "Rural"},
    "naturaleza": {"Total", "Oficial", "No oficial"},
    "grado": {"Total", "Primero", "Segundo", "Tercero", "Cuarto", "Quinto", "Media"},
    "edad": {"Total", "14-17", "15-28"},
    "subconjunto": {"Total", "Solo once", "Solo ciclos"},
}
DIMS = list(DIMENSIONES)
LLAVE_DATOS = ["cod_indicador", "cod_entidad", "anio"] + DIMS
LLAVE_GESTION = ["cod_indicador", "cod_proyecto", "cod_entidad", "anio"]
VACIO = "∅"


class Bitacora:
    def __init__(self):
        self.lineas = []

    def __call__(self, texto=""):
        print(texto)
        self.lineas.append(texto)


def resolver_duplicados(df, llave, log, nombre):
    """Filas que caen en la misma llave después de traducir nombres y códigos."""
    dup = df[df.duplicated(llave, keep=False)]
    if dup.empty:
        return df
    grupos = dup.groupby(llave, dropna=False)
    resueltas, errores = [], []
    for k, g in grupos:
        trat = " ".join(g.tratamiento.dropna().unique())
        if g.valor.nunique() == 1:
            motivo, valor = "duplicado exacto: se conserva una fila", g.valor.iloc[0]
        elif "se promedia" in trat:
            motivo, valor = "variante del nombre del mismo colegio: se promedian", g.valor.mean()
        elif "se conserva 15" in trat and 15 in set(g.valor):
            motivo, valor = "se conserva 15; el otro valor repite el del año anterior", 15.0
        elif "Grano programa" in trat:
            motivo, valor = "variantes del nombre del mismo programa: se suman las matrículas", g.valor.sum()
        else:
            errores.append(g)
            continue
        fila = g.iloc[[0]].copy()
        fila["valor"] = valor
        resueltas.append(fila)
        log(f"- {nombre}: {dict(zip(llave, k))} | {len(g)} filas → 1 ({motivo})")
    if errores:
        raise SystemExit(f"Llaves duplicadas sin regla en {nombre}:\n" + pd.concat(errores).to_string())
    return pd.concat([df.drop(dup.index), *resueltas], ignore_index=True)


def main(dama: Path, escribir: bool, salida: Path = None):
    log = Bitacora()
    hoy = dt.date.today().isoformat()
    log(f"# Construcción de oro, {hoy}\n")

    ind = pd.read_csv(CAT / "indicadores.csv")
    ent = pd.read_csv(CAT / "entidades.csv", dtype={"cod_oficial": str})
    proy = pd.read_csv(CAT / "proyectos.csv")
    asig = pd.read_csv(CAT / "asignacion_columnas.csv", dtype=str)
    recod = pd.read_csv(CAT / "recodificacion_entidades.csv")

    d = pd.read_excel(dama / MAESTRA, sheet_name="datos")
    log(f"Filas en la maestra: {len(d):,}\n")
    log("## Depuración\n")

    # 1. Filas sin valor
    sin_valor = d.valor.isna()
    log(f"- Filas sin valor eliminadas: {sin_valor.sum()} "
        f"({', '.join(f'{k} {v}' for k, v in d[sin_valor].cod_indicador.value_counts().sort_index().items())})")
    d = d[~sin_valor].copy()

    # 2. Códigos del ICFES de 2015 que cambiaron
    m = d.cod_entidad.isin(recod.cod_anterior)
    d.loc[m, "cod_entidad"] = d.loc[m, "cod_entidad"].map(dict(zip(recod.cod_anterior, recod.cod_entidad)))
    log(f"- Filas de colegios recodificadas al código DANE vigente: {m.sum()}")

    # 3. Traducción con asignacion_columnas
    k = ["cod_indicador", "categoria", "categoria_2"]
    for c in k[1:]:
        d[c] = d[c].fillna(VACIO).astype(str)
        asig[c] = asig[c].fillna(VACIO)
    d = d.merge(asig.rename(columns={"cod_entidad": "entidad_destino"}), on=k, how="left", validate="m:1")
    sin_asig = d.tabla.isna()
    if sin_asig.any():
        raise SystemExit("Combinaciones sin asignación:\n" + d[sin_asig][k].drop_duplicates().to_string())

    elim = d.tabla == "se elimina"
    for t, n in d[elim].groupby("tratamiento").size().items():
        log(f"- Eliminadas por regla acordada: {n} ({t})")
    d = d[~elim].copy()

    d["cod_entidad"] = d.cod_entidad.where(d.entidad_destino == "igual", d.entidad_destino).astype("int64")
    d["cod_indicador"] = d.cod_nuevo
    d["anio"] = d.anio.astype(int)

    datos = d[d.tabla == "datos"][LLAVE_DATOS + ["valor", "tratamiento"]].copy()
    gest = d[d.tabla == "datos_gestion"][LLAVE_GESTION + ["valor", "tratamiento"]].copy()
    datos = resolver_duplicados(datos, LLAVE_DATOS, log, "datos")
    gest = resolver_duplicados(gest, LLAVE_GESTION, log, "datos_gestion")
    datos = datos.drop(columns="tratamiento").sort_values(LLAVE_DATOS).reset_index(drop=True)
    gest = gest.drop(columns="tratamiento").sort_values(LLAVE_GESTION).reset_index(drop=True)

    # ---------------- Validaciones ----------------
    log("\n## Validaciones\n")
    fallas = []

    def check(nombre, ok, detalle=""):
        log(f"- {'OK   ' if ok else 'FALLA'} {nombre}{(': ' + detalle) if detalle and not ok else ''}")
        if not ok:
            fallas.append(nombre)

    check("llave única en datos", not datos.duplicated(LLAVE_DATOS).any())
    check("llave única en datos_gestion", not gest.duplicated(LLAVE_GESTION).any())
    check("sin valores vacíos", datos.notna().all().all() and gest.notna().all().all())
    for dim, permitidos in DIMENSIONES.items():
        malos = set(datos[dim]) - permitidos
        check(f"valores permitidos en {dim}", not malos, str(malos))
    tabla_ind = dict(zip(ind.cod_indicador, ind.tabla))
    malos = {c for c in datos.cod_indicador.unique() if tabla_ind.get(c) != "datos"}
    check("indicadores de datos existen en el catálogo con tabla datos", not malos, str(malos))
    malos = {c for c in gest.cod_indicador.unique() if tabla_ind.get(c) != "datos_gestion"}
    check("indicadores de gestión existen en el catálogo con tabla datos_gestion", not malos, str(malos))
    usados = set(datos.cod_indicador) | set(gest.cod_indicador)
    sin_datos = set(ind.cod_indicador) - usados
    check("todo indicador del catálogo tiene datos", not sin_datos, str(sorted(sin_datos)))
    malos = (set(datos.cod_entidad) | set(gest.cod_entidad)) - set(ent.cod_entidad)
    check("toda entidad existe en el catálogo", not malos, str(sorted(malos)))
    malos = set(gest.cod_proyecto) - set(proy.cod_proyecto)
    check("todo proyecto existe en el catálogo", not malos, str(sorted(malos)))
    # Las tasas de crecimiento pueden ser negativas y no entran en la regla de 0 a 100.
    # Las tasas de cobertura pueden superar 100: la matrícula incluye estudiantes de otras edades o
    # municipios y el denominador son proyecciones de población. Se informan, no detienen el proceso.
    es_pct = ind.unidad_medida.str.startswith("Porcentaje")
    cobertura = set(ind[es_pct & ind.indicador.str.contains("cobertura", case=False)].cod_indicador)
    variacion = set(ind[es_pct & ind.indicador.str.contains("crecimiento", case=False)].cod_indicador)
    pct = set(ind[es_pct].cod_indicador) - cobertura - variacion
    fuera = datos[datos.cod_indicador.isin(pct) & ~datos.valor.between(0, 100)]
    check("porcentajes entre 0 y 100", fuera.empty, fuera.head(10).to_string())
    cob = datos[datos.cod_indicador.isin(cobertura)]
    check("tasas de cobertura no negativas", (cob.valor >= 0).all())
    log(f"- AVISO tasas de cobertura por encima de 100: {(cob.valor > 100).sum()} filas "
        f"({', '.join(f'{k} {v}' for k, v in cob[cob.valor > 100].cod_indicador.value_counts().sort_index().items())})")

    if fallas:
        raise SystemExit(f"\n{len(fallas)} validaciones fallaron; no se escribe oro.")

    # ---------------- Resumen ----------------
    log("\n## Resultado\n")
    log(f"- datos: {len(datos):,} filas, {datos.cod_indicador.nunique()} indicadores")
    log(f"- datos_gestion: {len(gest):,} filas, {gest.cod_indicador.nunique()} indicadores, "
        f"{gest.cod_proyecto.nunique()} proyectos o programas")
    log(f"- entidades usadas: {len(set(datos.cod_entidad) | set(gest.cod_entidad))} de {len(ent):,} en el catálogo")
    log("\n| Indicador | Filas | Años | Entidades |\n|---|---|---|---|")
    for tabla in (datos, gest):
        r = tabla.groupby("cod_indicador").agg(filas=("valor", "size"), a0=("anio", "min"), a1=("anio", "max"),
                                               ent=("cod_entidad", "nunique"))
        for c, x in r.iterrows():
            log(f"| {c} | {x.filas:,} | {x.a0} a {x.a1} | {x.ent} |")

    if not escribir:
        return
    oro = salida or dama / "oro"
    if (oro / "datos.csv").exists():
        hist = oro / "historico" / hoy
        hist.mkdir(parents=True, exist_ok=True)
        for f in ("datos", "datos_gestion", "indicadores", "entidades", "proyectos"):
            if (oro / f"{f}.csv").exists():
                shutil.copy2(oro / f"{f}.csv", hist / f"{f}.csv")
    (oro / "reportes").mkdir(parents=True, exist_ok=True)
    datos.to_csv(oro / "datos.csv", index=False, encoding="utf-8")
    gest.to_csv(oro / "datos_gestion.csv", index=False, encoding="utf-8")
    ind.to_csv(oro / "indicadores.csv", index=False, encoding="utf-8")
    ent.to_csv(oro / "entidades.csv", index=False, encoding="utf-8")
    proy.to_csv(oro / "proyectos.csv", index=False, encoding="utf-8")
    (oro / "reportes" / f"construccion_{hoy}.md").write_text("\n".join(log.lineas) + "\n", encoding="utf-8")
    print(f"\nOro escrito en {oro}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dama", required=True, type=Path, help="carpeta dama_indicadores")
    ap.add_argument("--solo-validar", action="store_true", help="valida sin escribir oro")
    ap.add_argument("--salida", type=Path, help="carpeta de salida; por defecto <dama>/oro")
    a = ap.parse_args()
    main(a.dama, escribir=not a.solo_validar, salida=a.salida)
