#!/bin/sh
# Descarga el último .ipa compilado en GitHub y lo instala en el iPhone conectado.
# Úsalo cada 7 días (la firma de la cuenta gratuita de Apple vence).
set -e
tmp=$(mktemp -d)
curl -fsSL -o "$tmp/OllaYMercado.ipa" https://github.com/ManuelSalaz/ollaymercado/releases/download/latest-ios/OllaYMercado.ipa
xtool install --usb "$tmp/OllaYMercado.ipa"
rm -rf "$tmp"
