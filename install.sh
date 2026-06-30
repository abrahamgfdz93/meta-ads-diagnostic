#!/usr/bin/env bash
# Instalador de Meta Ads Diagnostic
set -e

echo "📊 Instalando Meta Ads Diagnostic..."

# 1. Verificar Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ Python 3 no está instalado."
  echo "   macOS:   brew install python3"
  echo "   Windows: descárgalo de https://www.python.org/downloads/"
  exit 1
fi
echo "✅ Python 3 detectado: $(python3 --version)"

# 2. Crear carpetas de trabajo (vacías, no se versionan)
mkdir -p analyser output
echo "✅ Carpetas analyser/ y output/ listas"

# 3. Registrar la skill en Claude Code (si existe el comando)
SKILL_SRC="COMPARTIR/meta-ads-diagnostic.md"
SKILL_DIR="$HOME/.claude/commands"
if [ -f "$SKILL_SRC" ]; then
  mkdir -p "$SKILL_DIR"
  cp "$SKILL_SRC" "$SKILL_DIR/meta-ads-diagnostic.md"
  echo "✅ Skill registrada: usa /meta-ads-diagnostic en Claude Code"
else
  echo "ℹ️  Skill no encontrada; puedes usar el dashboard abriendo index.html"
fi

echo ""
echo "🎉 Listo. Coloca tus CSV en analyser/<cuenta>/<periodo>/ y ejecuta /meta-ads-diagnostic"
echo "   (o abre index.html en Chrome para el modo drag & drop)."
