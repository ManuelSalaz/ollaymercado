#!/usr/bin/env python3
"""Actualiza los precios de la app con los precios del día de la app de ARA.

NO recorre categorías: repite solo las búsquedas de tus ingredientes y, para
cada uno, encuentra el producto por su código (araId) y lee su precio actual.

Uso normal (una vez por semana):
  1. Con el proxy corriendo, abre la app de ARA y haz UNA búsqueda cualquiera
     (eso deja un token de sesión fresco en la carpeta de capturas).
  2. python3 tools/actualizar_precios_ara.py
     -> consulta ARA, reescribe los precios en Sources/OllaYMercado/Catalog.swift
        y te muestra qué cambió.

Opciones:
  --captura <dir>   Carpeta de capturas de mitmproxy (def: ~/captura_ara)
  --dry             No escribe el Catalog, solo muestra qué cambiaría
  --demo            No usa la red: lee los precios de las capturas (para probar)
"""
import argparse
import glob
import json
import os
import re
import sys
import urllib.parse
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOGO = os.path.join(RAIZ, "Sources", "OllaYMercado", "Catalog.swift")
MAPA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ara_productos.json")


def capturas(carpeta):
    files = glob.glob(os.path.join(carpeta, "*products_search*.json"))
    if not files:
        sys.exit(f"No hay capturas de búsqueda en {carpeta}. Abre la app de ARA y haz una búsqueda con el proxy activo.")
    return sorted(files, key=os.path.getmtime, reverse=True)


def sesion(carpeta):
    """Lee token, clave y URL base de la captura más reciente."""
    for f in capturas(carpeta):
        d = json.load(open(f, encoding="utf-8"))
        hdrs = {k.lower(): v for k, v in d.get("request_headers", {}).items()}
        auth = hdrs.get("authorization")
        url = d.get("url", "")
        m = re.search(r"(https://[^/]+).*?[?&]key=([^&]+)", url)
        if auth and m:
            return auth, m.group(1), m.group(2)
    sys.exit("No encontré un token de sesión en las capturas. Abre la app de ARA (ya con sesión iniciada) y haz una búsqueda.")


def precios_demo(carpeta):
    """Precio de cada producto tal como quedó en las capturas (sin red)."""
    por_id = {}
    for f in capturas(carpeta):
        d = json.load(open(f, encoding="utf-8"))
        for p in (d.get("response", {}).get("data") or []):
            por_id.setdefault(p["id"], p.get("price"))
    return lambda araId, query: por_id.get(araId)


def precios_red(carpeta):
    auth, base, key = sesion(carpeta)

    def consulta(araId, query):
        url = f"{base}/products-search?query={urllib.parse.quote(query)}&storeId=default-store&key={key}&limit=15"
        req = urllib.request.Request(url, headers={"Authorization": auth, "Accept": "application/json",
                                                    "User-Agent": "OllaYMercado/actualizador"})
        with urllib.request.urlopen(req, timeout=20) as r:
            data = json.load(r).get("data") or []
        for p in data:
            if p.get("id") == araId:
                return p.get("price")
        return None

    return consulta


def fijar_precio(texto, item, nuevo):
    pat = re.compile(r'(it\("' + re.escape(item) + r'",\s*"(?:[^"\\]|\\.)*",\s*"[^"]*",\s*[0-9.]+,\s*"[^"]*",\s*)(\d+)')
    nuevos = [None]

    def repl(m):
        nuevos[0] = int(m.group(2))
        return m.group(1) + str(nuevo)

    texto2, n = pat.subn(repl, texto, count=1)
    return texto2, (nuevos[0] if n else None)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--captura", default=os.path.expanduser("~/captura_ara"))
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--demo", action="store_true")
    args = ap.parse_args()

    mapa = json.load(open(MAPA, encoding="utf-8"))
    consulta = precios_demo(args.captura) if args.demo else precios_red(args.captura)
    texto = open(CATALOGO, encoding="utf-8").read()

    cambios, iguales, fallos = [], 0, []
    for item, info in sorted(mapa.items()):
        try:
            nuevo = consulta(info["araId"], info["query"])
        except Exception as e:
            fallos.append(f"{item}: error de consulta ({e})")
            continue
        if not nuevo:
            fallos.append(f"{item}: no encontré el producto (código {info['araId']})")
            continue
        texto, viejo = fijar_precio(texto, item, nuevo)
        if viejo is None:
            fallos.append(f"{item}: no está en Catalog.swift")
        elif viejo != nuevo:
            cambios.append((item, viejo, nuevo))
        else:
            iguales += 1

    print(f"\n{len(cambios)} precios cambiaron, {iguales} iguales, {len(fallos)} sin resolver.\n")
    for item, v, n in cambios:
        flecha = "▲" if n > v else "▼"
        print(f"  {flecha} {item:12} {v:>7} -> {n:>7}")
    for f in fallos:
        print("  ! " + f)

    if cambios and not args.dry:
        open(CATALOGO, "w", encoding="utf-8").write(texto)
        print(f"\nCatalog.swift actualizado. Ahora súbelo para recompilar:\n  cd {RAIZ} && git commit -am 'precios ARA' && git push")
    elif args.dry:
        print("\n(--dry: no escribí nada)")
    else:
        print("\nNada que cambiar.")


if __name__ == "__main__":
    main()
