"""Construye los catálogos de catalogos/ a partir del libro de equivalencias acordado.

Se corre una sola vez. Desde entonces los catálogos se editan a mano en catalogos/
y quedan versionados en Git; este script queda como registro de cómo se armaron.

Insumos (rutas relativas a la carpeta de datos, ver --dama):
  respaldo/2026-10-09/bases_dama/DAMA_equivalencias_indicadores.xlsx
  bronce/maestra_historica/Indicadores FunLuker - Base maestra DAMA.xlsx
  plata/Indicadores FunLuker - saber_once_colegios.xlsx   (nombres y códigos DANE del ICFES)

Uso:
  python consolidacion/preparar_catalogos.py --dama "C:/Users/juanc/OneDrive/Luker/2026/Sistema M&E/dama_indicadores"
"""
import argparse
import re
import unicodedata
from pathlib import Path

import pandas as pd

REPO = Path(__file__).resolve().parents[1]
CAT = REPO / "catalogos"

# Códigos SNIES de institución, tomados de los archivos de matrícula del SNIES en bronce/men_snies_matricula
SNIES = {
    "Universidad de Caldas": "1112",
    "Universidad de Manizales": "1722",
    "Universidad Autonoma de Manizales": "1825",
    "Universidad Catolica de Manizales": "1827",
}

# Nombres de colegios que en el ICFES comparten código DANE: una sola entidad con el nombre vigente
FUSIONES_COLEGIOS = {
    "IE Chipre": "IE Instituto Chipre",
    "IE INSTITUTO CHIPRE": "IE Instituto Chipre",
    "IE Pablo VI": "IE Pablo VI",
    "IE INSTITUTO PABLO VI": "IE Pablo VI",
    "IE Leon de Greiff": "IE León de Greiff",
    "IE LICEO LEON DE GREIFF": "IE León de Greiff",
    "IE JUAN PABLO II": "IE Rural Juan Pablo II",
    "IE RAFAEL POMBO": "IE Rural Rafael Pombo",
}

# Colegio sin código DANE identificado: código provisional, reemplazar cuando se obtenga el DANE
PROVISIONALES = {"CE Rural La Palma": 17001905}


def clave(t):
    """Normaliza un nombre de colegio para cruzarlo con el ICFES."""
    t = unicodedata.normalize("NFKD", str(t)).encode("ascii", "ignore").decode().upper()
    t = " ".join(re.sub(r"[^A-Z0-9 ]", " ", t).split())
    for a, b in [("INSTITUCION EDUCATIVA", ""), (r"\bIE\b", ""), (r"\bRURAL\b", ""), (r"\bINSTITUTO\b", ""),
                 (r"\bCOLEGIO\b", ""), (r"\bLICEO\b", ""), (r"\bESCUELA\b", ""), (r"\bTECNICO\b", ""),
                 (r"\bNTRA\b", "NUESTRA"), (r"\bSRA\b", "SENORA"), (r"\bSUP\b", "SUPERIOR"),
                 (r"\bAUXILIARES\b", "AUXILIAR"), (r"\bDE\b", ""), (r"\bLA\b", ""), (r"\bDEL\b", ""), (r"\bCE\b", "")]:
        t = re.sub(a, b, t)
    return " ".join(t.split())


def nombre_icfes(t):
    """Convierte el nombre del ICFES (mayúsculas y abreviado) a un nombre legible."""
    t = " ".join(str(t).split())
    for a, b in [(r"^INSTITUCI[OÓ]N EDUCATIVA\b", "IE"), (r"^COL\.", "Colegio"), (r"^LIC\.", "Liceo"),
                 (r"^INST\.\s*EDUC\b", "Instituto de Educación"), (r"^INST\.", "Instituto"), (r"^SEM\.", "Seminario"),
                 (r"^ACAD\.", "Academia"), (r"\bGRAL\.", "General"), (r"\bNTRA\b\.?", "Nuestra"),
                 (r"\bSRA\b\.?", "Señora"), (r"\bS\. CLEMENTE\b", "San Clemente"), (r"\bR\.$", "R.")]:
        t = re.sub(a, b, t, flags=re.I)
    minus = {"de", "del", "y", "para", "en", "e"}
    siglas = {"IE", "ASED", "CENSA", "ASPAEN", "II", "VI", "X", "INEM", "R."}
    out = []
    for i, w in enumerate(t.split(" ")):
        if w.upper() in siglas or w in siglas:
            out.append(w.upper())
        elif i > 0 and w.lower() in minus:
            out.append(w.lower())
        else:
            out.append("-".join(p.capitalize() for p in w.split("-")))
    t = " ".join(out).replace("Confamiliares Sede A", "Confamiliares")
    return t.replace("para La Ciencia", "para la Ciencia").replace("Aspaen-Gimnasio", "Aspaen Gimnasio")


