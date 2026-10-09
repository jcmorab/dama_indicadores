"""Construye la capa oro.

Aplica los catálogos de 02_catalogos a la maestra de 01_bronce/luker_maestra y escribe en 03_oro:
  datos.csv           cod_indicador, cod_entidad, anio, sexo, zona, naturaleza, grado, edad, subconjunto, valor
  datos_gestion.csv   cod_indicador, cod_proyecto, cod_entidad, anio, valor
  indicadores.csv, entidades.csv, proyectos.csv

Si alguna validación falla, se detiene sin escribir.

Uso:
  python 03_consolidacion/construir_oro.py --dama "C:/Users/juanc/OneDrive/Luker/dama_indicadores"
"""
import argparse
from pathlib import Path

import pandas as pd

REPO = Path(__file__).resolve().parents[1]
CAT = REPO / "02_catalogos"
MAESTRA = "01_bronce/luker_maestra/Indicadores FunLuker - Base maestra DAMA.xlsx"

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


def resolver_duplicados(df, llave, nombre):
    """Filas que caen en la misma llave después de traducir nombres y códigos."""
    dup = df[df.duplicated(llave, keep=False)]
    if dup.empty:
        return df
    resueltas, errores = [], []
    for k, g in dup.groupby(llave, dropna=False):
        trat = " ".join(g.tratamiento.dropna().unique())
        if g.valor.nunique() == 1:
            motivo, valor = "duplicado exacto", g.valor.iloc[0]
        elif "se promedia" in trat:
            motivo, valor = "variantes del nombre del mismo colegio, promedio", g.valor.mean()
        elif "se conserva 15" in trat and 15 in set(g.valor):
            motivo, valor = "se conserva 15", 15.0
        elif "Grano programa" in trat:
            motivo, valor = "variantes del nombre del mismo programa, suma", g.valor.sum()
        else:
            errores.append(g)
            continue
        fila = g.iloc[[0]].copy()
        fila["valor"] = valor
        resueltas.append(fila)
        print(f"  {nombre}: {dict(zip(llave[:4], k[:4]))}, {len(g)} filas a 1 ({motivo})")
    if errores:
        raise SystemExit(f"Llaves duplicadas sin regla en {nombre}:\n" + pd.concat(errores).to_string())
    return pd.concat([df.drop(dup.index), *resueltas], ignore_index=True)


