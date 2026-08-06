#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""AOS Sprint 5 — verificador cruzado opcional del indice STEP via FreeCADCmd.

Lee AOS_STEP_INDICE_IN / AOS_STEP_INDICE_OUT del entorno (o argv tras --).
Importa el STEP, emite JSON UTF-8 con nombre, placement y bbox por solido.
No es camino de produccion: solo tests. Nunca debe romper la bateria AOS.
"""
from __future__ import print_function

import json
import os
import sys
import traceback


def _paths():
    step = os.environ.get("AOS_STEP_INDICE_IN", "") or ""
    out = os.environ.get("AOS_STEP_INDICE_OUT", "") or ""
    args = list(sys.argv[1:])
    if "--" in args:
        i = args.index("--")
        args = args[i + 1 :]
    else:
        # Quitar el propio .py si FreeCAD lo deja en argv
        args = [a for a in args if not str(a).lower().endswith(".py")]
    if len(args) >= 1 and not step:
        step = args[0]
    if len(args) >= 2 and not out:
        out = args[1]
    return step, out


def _write(out_path, payload):
    raw = json.dumps(payload, ensure_ascii=False, indent=2)
    if isinstance(raw, bytes):
        data = raw
    else:
        data = raw.encode("utf-8")
    with open(out_path, "wb") as fh:
        fh.write(data)


def _bbox_dict(bb):
    return {
        "xmin": float(bb.XMin),
        "xmax": float(bb.XMax),
        "ymin": float(bb.YMin),
        "ymax": float(bb.YMax),
        "zmin": float(bb.ZMin),
        "zmax": float(bb.ZMax),
    }


def _scale_bbox(bb, factor):
    return {k: float(v) * factor for k, v in bb.items()}


def _vec3(v):
    return [float(v.x), float(v.y), float(v.z)]


def _scale_vec(v, factor):
    return [float(x) * factor for x in v]


def main():
    step, out = _paths()
    if not out:
        # Sin salida no hay forma de reportar; salir con error
        sys.stderr.write("AOS_STEP_INDICE_OUT no definido\n")
        return 2
    if not step or not os.path.isfile(step):
        _write(
            out,
            {
                "ok": False,
                "error": "STEP ausente: %s" % step,
                "productos": [],
            },
        )
        return 1

    try:
        import FreeCAD  # noqa: F401
        import Import
        import Part  # noqa: F401
    except Exception as exc:
        _write(
            out,
            {
                "ok": False,
                "error": "FreeCAD no importable: %s" % exc,
                "productos": [],
            },
        )
        return 1

    # STEP del banco AOS usa SI_UNIT(.MILLI.,.METRE.) → FreeCAD conserva mm.
    factor = 1.0e-3
    try:
        env_f = os.environ.get("AOS_STEP_INDICE_FACTOR", "")
        if env_f:
            factor = float(env_f)
    except Exception:
        factor = 1.0e-3

    doc = None
    try:
        doc = FreeCAD.newDocument("AOS_STEP_INDICE")
        Import.insert(step, doc.Name)
        productos = []
        for obj in doc.Objects:
            if not hasattr(obj, "Shape"):
                continue
            try:
                shape = obj.Shape
            except Exception:
                continue
            if shape is None or shape.isNull():
                continue
            try:
                bb = shape.BoundBox
                pl = obj.Placement
                origen = _vec3(pl.Base)
                bbox = _bbox_dict(bb)
            except Exception:
                continue
            nombre = ""
            try:
                nombre = str(obj.Label)
            except Exception:
                nombre = str(getattr(obj, "Name", "OBJ"))
            productos.append(
                {
                    "nombre": nombre,
                    "placement_origen": origen,
                    "placement_origen_m": _scale_vec(origen, factor),
                    "bbox": bbox,
                    "bbox_m": _scale_bbox(bbox, factor),
                }
            )

        _write(
            out,
            {
                "ok": True,
                "disponible": True,
                "factor_a_metros": factor,
                "unidades_documento": "mm_asumido",
                "n_productos": len(productos),
                "productos": productos,
                "origen": "FreeCADCmd",
            },
        )
        return 0
    except Exception as exc:
        _write(
            out,
            {
                "ok": False,
                "error": "%s" % exc,
                "traceback": traceback.format_exc(),
                "productos": [],
            },
        )
        return 1
    finally:
        try:
            if doc is not None:
                FreeCAD.closeDocument(doc.Name)
        except Exception:
            pass


if __name__ == "__main__":
    try:
        code = main()
    except Exception as exc:
        # Ultimo recurso: intentar escribir error si hay OUT
        _, out = _paths()
        if out:
            try:
                _write(
                    out,
                    {
                        "ok": False,
                        "error": "excepcion no controlada: %s" % exc,
                        "productos": [],
                    },
                )
            except Exception:
                pass
        code = 1
    sys.exit(code)
