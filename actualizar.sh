#!/bin/sh
# Refresca los precios con los de la app de ARA y recompila.
# ANTES de correr esto: con el proxy activo, abre la app de ARA y haz UNA búsqueda
# cualquiera (eso deja una sesión fresca). Luego corre este comando.
set -e
cd "$(dirname "$0")"
python3 tools/actualizar_precios_ara.py "$@"
if ! git diff --quiet Sources/OllaYMercado/Catalog.swift; then
  git commit -qam "Precios ARA $(date +%F)"
  git push -q
  echo ""
  echo "Subido. GitHub está recompilando (~5-10 min)."
  echo "Cuando termine, conecta el iPhone y corre:  ./instalar.sh"
fi