def main(dama: Path, escribir: bool, salida: Path = None):
    ind = pd.read_csv(CAT / "indicadores.csv")
    ent = pd.read_csv(CAT / "entidades.csv", dtype={"cod_oficial": str})
    proy = pd.read_csv(CAT / "proyectos.csv")
    asig = pd.read_csv(CAT / "asignacion_columnas.csv", dtype=str)
    recod = pd.read_csv(CAT / "recodificacion_entidades.csv")

    d = pd.read_excel(dama / MAESTRA, sheet_name="datos")
    print(f"Maestra: {len(d):,} filas")

    sin_valor = d.valor.isna()
    print(f"  sin valor, eliminadas: {sin_valor.sum()}")
    d = d[~sin_valor].copy()

    m = d.cod_entidad.isin(recod.cod_anterior)
    d.loc[m, "cod_entidad"] = d.loc[m, "cod_entidad"].map(dict(zip(recod.cod_anterior, recod.cod_entidad)))
    print(f"  colegios recodificados al código vigente: {m.sum()}")

    k = ["cod_indicador", "categoria", "categoria_2"]
    for c in k[1:]:
        d[c] = d[c].fillna(VACIO).astype(str)
        asig[c] = asig[c].fillna(VACIO)
    d = d.merge(asig.rename(columns={"cod_entidad": "entidad_destino"}), on=k, how="left", validate="m:1")
    if d.tabla.isna().any():
        raise SystemExit("Combinaciones sin asignación:\n" + d[d.tabla.isna()][k].drop_duplicates().to_string())

    elim = d.tabla == "se elimina"
    for t, n in d[elim].groupby("tratamiento").size().items():
        print(f"  eliminadas por regla acordada: {n} ({t})")
    d = d[~elim].copy()

    d["cod_entidad"] = d.cod_entidad.where(d.entidad_destino == "igual", d.entidad_destino).astype("int64")
    d["cod_indicador"] = d.cod_nuevo
    d["anio"] = d.anio.astype(int)

    datos = d[d.tabla == "datos"][LLAVE_DATOS + ["valor", "tratamiento"]].copy()
    gest = d[d.tabla == "datos_gestion"][LLAVE_GESTION + ["valor", "tratamiento"]].copy()
    datos = resolver_duplicados(datos, LLAVE_DATOS, "datos")
    gest = resolver_duplicados(gest, LLAVE_GESTION, "datos_gestion")
    datos = datos.drop(columns="tratamiento").sort_values(LLAVE_DATOS).reset_index(drop=True)
    gest = gest.drop(columns="tratamiento").sort_values(LLAVE_GESTION).reset_index(drop=True)

    print("Validaciones")
    fallas = []

    def check(nombre, ok, detalle=""):
        print(f"  {'ok   ' if ok else 'FALLA'} {nombre}{(': ' + detalle) if detalle and not ok else ''}")
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
    check("indicadores de datos en el catálogo", not malos, str(malos))
    malos = {c for c in gest.cod_indicador.unique() if tabla_ind.get(c) != "datos_gestion"}
    check("indicadores de gestión en el catálogo", not malos, str(malos))
    sin_datos = set(ind.cod_indicador) - set(datos.cod_indicador) - set(gest.cod_indicador)
    check("todo indicador del catálogo tiene datos", not sin_datos, str(sorted(sin_datos)))
    malos = (set(datos.cod_entidad) | set(gest.cod_entidad)) - set(ent.cod_entidad)
    check("toda entidad existe en el catálogo", not malos, str(sorted(malos)))
    malos = set(gest.cod_proyecto) - set(proy.cod_proyecto)
    check("todo proyecto existe en el catálogo", not malos, str(sorted(malos)))
    # Las tasas de crecimiento pueden ser negativas y las de cobertura superar 100
    # (la matrícula incluye estudiantes de otras edades y el denominador son proyecciones).
    es_pct = ind.unidad_medida.str.startswith("Porcentaje")
    cobertura = set(ind[es_pct & ind.indicador.str.contains("cobertura", case=False)].cod_indicador)
    variacion = set(ind[es_pct & ind.indicador.str.contains("crecimiento", case=False)].cod_indicador)
    pct = set(ind[es_pct].cod_indicador) - cobertura - variacion
    fuera = datos[datos.cod_indicador.isin(pct) & ~datos.valor.between(0, 100)]
    check("porcentajes entre 0 y 100", fuera.empty, fuera.head(10).to_string())
    cob = datos[datos.cod_indicador.isin(cobertura)]
    check("tasas de cobertura no negativas", (cob.valor >= 0).all())
    print(f"  aviso: tasas de cobertura por encima de 100: {(cob.valor > 100).sum()} filas")
    if fallas:
        raise SystemExit(f"{len(fallas)} validaciones fallaron; no se escribe oro.")

    print(f"Oro: datos {len(datos):,} filas, {datos.cod_indicador.nunique()} indicadores; "
          f"datos_gestion {len(gest):,} filas, {gest.cod_indicador.nunique()} indicadores")
    if not escribir:
        return
    oro = salida or dama / "03_oro"
    oro.mkdir(parents=True, exist_ok=True)
    datos.to_csv(oro / "datos.csv", index=False, encoding="utf-8")
    gest.to_csv(oro / "datos_gestion.csv", index=False, encoding="utf-8")
    ind.to_csv(oro / "indicadores.csv", index=False, encoding="utf-8")
    ent.to_csv(oro / "entidades.csv", index=False, encoding="utf-8")
    proy.to_csv(oro / "proyectos.csv", index=False, encoding="utf-8")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dama", required=True, type=Path, help="carpeta dama_indicadores")
    ap.add_argument("--solo-validar", action="store_true", help="valida sin escribir")
    ap.add_argument("--salida", type=Path, help="carpeta de salida; por defecto <dama>/03_oro")
    a = ap.parse_args()
    main(a.dama, escribir=not a.solo_validar, salida=a.salida)
