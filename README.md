# 📊 Meta Ads Diagnostic

Analiza los CSV exportados de **Meta Ads** y genera un dashboard HTML con un diagnóstico completo por cuenta: semáforos de salud, causa raíz por anuncio, ganadores/perdedores, KPIs y gráficas. El trabajo mecánico (parseo, semáforos, HTML) lo hace `generator.py`; el análisis cualitativo lo escribe la IA desde Claude Code.

> Pensado para equipos de marketing/performance que necesitan pasar de un CSV crudo de Meta a un reporte ejecutivo claro en ~2-3 minutos.

## ✨ Características

- **Dos modos de uso:** skill con IA (`/meta-ads-diagnostic`) o dashboard interactivo standalone (`index.html`, drag & drop).
- **Semáforo de 4 niveles por anuncio**, evaluado en contexto de cada campaña (no con umbrales absolutos).
- **Causa raíz por anuncio** en 3 ejes: Origen del problema · Configuración Ads · Dirección Creativa.
- **Ganadores / Perdedores** por CPA + volumen, KPIs globales y KPI comparativa lado a lado.
- **Detección automática del tipo de campaña** (Captación / Retención / Reactivación) con color por tipo.
- **Gráficas Chart.js**: ROAS, costo por resultado, distribución de gasto, frecuencia y top mejores/peores anuncios.
- **Sin dependencias externas** — solo Python 3 (librería estándar). HTML autocontenido.

## 📦 Requisitos

- **Python 3** (incluido en macOS/Linux; en Windows descargar de python.org). No requiere `pip install` de nada.
- Para el modo con IA: **Claude Code**.
- Para el dashboard backup: un navegador moderno (Chrome recomendado).

## 🚀 Instalación

```bash
git clone https://github.com/abrahamgfdz93/meta-ads-diagnostic.git
cd meta-ads-diagnostic
./install.sh
```

El instalador verifica Python 3 y registra el comando `/meta-ads-diagnostic` en Claude Code (`~/.claude/commands/`).

> ¿Sin Claude Code? Igual puedes usar el dashboard: abre `index.html` en Chrome y arrastra tus CSV.

## 🧭 Uso

**Con IA (recomendado):**

1. Coloca los CSV de Meta en `analyser/{cuenta}/{periodo}/` (el nombre del periodo es libre).
2. En Claude Code escribe `/meta-ads-diagnostic` (o `/meta-ads-diagnostic bet4-br`).
3. Espera ~2-3 min. El reporte HTML se genera en `output/{cuenta}/` y se abre solo.

**Modo manual (sin IA):**

```bash
# Parsear CSV → JSON estructurado (semáforos, KPIs, benchmarks)
python3 generator.py parse <cuenta> <periodo>

# Generar el HTML final a partir de un análisis JSON
python3 generator.py generate <cuenta> <periodo> --analysis analysis.json --open
```

## 📁 Estructura

```
meta-ads-diagnostic/
├── generator.py        # Motor: parseo CSV + generación del HTML
├── template.html       # Plantilla del dashboard (CSS/JS/layout)
├── index.html          # Dashboard interactivo standalone (drag & drop)
├── assets/logos/       # Logos por cuenta (logo.png)
├── docs/               # Diseño y specs del proyecto
└── COMPARTIR-v2/       # Kit de instalación para compartir con un equipo
```

> **Nota de privacidad:** las carpetas `analyser/` (CSV reales) y `output/` (reportes generados) están en `.gitignore`. Nunca subas datos de campañas reales a un repo público.

## 🗂️ Formato de los CSV de Meta

El parser espera el export estándar de Meta Ads (resumen de campañas y/o anuncios individuales) y corrige automáticamente los problemas de encoding UTF-8 típicos (ej. `campaÃ±a`). Las columnas esperadas están documentadas en [CLAUDE.md](CLAUDE.md).

## 📄 Licencia

MIT — ver [LICENSE](LICENSE).
