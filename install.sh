#!/usr/bin/env bash
# Instalador de Meta Ads Diagnostic
set -e

# Carpeta real donde vive este repo (donde el usuario lo clonó)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📊 Instalando Meta Ads Diagnostic..."
echo "   Proyecto: $PROJECT_DIR"

# 1. Verificar Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ Python 3 no está instalado."
  echo "   macOS:   brew install python3"
  echo "   Windows: descárgalo de https://www.python.org/downloads/"
  exit 1
fi
echo "✅ Python 3 detectado: $(python3 --version)"

# 2. Crear carpetas de trabajo (vacías, no se versionan)
mkdir -p "$PROJECT_DIR/analyser" "$PROJECT_DIR/output"
echo "✅ Carpetas analyser/ y output/ listas"

# 3. Registrar la skill en Claude Code, apuntando a ESTA carpeta
SKILL_SRC="$PROJECT_DIR/skill/meta-ads-diagnostic.md"
SKILL_DIR="$HOME/.claude/commands"
if [ -f "$SKILL_SRC" ]; then
  mkdir -p "$SKILL_DIR"
  # Sustituye el marcador __PROJECT_DIR__ por la ruta real del clon
  sed "s|__PROJECT_DIR__|$PROJECT_DIR|g" "$SKILL_SRC" > "$SKILL_DIR/meta-ads-diagnostic.md"
  echo "✅ Skill instalada en $SKILL_DIR/meta-ads-diagnostic.md"
  echo "   Ruta del proyecto embebida: $PROJECT_DIR"
else
  echo "⚠️  No se encontró skill/meta-ads-diagnostic.md — revisa el repo."
fi

echo ""
echo "🎉 Listo."
echo "   1. Coloca tus CSV en: $PROJECT_DIR/analyser/<cuenta>/<periodo>/"
echo "   2. En Claude Code ejecuta: /meta-ads-diagnostic"
echo "   (o abre index.html en Chrome para el modo drag & drop, sin IA)"
