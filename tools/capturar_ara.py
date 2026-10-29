"""Addon de mitmproxy: guarda el tráfico que hace la app de ARA.

Uso: mitmdump -s tools/capturar_ara.py --set captura=/ruta/carpeta

- indice.log: una línea por petición (método, URL, estado, tipo, tamaño) y por
  cada fallo de TLS, que delata certificate pinning.
- Un archivo por respuesta con cuerpo de texto (JSON, GraphQL, HTML, etc.) o
  binario (.bin, por si es protobuf), para encontrar el endpoint de precios.
"""
import json
import os
import re
import time

from mitmproxy import ctx, http, tls

# Solo analítica y apps ajenas; los dominios de Google/Firebase se guardan porque el catálogo puede vivir ahí
RUIDO = re.compile(r"(google-analytics|googleadservices|googletagmanager|googlesyndication|doubleclick|apple\.com|icloud|"
                   r"facebook|crashlytics|firebaseinstallations|app-measurement|branch\.io|appsflyer|adjust\.com|sentry|"
                   r"mzstatic|spotify|whatsapp|instagram|tiktok|cdninstagram|marketingcloudapis|media\.aratiendas)", re.I)


def load(loader):
    loader.add_option("captura", str, "captura_ara", "Carpeta donde guardar las respuestas")


def _indice(linea: str):
    os.makedirs(ctx.options.captura, exist_ok=True)
    with open(os.path.join(ctx.options.captura, "indice.log"), "a", encoding="utf-8") as f:
        f.write(time.strftime("%H:%M:%S ") + linea + "\n")


def tls_failed_client(data: tls.TlsData):
    sni = data.context.client.sni or "?"
    if not RUIDO.search(sni):
        _indice(f"TLS-FALLÓ {sni}: {data.conn.error}")
        ctx.log.info(f"[ARA] TLS FALLÓ con {sni} (posible pinning)")


def response(flow: http.HTTPFlow):
    host = flow.request.pretty_host
    if RUIDO.search(host):
        return
    ctype = flow.response.headers.get("content-type", "")
    contenido = flow.response.content or b""
    _indice(f"{flow.request.method} {flow.request.pretty_url} -> {flow.response.status_code} [{ctype}] {len(contenido)} B")
    ctx.log.info(f"[ARA] {flow.request.method} {flow.request.pretty_url} -> {flow.response.status_code} [{ctype}]")

    if not contenido or re.search(r"image|font|video|audio|css|javascript", ctype):
        return
    base = f"{time.time():.3f}_{host}_{re.sub(r'[^a-zA-Z0-9]+', '_', flow.request.path)[:80]}"
    carpeta = ctx.options.captura
    try:
        texto = contenido.decode("utf-8")
    except UnicodeDecodeError:
        texto = None
    if texto is None:
        with open(os.path.join(carpeta, base + ".bin"), "wb") as f:
            f.write(contenido)
        cuerpo = f"<binario, ver {base}.bin>"
    else:
        try:
            cuerpo = json.loads(texto)
        except ValueError:
            cuerpo = texto
    registro = {
        "method": flow.request.method,
        "url": flow.request.pretty_url,
        "status": flow.response.status_code,
        "content_type": ctype,
        "request_headers": dict(flow.request.headers),
        "request_body": flow.request.get_text(strict=False),
        "response": cuerpo,
    }
    with open(os.path.join(carpeta, base + ".json"), "w", encoding="utf-8") as f:
        json.dump(registro, f, ensure_ascii=False, indent=1)