def main(dama: Path):
    eq = dama / "respaldo/2026-10-09/bases_dama/DAMA_equivalencias_indicadores.xlsx"
    maestra = dama / "bronce/maestra_historica/Indicadores FunLuker - Base maestra DAMA.xlsx"
    saber = dama / "plata/Indicadores FunLuker - saber_once_colegios.xlsx"

    # ---------- Colegios del ICFES: código vigente y nombre más reciente ----------
    s = pd.read_excel(saber)[["cod_entidad", "entidad", "anio"]]
    g = s.groupby(["cod_entidad", "entidad"]).anio.agg(["min", "max"]).reset_index()
    g["k"] = g.entidad.map(clave)
    # 2015 usa otro código para cinco colegios que desde 2016 tienen código estable con el mismo nombre
    recod = []
    for k, sub in g.groupby("k"):
        if sub.cod_entidad.nunique() > 1:
            vigente = sub.loc[sub["max"].idxmax(), "cod_entidad"]
            for c in sub.cod_entidad.unique():
                if c != vigente:
                    recod.append({"cod_anterior": c, "cod_entidad": vigente,
                                  "motivo": "Código del ICFES en 2015; desde 2016 el colegio usa el código vigente"})
    recod = pd.DataFrame(recod)
    vig = g[~g.cod_entidad.isin(recod.cod_anterior)]
    vig = vig.sort_values("max").groupby("cod_entidad").tail(1)  # nombre más reciente por código

    # ---------- Colegios de ATAL, CSOC y UTC: cruce por nombre ----------
    en = pd.read_excel(eq, sheet_name="entidades_nuevas")
    col = en[(en.tipo == "colegio") & (en.cod_entidad == "DANE (DUE)")].copy()
    cruce = []
    for n in col.nombre_normalizado:
        if n in PROVISIONALES:
            cruce.append((n, PROVISIONALES[n], "provisional: sin código DANE identificado"))
            continue
        m = vig[vig.k == clave(n)]
        if len(m) != 1:
            raise SystemExit(f"Colegio sin cruce único con el ICFES: {n} ({len(m)} candidatos)")
        cruce.append((n, int(m.cod_entidad.iloc[0]), "ICFES, cruce por nombre"))
    cruce = pd.DataFrame(cruce, columns=["entidad_ref", "cod_entidad", "origen_codigo"])

    nombres = {}
    for _, r in cruce.iterrows():
        nombres.setdefault(r.cod_entidad, FUSIONES_COLEGIOS.get(r.entidad_ref, r.entidad_ref))
    for _, r in cruce.iterrows():  # las fusiones mandan sobre el primer nombre visto
        if r.entidad_ref in FUSIONES_COLEGIOS:
            nombres[r.cod_entidad] = FUSIONES_COLEGIOS[r.entidad_ref]

    filas_col = []
    for _, r in vig.iterrows():
        c = int(r.cod_entidad)
        filas_col.append({"cod_entidad": c, "entidad": nombres.get(c, nombre_icfes(r.entidad)),
                          "tipo": "colegio", "cod_oficial": str(c)})
    for n, c in PROVISIONALES.items():
        filas_col.append({"cod_entidad": c, "entidad": n, "tipo": "colegio", "cod_oficial": None})

    # ---------- Oferentes de UTC: código interno, SNIES cuando existe ----------
    of = en[en.tipo == "oferente"].sort_values("nombre_normalizado").reset_index(drop=True)
    of["cod_entidad"] = [17001911 + i for i in range(len(of))]
    filas_of = [{"cod_entidad": r.cod_entidad, "entidad": r.nombre_normalizado, "tipo": "oferente",
                 "cod_oficial": SNIES.get(r.nombre_normalizado)} for _, r in of.iterrows()]

    # ---------- Agrupaciones y país ----------
    ag = en[en.tipo == "agrupación"]
    filas_ag = [{"cod_entidad": int(r.cod_entidad), "entidad": r.nombre_normalizado, "tipo": "agrupación",
                 "cod_oficial": None} for _, r in ag.iterrows()]
    filas_ag.append({"cod_entidad": 57, "entidad": "Colombia", "tipo": "país", "cod_oficial": "57"})

    # ---------- Entidades territoriales de la maestra ----------
    ce = pd.read_excel(maestra, sheet_name="catalogo_entidades")
    ce["tipo"] = ce.tipo.str.lower()
    ce["cod_oficial"] = ce.cod_entidad.astype(str)

    ent = pd.concat([ce[["cod_entidad", "entidad", "tipo", "cod_oficial", "latitud", "longitud"]],
                     pd.DataFrame(filas_col + filas_of + filas_ag)], ignore_index=True)
    ent["cod_entidad"] = ent.cod_entidad.astype("int64")
    assert ent.cod_entidad.is_unique, ent[ent.cod_entidad.duplicated(keep=False)]
    ent = ent.sort_values(["tipo", "cod_entidad"])

    # ---------- Proyectos y programas técnicos de UTC ----------
    pr = pd.read_excel(eq, sheet_name="proyectos")[["cod_proyecto", "proyecto", "linea"]]
    asig = pd.read_excel(eq, sheet_name="asignacion_columnas")
    progs = asig.loc[asig.cod_proyecto.astype(str).str.startswith("programa: "), "cod_proyecto"]
    progs = progs.str.replace("programa: ", "", regex=False)

    def kprog(t):
        t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode().lower()
        t = re.sub(r"[^a-z0-9 ]", " ", t)
        t = re.sub(r"\bcadena de logistica\b", "cadena logistica", t)
        return " ".join(w for w in t.split() if w not in {"de", "la", "en", "y", "el"})

    pg = pd.DataFrame({"variante": progs.unique()})
    pg["k"] = pg.variante.map(kprog)
    # nombre: la variante con menos mayúsculas iniciales (estilo de oración)
    pg["mayus"] = pg.variante.str.count(r"\b[A-ZÁÉÍÓÚ]")
    canon = pg.sort_values(["k", "mayus"]).groupby("k").head(1).sort_values("variante")
    canon = canon.assign(cod_proyecto=[f"PT{i:03d}" for i in range(1, len(canon) + 1)])
    canon["proyecto"] = canon.variante.str.replace(r"\s+", " ", regex=True).str.strip()
    canon.loc[canon.proyecto == "sin identificar el Programa", "proyecto"] = "Programa no identificado"
    canon["linea"] = "Programas técnicos UTC"
    prog_cod = pg.merge(canon[["k", "cod_proyecto"]], on="k")[["variante", "cod_proyecto"]]
    proy = pd.concat([pr, canon[["cod_proyecto", "proyecto", "linea"]]], ignore_index=True)
    assert proy.cod_proyecto.is_unique

    # ---------- Indicadores ----------
    ind = pd.read_excel(eq, sheet_name="indicadores")
    ind["fecha_actualizacion"] = pd.to_datetime(ind.fecha_actualizacion).dt.date

    # ---------- Asignación de columnas, con códigos resueltos ----------
    ref_cod = dict(zip(cruce.entidad_ref, cruce.cod_entidad))
    ref_cod.update(dict(zip(of.nombre_normalizado, of.cod_entidad)))

    def resolver_entidad(r):
        v = str(r.cod_entidad)
        if v == "(igual)":
            return "igual"
        if v in ("DANE del colegio", "SNIES / SIET de la institución"):
            return str(ref_cod[r.entidad_ref])
        return v

    prog_map = dict(zip("programa: " + prog_cod.variante, prog_cod.cod_proyecto))
    asig["cod_entidad"] = asig.apply(resolver_entidad, axis=1)
    asig["cod_proyecto"] = asig.cod_proyecto.map(lambda x: prog_map.get(x, x))
    tnr = pd.DataFrame([{"cod_indicador": c, "categoria": s_, "categoria_2": "Total", "filas": 230, "tabla": "datos",
                         "cod_nuevo": c, "cod_entidad": "igual", "sexo": s_, "zona": "Total",
                         "naturaleza": "Total", "grado": "Total", "edad": "Total", "subconjunto": "Total",
                         "tratamiento": "Agregado después del libro de equivalencias (rutina 10_uso_tiempo)"}
                        for c in ("TNR_01", "TNR_02") for s_ in ("Hombre", "Mujer", "Total")])
    asig = pd.concat([asig, tnr], ignore_index=True)
    asig = asig.drop(columns=["entidad_ref", "filas"])

    CAT.mkdir(exist_ok=True)
    ind.to_csv(CAT / "indicadores.csv", index=False, encoding="utf-8")
    ent.to_csv(CAT / "entidades.csv", index=False, encoding="utf-8")
    proy.to_csv(CAT / "proyectos.csv", index=False, encoding="utf-8")
    asig.to_csv(CAT / "asignacion_columnas.csv", index=False, encoding="utf-8")
    recod.to_csv(CAT / "recodificacion_entidades.csv", index=False, encoding="utf-8")
    cruce.merge(ent[["cod_entidad", "entidad"]], on="cod_entidad").rename(
        columns={"entidad_ref": "nombre_en_maestra", "entidad": "entidad_catalogo"}).to_csv(
        CAT / "cruce_colegios.csv", index=False, encoding="utf-8")
    print(f"indicadores {len(ind)} | entidades {len(ent)} | proyectos {len(proy)} | "
          f"asignaciones {len(asig)} | recodificaciones {len(recod)}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dama", required=True, type=Path, help="carpeta dama_indicadores")
    main(ap.parse_args().dama)
