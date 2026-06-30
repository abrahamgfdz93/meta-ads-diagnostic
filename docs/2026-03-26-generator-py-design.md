# generator.py Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Python script that handles CSV parsing, rule-based analysis, and HTML generation for Meta Ads diagnostics — reducing report generation from ~7 min to ~2-3 min.

**Architecture:** Two-mode CLI script (`--parse` for data extraction, `--generate` for HTML output). Python handles all mechanical work (parsing, KPIs, semaphores, HTML). The LLM only writes qualitative analysis as a JSON file that Python injects into the template.

**Tech Stack:** Python 3 stdlib (csv, json, argparse, base64, os, pathlib). No external dependencies.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `generator.py` | Create | Main script: CSV parsing, analysis engine, HTML generation, CLI |
| `meta-ads-diagnostic.md` | Modify (`~/.claude/commands/`) | Update skill to use generator.py |
| `CLAUDE.md` | Modify (project root) | Document new flow |

## JSON Schema — LLM Analysis Input

The LLM writes this JSON after reviewing the `--parse` output. Generator reads it for `--generate`.

```json
{
  "campaigns": {
    "<campaign_name>": {
      "diagnosis": "Texto de diagnóstico de la campaña",
      "main_problem": "Problema principal en una frase",
      "immediate_action": "Acción inmediata específica",
      "creative_analysis": {
        "verdict": "NO|SÍ|PARCIAL",
        "explanation": "Explicación contextual"
      },
      "strategy": [
        {"aspect": "Objetivo", "current": "...", "recommendation": "..."},
        {"aspect": "Problema/Fortaleza", "current": "...", "recommendation": "..."},
        {"aspect": "Creativos", "current": "...", "recommendation": "..."},
        {"aspect": "Segmentación", "current": "...", "recommendation": "..."},
        {"aspect": "Mensaje recomendado", "current": "...", "recommendation": "..."},
        {"aspect": "KPI a monitorear", "current": "...", "recommendation": "..."}
      ]
    }
  },
  "ads": {
    "<ad_name>": {
      "root_cause": "Origen del problema contextual",
      "config_ads": "Qué cambiar en Meta Ads Manager",
      "creative_direction": "Qué hacer con los creativos"
    }
  },
  "executive_note": "Nota ejecutiva completa para directivos",
  "top5_actions": [
    {
      "action": "Descripción de la acción quirúrgica",
      "impact": "Impacto estimado (ahorro/mejora)",
      "responsible": "Configuración Ads|Dirección Creativa|Ambas áreas"
    }
  ]
}
```

**Note on duplicate ad names:** If two ads share the same name (e.g., "Revivir Ina C Web-App +16"), the `--parse` output will label them with suffixes `(A)`, `(B)`, etc. The LLM must use these suffixed keys in the JSON. Generator matches by these keys.

---

## Chunk 1: Core Script — CSV Parsing + Data Model

### Task 1: Create generator.py with CLI skeleton and constants

**Files:**
- Create: `generator.py`

- [ ] **Step 1: Create generator.py with argparse CLI, casino config, and encoding fixes**

```python
#!/usr/bin/env python3
"""Meta Ads Diagnostic Generator — Parses CSVs and generates HTML dashboards."""

import argparse
import csv
import json
import base64
import os
import sys
from pathlib import Path
from io import StringIO

# === CONSTANTS ===

BASE_DIR = Path(__file__).parent
TEMPLATE_PATH = BASE_DIR / "template.html"
ANALYSER_DIR = BASE_DIR / "analyser"
OUTPUT_DIR = BASE_DIR / "output"
LOGOS_DIR = BASE_DIR / "assets" / "logos"

CASINOS = {
    "bmx":      {"name": "Betmexico",    "currency": "MXN", "symbol": "$",  "country": "México"},
    "bet4-pe":  {"name": "Bet4 Perú",    "currency": "MXN", "symbol": "$",  "country": "Perú"},
    "bet4-br":  {"name": "Bet4 Brasil",   "currency": "BRL", "symbol": "R$", "country": "Brasil"},
    "aposta":   {"name": "Aposta",        "currency": "BRL", "symbol": "R$", "country": "Brasil"},
    "fazo":     {"name": "Fazo",          "currency": "BRL", "symbol": "R$", "country": "Brasil"},
    "casinito": {"name": "Casinito",      "currency": "TBD", "symbol": "$",  "country": "TBD"},
}

ENCODING_FIXES = {
    "campaÃ±a": "campaña", "FinalizaciÃ³n": "Finalización",
    "ConfiguraciÃ³n": "Configuración", "atribuciÃ³n": "atribución",
    "inversiÃ³n": "inversión", "interacciÃ³n": "interacción",
    "ClasificaciÃ³n": "Clasificación", "Ãltimo": "Último",
}

CAMPAIGN_COLORS = {
    "captacion": {"badge": "badge-red", "dot": "dot-red", "chart": "#DC2626"},
    "retencion": {"badge": "badge-blue", "dot": "dot-blue", "chart": "#2563EB"},
    "reactivacion": {"badge": "badge-purple", "dot": "dot-purple", "chart": "#7C3AED"},
}


def fix_encoding(text):
    for bad, good in ENCODING_FIXES.items():
        text = text.replace(bad, good)
    return text


def classify_campaign(name):
    lower = name.lower()
    if any(k in lower for k in ["retener", "retarget", "retención"]):
        return "retencion"
    if any(k in lower for k in ["reactivar", "revivir", "reactivación"]):
        return "reactivacion"
    if "all" in lower:
        return "captacion"
    return "captacion"  # default


def parse_csv_file(filepath):
    raw = filepath.read_text(encoding="utf-8")
    raw = fix_encoding(raw)
    reader = csv.DictReader(StringIO(raw))
    rows = []
    for row in reader:
        rows.append(row)
    return rows


def safe_float(val, default=0.0):
    if not val or val == "-":
        return default
    try:
        return float(val.replace(",", ""))
    except (ValueError, AttributeError):
        return default


def safe_int(val, default=0):
    return int(safe_float(val, default))


def fmt_number(n):
    if isinstance(n, float):
        if n == int(n) and n > 100:
            return f"{int(n):,}"
        if n >= 100:
            return f"{n:,.2f}"
        return f"{n:.2f}"
    return f"{n:,}"


def fmt_money(n, symbol="$"):
    return f"{symbol}{fmt_number(n)}"


def main():
    parser = argparse.ArgumentParser(description="Meta Ads Diagnostic Generator")
    sub = parser.add_subparsers(dest="mode", required=True)

    p_parse = sub.add_parser("parse", help="Parse CSVs and output structured summary")
    p_parse.add_argument("casino", choices=CASINOS.keys())
    p_parse.add_argument("period", help="Period folder name")

    p_gen = sub.add_parser("generate", help="Generate HTML dashboard")
    p_gen.add_argument("casino", choices=CASINOS.keys())
    p_gen.add_argument("period", help="Period folder name")
    p_gen.add_argument("--analysis", required=True, help="Path to LLM analysis JSON")

    args = parser.parse_args()

    if args.mode == "parse":
        run_parse(args.casino, args.period)
    elif args.mode == "generate":
        run_generate(args.casino, args.period, args.analysis)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Verify CLI skeleton works**

Run: `cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic && python3 generator.py parse bmx 260326`
Expected: Error about `run_parse` not defined (skeleton works, function missing)

---

### Task 2: Implement CSV parsing and data model (`run_parse`)

**Files:**
- Modify: `generator.py`

- [ ] **Step 3: Add run_parse function that reads all CSVs and builds structured data**

Add after `fmt_money` function, before `main()`:

```python
def load_campaign_csvs(casino_id, period):
    """Load all CSVs from the period folder and return structured data."""
    period_dir = ANALYSER_DIR / casino_id / period
    if not period_dir.exists():
        print(f"ERROR: No existe la carpeta {period_dir}", file=sys.stderr)
        sys.exit(1)

    csv_files = sorted(period_dir.glob("*.csv"))
    if not csv_files:
        print(f"ERROR: No hay CSV en {period_dir}", file=sys.stderr)
        sys.exit(1)

    global_rows = []
    campaign_ads = {}  # campaign_type -> list of ad rows

    for f in csv_files:
        rows = parse_csv_file(f)
        if not rows:
            continue
        # Detect if global (has "Nombre de la campaña") or per-campaign (has "Nombre del anuncio")
        headers = list(rows[0].keys())
        if any("Nombre de la campaña" in h for h in headers):
            global_rows = rows
        elif any("Nombre del anuncio" in h for h in headers):
            # Determine campaign type from filename
            fname = f.stem.lower()
            if "captacion" in fname:
                campaign_ads["captacion"] = rows
            elif "retencion" in fname:
                campaign_ads["retencion"] = rows
            elif "reactivacion" in fname:
                campaign_ads["reactivacion"] = rows
            else:
                # Try to detect from ad data
                campaign_ads[fname] = rows

    return global_rows, campaign_ads


def build_data_model(global_rows, campaign_ads, casino_info):
    """Build structured data model from raw CSV rows."""
    symbol = casino_info["symbol"]

    # --- Parse campaigns from global CSV ---
    campaigns = []
    for row in global_rows:
        name = row.get("Nombre de la campaña", "")
        status = row.get("Entrega de la campaña", "")
        camp = {
            "name": name,
            "status": status,
            "type": classify_campaign(name),
            "results": safe_int(row.get("Resultados", 0)),
            "result_indicator": row.get("Indicador de resultado", ""),
            "cost_per_result": safe_float(row.get("Costo por resultados", 0)),
            "budget": row.get("Presupuesto del conjunto de anuncios", ""),
            "budget_type": row.get("Tipo de presupuesto del conjunto de anuncios", ""),
            "spend": safe_float(row.get(f"Importe gastado ({casino_info['currency']})", 0)),
            "impressions": safe_int(row.get("Impresiones", 0)),
            "reach": safe_int(row.get("Alcance", 0)),
            "frequency": safe_float(row.get("Frecuencia", 0)),
            "cpm": safe_float(row.get(f"CPM (costo por mil impresiones) ({casino_info['currency']})", 0)),
            "purchases": safe_int(row.get("Compras", 0)),
            "finalization": row.get("Finalización", ""),
            "attribution": row.get("Configuración de atribución", ""),
            "roas": safe_float(row.get("ROAS (retorno de la inversión en publicidad) de compras", 0)),
        }
        # Determine metric label
        if "registration" in camp["result_indicator"]:
            camp["metric_label"] = "registros"
        else:
            camp["metric_label"] = "compras"
        campaigns.append(camp)

    # Separate active vs archived/inactive
    active = [c for c in campaigns if c["status"] == "active"]
    inactive = [c for c in campaigns if c["status"] != "active"]

    # --- Parse ads from per-campaign CSVs ---
    all_ads = []
    for ctype, rows in campaign_ads.items():
        # Track duplicate names for suffixing
        name_count = {}
        for row in rows:
            raw_name = row.get("Nombre del anuncio", "")
            name_count[raw_name] = name_count.get(raw_name, 0) + 1

        name_seen = {}
        for row in rows:
            raw_name = row.get("Nombre del anuncio", "")
            # Suffix duplicates
            if name_count[raw_name] > 1:
                name_seen[raw_name] = name_seen.get(raw_name, 0) + 1
                suffix = chr(64 + name_seen[raw_name])  # A, B, C...
                display_name = f"{raw_name} ({suffix})"
            else:
                display_name = raw_name

            ad = {
                "name": display_name,
                "raw_name": raw_name,
                "campaign_type": ctype,
                "status": row.get("Entrega del anuncio", ""),
                "results": safe_int(row.get("Resultados", 0)),
                "result_indicator": row.get("Indicador de resultado", ""),
                "cost_per_result": safe_float(row.get("Costo por resultados", 0)),
                "budget": row.get("Presupuesto del conjunto de anuncios", ""),
                "budget_type": row.get("Tipo de presupuesto del conjunto de anuncios", ""),
                "spend": safe_float(row.get(f"Importe gastado ({casino_info['currency']})", 0)),
                "impressions": safe_int(row.get("Impresiones", 0)),
                "reach": safe_int(row.get("Alcance", 0)),
                "frequency": safe_float(row.get("Frecuencia", 0)),
                "cpm": safe_float(row.get(f"CPM (costo por mil impresiones) ({casino_info['currency']})", 0)),
                "purchases": safe_int(row.get("Compras", 0)),
                "roas": safe_float(row.get("ROAS (retorno de la inversión en publicidad) de compras", 0)),
                "bid": row.get("Puja", "-"),
                "bid_type": row.get("Tipo de puja", ""),
                "last_change": row.get("Último cambio significativo", "-"),
                "quality": row.get("Clasificación de calidad", "-"),
                "engagement": row.get("Clasificación del porcentaje de interacción", "-"),
                "conversion": row.get("Clasificación del porcentaje de conversiones", "-"),
                "ad_set": row.get("Nombre del conjunto de anuncios", ""),
            }
            all_ads.append(ad)

    # --- Get date range ---
    date_start = global_rows[0].get("Inicio del informe", "") if global_rows else ""
    date_end = global_rows[0].get("Fin del informe", "") if global_rows else ""

    return {
        "date_start": date_start,
        "date_end": date_end,
        "campaigns_active": active,
        "campaigns_inactive": inactive,
        "ads": all_ads,
    }


def run_parse(casino_id, period):
    """Parse CSVs and print structured summary for LLM analysis."""
    casino_info = CASINOS[casino_id]
    global_rows, campaign_ads = load_campaign_csvs(casino_id, period)
    data = build_data_model(global_rows, campaign_ads, casino_info)

    # Compute KPIs and semaphores
    data = compute_analysis(data, casino_info)

    # Output as JSON for LLM to read
    output = {
        "casino": casino_info,
        "casino_id": casino_id,
        "period": period,
        "date_range": f"{data['date_start']} al {data['date_end']}",
        "active_campaigns": [],
        "inactive_campaigns": [],
    }

    for camp in data["campaigns_active"]:
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp["type"]]
        c = {
            "name": camp["name"],
            "type": camp["type"],
            "type_label": {"captacion": "Captación", "retencion": "Retención", "reactivacion": "Reactivación"}[camp["type"]],
            "status_label": camp.get("status_label", ""),
            "status_emoji": camp.get("status_emoji", ""),
            "results": camp["results"],
            "metric_label": camp["metric_label"],
            "cost_per_result": camp["cost_per_result"],
            "spend": camp["spend"],
            "roas": camp["roas"],
            "impressions": camp["impressions"],
            "frequency": camp["frequency"],
            "cpm": camp["cpm"],
            "purchases": camp["purchases"],
            "ads": [],
        }
        for ad in camp_ads:
            c["ads"].append({
                "name": ad["name"],
                "status": ad["status"],
                "semaphore": ad.get("semaphore", ""),
                "semaphore_label": ad.get("semaphore_label", ""),
                "is_benchmark": ad.get("is_benchmark", False),
                "results": ad["results"],
                "cost_per_result": ad["cost_per_result"],
                "spend": ad["spend"],
                "roas": ad["roas"],
                "impressions": ad["impressions"],
                "frequency": ad["frequency"],
                "cpm": ad["cpm"],
                "bid": ad["bid"],
                "quality": ad["quality"],
                "engagement": ad["engagement"],
                "conversion": ad["conversion"],
                "gp_verdict": ad.get("gp_verdict", ""),
                "gp_label": ad.get("gp_label", ""),
            })
        output["active_campaigns"].append(c)

    for camp in data["campaigns_inactive"]:
        output["inactive_campaigns"].append({
            "name": camp["name"],
            "status": camp["status"],
            "results": camp["results"],
            "spend": camp["spend"],
            "roas": camp["roas"],
        })

    # Global KPIs
    total_spend = sum(c["spend"] for c in data["campaigns_active"])
    total_revenue = sum(c["spend"] * c["roas"] for c in data["campaigns_active"])
    weighted_roas = total_revenue / total_spend if total_spend > 0 else 0
    avg_cpm = sum(c["cpm"] for c in data["campaigns_active"]) / len(data["campaigns_active"]) if data["campaigns_active"] else 0

    output["global_kpis"] = {
        "total_spend": total_spend,
        "weighted_roas": round(weighted_roas, 2),
        "avg_cpm": round(avg_cpm, 2),
        "total_results_by_type": {},
    }
    for camp in data["campaigns_active"]:
        label = camp["metric_label"]
        output["global_kpis"]["total_results_by_type"][label] = (
            output["global_kpis"]["total_results_by_type"].get(label, 0) + camp["results"]
        )

    print(json.dumps(output, indent=2, ensure_ascii=False))
```

- [ ] **Step 4: Verify parse mode works with real data**

Run: `cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic && python3 generator.py parse bmx 260326`
Expected: Error about `compute_analysis` not defined (parsing works, analysis function missing)

---

### Task 3: Implement rule-based analysis engine

**Files:**
- Modify: `generator.py`

- [ ] **Step 5: Add compute_analysis function with semaphores, benchmarks, ganadores/perdedores**

Add before `run_parse`:

```python
def compute_analysis(data, casino_info):
    """Apply rule-based analysis: semaphores, benchmarks, ganadores/perdedores, campaign status."""

    for camp in data["campaigns_active"]:
        camp_type = camp["type"]
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp_type]
        active_ads = [a for a in camp_ads if a["status"] == "active"]

        # --- BENCHMARK: best ROAS in campaign ---
        if active_ads:
            best = max(active_ads, key=lambda a: a["roas"])
            for ad in camp_ads:
                ad["is_benchmark"] = (ad["name"] == best["name"] and ad["status"] == "active")

        # --- SEMAPHORE per ad (4 levels, relative to campaign) ---
        avg_cpm = sum(a["cpm"] for a in active_ads) / len(active_ads) if active_ads else 0

        for ad in camp_ads:
            if ad["status"] != "active":
                ad["semaphore"] = "gray"
                ad["semaphore_label"] = "Inactivo"
                ad["semaphore_emoji"] = "⚪"
                continue

            quality = ad.get("quality", "-")
            has_penalty = quality != "-" and "por debajo" in quality.lower() if quality else False

            # 🔴 PAUSAR YA
            if has_penalty:
                ad["semaphore"] = "red"
                ad["semaphore_label"] = "PAUSAR YA"
                ad["semaphore_emoji"] = "🔴"
            elif ad["spend"] > 0 and ad["results"] == 0 and ad["spend"] > camp["spend"] * 0.05:
                ad["semaphore"] = "red"
                ad["semaphore_label"] = "PAUSAR YA"
                ad["semaphore_emoji"] = "🔴"
            elif ad["roas"] < 0.3 and ad["spend"] > camp["spend"] * 0.05:
                ad["semaphore"] = "red"
                ad["semaphore_label"] = "PAUSAR YA"
                ad["semaphore_emoji"] = "🔴"
            # 🟠 Pausar
            elif ad["roas"] < 1.0 and ad["spend"] > camp["spend"] * 0.05:
                ad["semaphore"] = "orange"
                ad["semaphore_label"] = "Pausar"
                ad["semaphore_emoji"] = "🟠"
            elif ad["results"] < 50 and ad["spend"] > camp["spend"] * 0.05:
                ad["semaphore"] = "orange"
                ad["semaphore_label"] = "Pausar"
                ad["semaphore_emoji"] = "🟠"
            # 🟡 Monitorear
            elif ad["frequency"] > 7 or (avg_cpm > 0 and ad["cpm"] > avg_cpm * 1.5):
                ad["semaphore"] = "yellow"
                ad["semaphore_label"] = "Monitorear"
                ad["semaphore_emoji"] = "🟡"
            elif 1.0 <= ad["roas"] <= 5.0:
                ad["semaphore"] = "yellow"
                ad["semaphore_label"] = "Monitorear"
                ad["semaphore_emoji"] = "🟡"
            # 🟢 Óptimo
            else:
                ad["semaphore"] = "green"
                ad["semaphore_label"] = "Óptimo"
                ad["semaphore_emoji"] = "🟢"

        # --- GANADORES/PERDEDORES (CPA relative + volume) ---
        if active_ads:
            avg_cpa = sum(a["cost_per_result"] for a in active_ads) / len(active_ads)
            total_results = sum(a["results"] for a in active_ads)
            median_results = sorted(a["results"] for a in active_ads)[len(active_ads) // 2] if active_ads else 0

            for ad in camp_ads:
                if ad["status"] != "active":
                    ad["gp_verdict"] = "gray"
                    ad["gp_label"] = "Inactivo"
                    continue

                quality = ad.get("quality", "-")
                has_penalty = quality != "-" and "por debajo" in quality.lower() if quality else False
                low_volume = ad["results"] < total_results * 0.10 if total_results > 0 else False

                if has_penalty or (avg_cpa > 0 and ad["cost_per_result"] > avg_cpa * 1.5) or low_volume:
                    ad["gp_verdict"] = "red"
                    ad["gp_label"] = "Pausar ASAP"
                elif avg_cpa > 0 and ad["cost_per_result"] < avg_cpa * 0.7 and ad["results"] >= median_results:
                    ad["gp_verdict"] = "green"
                    ad["gp_label"] = "Dejar correr"
                else:
                    ad["gp_verdict"] = "yellow"
                    ad["gp_label"] = "Monitorear"

        # --- CAMPAIGN STATUS ---
        roas = camp["roas"]
        weak_spend = sum(a["spend"] for a in active_ads if a.get("semaphore") in ["red", "orange"])
        weak_pct = weak_spend / camp["spend"] if camp["spend"] > 0 else 0

        if roas < 1.0:
            camp["status_label"] = "Crítica"
            camp["status_emoji"] = "🔴"
            camp["status_dot"] = "dot-red"
        elif roas < 5.0 or (roas >= 5.0 and weak_pct > 0.40):
            camp["status_label"] = "Media-alta"
            camp["status_emoji"] = "🟡"
            camp["status_dot"] = "dot-yellow"
        elif roas >= 15.0 and weak_pct < 0.20:
            camp["status_label"] = "Excelente"
            camp["status_emoji"] = "🟢🟢"
            camp["status_dot"] = "dot-green"
        else:
            camp["status_label"] = "Funciona bien"
            camp["status_emoji"] = "🟢"
            camp["status_dot"] = "dot-green"

    return data
```

- [ ] **Step 6: Test parse mode end-to-end**

Run: `cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic && python3 generator.py parse bmx 260326 | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Campaigns: {len(d[\"active_campaigns\"])} active'); [print(f'  {c[\"name\"]}: ROAS {c[\"roas\"]}, {len(c[\"ads\"])} ads') for c in d['active_campaigns']]"`
Expected: Shows 3 active campaigns with their ROAS and ad counts

---

## Chunk 2: HTML Generation Engine

### Task 4: Implement all HTML placeholder generators

**Files:**
- Modify: `generator.py`

- [ ] **Step 7: Add HTML generator functions for all 15+ placeholders**

Add before `run_parse`:

```python
# === HTML GENERATORS ===

TYPE_LABELS = {"captacion": "Captación", "retencion": "Retención", "reactivacion": "Reactivación"}


def gen_tab1_kpis(data, symbol):
    """Grid-4 global KPI cards (NOT collapsible)."""
    kpis = data["global_kpis"]
    total_spend = kpis["total_spend"]
    weighted_roas = kpis["weighted_roas"]
    avg_cpm = kpis["avg_cpm"]

    # Results summary
    results_parts = []
    for label, count in kpis["total_results_by_type"].items():
        results_parts.append(f"{fmt_number(count)} {label}")
    results_str = " + ".join(results_parts)

    roas_class = "green" if weighted_roas > 5 else ("red" if weighted_roas < 1 else "yellow")

    return f'''<div class="grid-4">
  <div class="kpi-card"><div class="value">{fmt_money(total_spend, symbol)}</div><div class="label">Gasto Total</div></div>
  <div class="kpi-card"><div class="value">{results_str}</div><div class="label">Resultados Totales</div></div>
  <div class="kpi-card {roas_class}"><div class="value">{weighted_roas}x</div><div class="label">ROAS Ponderado</div></div>
  <div class="kpi-card"><div class="value">{fmt_money(avg_cpm, symbol)}</div><div class="label">CPM Promedio</div></div>
</div>'''


def gen_tab1_ganadores(data, symbol, analysis):
    """Ganadores/Perdedores table per campaign (collapsible, starts OPEN)."""
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>&#9889; Acción Inmediata — Ganadores y Perdedores</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body">'

    total_paused_spend = 0
    total_paused_count = 0
    total_winner_results = 0
    total_results = 0

    for camp in data["campaigns_active"]:
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp["type"] and a["status"] == "active"]
        colors = CAMPAIGN_COLORS[camp["type"]]
        label = TYPE_LABELS[camp["type"]]

        html += f'<h3 style="margin-top:16px">{camp["name"]} <span class="badge {colors["badge"]}">{label}</span></h3>'
        html += '<div class="table-wrap"><table><thead><tr>'
        html += '<th>Anuncio</th><th>CPA</th><th>Volumen</th><th>ROAS</th><th>Veredicto</th>'
        html += '</tr></thead><tbody>'

        # Sort: green first, then yellow, then red
        order = {"green": 0, "yellow": 1, "red": 2}
        sorted_ads = sorted(camp_ads, key=lambda a: order.get(a.get("gp_verdict", "yellow"), 1))

        for ad in sorted_ads:
            v = ad.get("gp_verdict", "yellow")
            vlabel = ad.get("gp_label", "Monitorear")
            badge_cls = f"badge-{v}"
            bm = " <strong>BENCHMARK</strong>" if ad.get("is_benchmark") else ""
            html += f'<tr><td>{ad["name"]}{bm}</td>'
            html += f'<td>{fmt_money(ad["cost_per_result"], symbol)}</td>'
            html += f'<td>{fmt_number(ad["results"])}</td>'
            html += f'<td>{ad["roas"]:.2f}x</td>'
            html += f'<td><span class="badge {badge_cls}">{vlabel}</span></td></tr>'

            total_results += ad["results"]
            if v == "red":
                total_paused_spend += ad["spend"] / 30  # daily
                total_paused_count += 1
            elif v == "green":
                total_winner_results += ad["results"]

        html += '</tbody></table></div>'

    # Summary alert
    winner_pct = (total_winner_results / total_results * 100) if total_results > 0 else 0
    if total_paused_count > 0:
        html += f'<div class="alert-box alert-yellow" style="margin-top:16px">'
        html += f'Pausar <strong>{total_paused_count} anuncio{"s" if total_paused_count > 1 else ""}</strong> ahorra ~{fmt_money(total_paused_spend, symbol)}/día. '
        html += f'Los ganadores concentran el <strong>{winner_pct:.0f}%</strong> de los resultados.</div>'

    html += '</div></div>'
    return html


def gen_tab1_nota(analysis):
    """Executive note (collapsible)."""
    note = analysis.get("executive_note", "")
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>&#128221; Nota Ejecutiva</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body">'
    html += f'<div class="alert-box alert-yellow">{note}</div>'
    html += '</div></div>'
    return html


def gen_tab1_kpi_comparativa(data, symbol):
    """Side-by-side KPI comparison table (collapsible)."""
    camps = data["campaigns_active"]
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>KPIs por Campaña</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body"><div class="table-wrap"><table><thead><tr><th>Indicador</th>'

    for c in camps:
        colors = CAMPAIGN_COLORS[c["type"]]
        label = TYPE_LABELS[c["type"]]
        html += f'<th>{c["name"]} <span class="badge {colors["badge"]}">{label}</span></th>'
    html += '</tr></thead><tbody>'

    rows_data = [
        ("Objetivo", [c["metric_label"].capitalize() for c in camps]),
        ("Gasto Total", [fmt_money(c["spend"], symbol) for c in camps]),
        ("Resultados", [fmt_number(c["results"]) for c in camps]),
        ("Costo/Resultado", [fmt_money(c["cost_per_result"], symbol) for c in camps]),
        ("ROAS", [f'{"✅" if c["roas"] > 5 else "⚠️"} {c["roas"]:.2f}x' for c in camps]),
        ("Impresiones", [fmt_number(c["impressions"]) for c in camps]),
        ("Frecuencia", [f'{"🔴" if c["frequency"] > 15 else "⚠️" if c["frequency"] > 7 else "✅"} {c["frequency"]:.2f}' for c in camps]),
        ("CPM", [fmt_money(c["cpm"], symbol) for c in camps]),
    ]

    for label, values in rows_data:
        html += f'<tr><td><strong>{label}</strong></td>'
        for v in values:
            html += f'<td>{v}</td>'
        html += '</tr>'

    html += '</tbody></table></div></div></div>'
    return html


def gen_tab1_tabla_campanas(data, analysis):
    """Quick diagnosis table (collapsible)."""
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>Diagnóstico Rápido por Campaña</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body"><div class="table-wrap"><table><thead><tr>'
    html += '<th>Campaña</th><th>Tipo</th><th>Estado</th><th>Problema Principal</th><th>Acción Inmediata</th>'
    html += '</tr></thead><tbody>'

    for camp in data["campaigns_active"]:
        colors = CAMPAIGN_COLORS[camp["type"]]
        label = TYPE_LABELS[camp["type"]]
        camp_analysis = analysis.get("campaigns", {}).get(camp["name"], {})

        html += f'<tr><td>{camp["name"]}</td>'
        html += f'<td><span class="badge {colors["badge"]}">{label}</span></td>'
        html += f'<td><span class="dot {camp.get("status_dot", "dot-gray")}"></span> {camp.get("status_label", "")}</td>'
        html += f'<td>{camp_analysis.get("main_problem", "—")}</td>'
        html += f'<td>{camp_analysis.get("immediate_action", "—")}</td></tr>'

    html += '</tbody></table></div></div></div>'
    return html


def gen_tab1_creativos(data, analysis):
    """Creative analysis grid (collapsible)."""
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>¿Es suficiente solo cambiar imágenes?</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body"><div class="grid-3">'

    verdict_map = {"NO": "alert-red", "SÍ": "alert-green", "PARCIAL": "alert-yellow"}

    for camp in data["campaigns_active"]:
        camp_analysis = analysis.get("campaigns", {}).get(camp["name"], {})
        creative = camp_analysis.get("creative_analysis", {})
        verdict = creative.get("verdict", "PARCIAL")
        explanation = creative.get("explanation", "")
        alert_cls = verdict_map.get(verdict, "alert-yellow")
        label = TYPE_LABELS[camp["type"]]

        html += f'<div class="alert-box {alert_cls}">'
        html += f'<strong>{camp["name"]}</strong> ({label})<br>'
        html += f'<strong>{verdict}</strong> — {explanation}</div>'

    html += '</div></div></div>'
    return html


def gen_tab1_presupuesto(data, symbol):
    """Budget distribution table (collapsible)."""
    total = sum(c["spend"] for c in data["campaigns_active"])
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>Distribución de Presupuesto</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body"><div class="table-wrap"><table><thead><tr>'
    html += '<th>Campaña</th><th>Tipo</th><th>Gasto Actual</th><th>% del Total</th><th>ROAS</th><th>Recomendación</th>'
    html += '</tr></thead><tbody>'

    for camp in data["campaigns_active"]:
        colors = CAMPAIGN_COLORS[camp["type"]]
        label = TYPE_LABELS[camp["type"]]
        pct = (camp["spend"] / total * 100) if total > 0 else 0
        roas = camp["roas"]
        roas_badge = "badge-green" if roas > 5 else ("badge-red" if roas < 1 else "badge-yellow")

        # Recommendation based on ROAS vs spend proportion
        if roas > 50 and pct < 20:
            rec, rec_badge = "Potenciar", "badge-green"
        elif roas < 5 or pct > 80:
            rec, rec_badge = "Reducir", "badge-red"
        else:
            rec, rec_badge = "Mantener", "badge-yellow"

        html += f'<tr><td>{camp["name"]}</td>'
        html += f'<td><span class="badge {colors["badge"]}">{label}</span></td>'
        html += f'<td>{fmt_money(camp["spend"], symbol)}</td>'
        html += f'<td>{pct:.1f}%</td>'
        html += f'<td><span class="badge {roas_badge}">{roas:.2f}x</span></td>'
        html += f'<td><span class="badge {rec_badge}">{rec}</span></td></tr>'

    html += '</tbody></table></div></div></div>'
    return html


def gen_tab2(data, symbol, analysis):
    """Tab 2: Detail per campaign + archived at bottom."""
    html = ""

    for camp in data["campaigns_active"]:
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp["type"]]
        colors = CAMPAIGN_COLORS[camp["type"]]
        label = TYPE_LABELS[camp["type"]]
        camp_analysis = analysis.get("campaigns", {}).get(camp["name"], {})

        html += '<div class="card">'
        html += f'<div class="card-header"><h2>{camp["name"]}</h2>'
        html += f'<span class="badge {colors["badge"]}">{label}</span></div>'

        # Diagnosis alert
        diagnosis = camp_analysis.get("diagnosis", "")
        status = camp.get("status_label", "")
        emoji = camp.get("status_emoji", "")
        alert_cls = "alert-red" if "Crítica" in status else ("alert-yellow" if "Media" in status else "alert-green")
        html += f'<div class="alert-box {alert_cls}"><strong>{emoji} {status}</strong> — {diagnosis}</div>'

        # Campaign KPIs
        html += '<div class="grid-4" style="margin-bottom:16px">'
        html += f'<div class="kpi-card"><div class="value">{fmt_money(camp["spend"], symbol)}</div><div class="label">Gasto</div></div>'
        html += f'<div class="kpi-card"><div class="value">{fmt_number(camp["results"])}</div><div class="label">{camp["metric_label"].capitalize()}</div></div>'
        roas_cls = "green" if camp["roas"] > 5 else ("red" if camp["roas"] < 1 else "yellow")
        html += f'<div class="kpi-card {roas_cls}"><div class="value">{camp["roas"]:.2f}x</div><div class="label">ROAS</div></div>'
        freq_cls = "red" if camp["frequency"] > 15 else ("yellow" if camp["frequency"] > 7 else "")
        html += f'<div class="kpi-card {freq_cls}"><div class="value">{camp["frequency"]:.2f}</div><div class="label">Frecuencia</div></div>'
        html += '</div>'

        # Ads table
        html += '<div class="table-wrap"><table><thead><tr>'
        html += '<th>Anuncio</th><th>Semáforo</th><th>Status</th><th>Resultados</th><th>Costo/Res</th>'
        html += '<th>Gasto</th><th>Impresiones</th><th>Freq</th><th>CPM</th><th>ROAS</th><th>Puja</th><th>Calidad Meta</th>'
        html += '</tr></thead><tbody>'

        for ad in camp_ads:
            sem = ad.get("semaphore", "gray")
            sem_label = ad.get("semaphore_label", "")
            sem_emoji = ad.get("semaphore_emoji", "")
            bm = " BENCHMARK" if ad.get("is_benchmark") else ""
            badge_cls = f"badge-{sem}" if sem != "orange" else "badge-yellow"

            html += f'<tr><td>{ad["name"]}{bm}</td>'
            html += f'<td><span class="badge {badge_cls}">{sem_emoji} {sem_label}</span></td>'
            html += f'<td>{ad["status"]}</td>'
            html += f'<td>{fmt_number(ad["results"])}</td>'
            html += f'<td>{fmt_money(ad["cost_per_result"], symbol)}</td>'
            html += f'<td>{fmt_money(ad["spend"], symbol)}</td>'
            html += f'<td>{fmt_number(ad["impressions"])}</td>'
            html += f'<td>{ad["frequency"]:.2f}</td>'
            html += f'<td>{fmt_money(ad["cpm"], symbol)}</td>'
            html += f'<td>{ad["roas"]:.2f}x</td>'
            html += f'<td>{ad["bid"]}</td>'
            html += f'<td>{ad["quality"]}</td></tr>'

        html += '</tbody></table></div>'

        # Expandable root cause per ad
        for ad in camp_ads:
            if ad["status"] != "active":
                continue
            ad_analysis = analysis.get("ads", {}).get(ad["name"], {})
            if not ad_analysis:
                continue

            html += '<div class="expandable">'
            html += f'<div class="expandable-header" onclick="toggleExpand(this)">'
            html += f'<span>{ad["name"]} — Causa Raíz</span>'
            html += '<span class="expandable-arrow">&#9654;</span></div>'
            html += '<div class="expandable-body">'
            html += '<div class="table-wrap"><table class="strategy-table"><thead><tr>'
            html += '<th>Origen del Problema</th><th>Configuración Ads</th><th>Dirección Creativa</th>'
            html += '</tr></thead><tbody><tr>'
            html += f'<td>{ad_analysis.get("root_cause", "—")}</td>'
            html += f'<td>{ad_analysis.get("config_ads", "—")}</td>'
            html += f'<td>{ad_analysis.get("creative_direction", "—")}</td>'
            html += '</tr></tbody></table></div></div></div>'

        html += '</div>'  # close card

    # Archived campaigns
    if data["campaigns_inactive"]:
        html += '<div class="card collapsible closed">'
        html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
        html += '<h2>Campañas Archivadas / Inactivas</h2>'
        html += '<span class="collapsible-arrow">&#9660;</span></div>'
        html += '<div class="collapsible-body"><div class="table-wrap"><table><thead><tr>'
        html += '<th>Campaña</th><th>Estado</th><th>Resultados</th><th>Gasto</th><th>ROAS</th>'
        html += '</tr></thead><tbody>'

        for camp in data["campaigns_inactive"]:
            html += f'<tr><td>{camp["name"]}</td><td>{camp["status"]}</td>'
            html += f'<td>{fmt_number(camp["results"])}</td>'
            html += f'<td>{fmt_money(camp["spend"], symbol)}</td>'
            html += f'<td>{camp["roas"]:.2f}x</td></tr>'

        html += '</tbody></table></div></div></div>'

    return html


def gen_tab3_actions(analysis):
    """Top 5 actions (collapsible)."""
    actions = analysis.get("top5_actions", [])
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>Top 5 Acciones Inmediatas</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body">'

    for i, act in enumerate(actions[:5], 1):
        html += f'<div class="action-item">'
        html += f'<div class="action-num">{i}</div>'
        html += f'<div class="action-body"><strong>{act.get("action", "")}</strong>'
        html += f'<div class="action-meta">Impacto: {act.get("impact", "")} | Responsable: {act.get("responsible", "")}</div>'
        html += '</div></div>'

    html += '</div></div>'
    return html


def gen_tab3_strategy(data, analysis):
    """Strategy tables per campaign (collapsible)."""
    html = '<div class="card collapsible">'
    html += '<div class="collapsible-header" onclick="toggleCollapse(this)">'
    html += '<h2>Estrategia por Campaña</h2>'
    html += '<span class="collapsible-arrow">&#9660;</span></div>'
    html += '<div class="collapsible-body">'

    for camp in data["campaigns_active"]:
        camp_analysis = analysis.get("campaigns", {}).get(camp["name"], {})
        strategy = camp_analysis.get("strategy", [])
        colors = CAMPAIGN_COLORS[camp["type"]]
        label = TYPE_LABELS[camp["type"]]

        html += f'<h3 style="margin-top:16px">{camp["name"]} <span class="badge {colors["badge"]}">{label}</span></h3>'
        html += '<div class="table-wrap"><table class="strategy-table"><thead><tr>'
        html += '<th>Aspecto</th><th>Situación Actual</th><th>Recomendación</th>'
        html += '</tr></thead><tbody>'

        for row in strategy:
            html += f'<tr><td>{row.get("aspect", "")}</td>'
            html += f'<td>{row.get("current", "")}</td>'
            html += f'<td>{row.get("recommendation", "")}</td></tr>'

        html += '</tbody></table></div>'

    html += '</div></div>'
    return html


def gen_charts_js(data):
    """Generate Chart.js code for 6 charts."""
    camps = data["campaigns_active"]
    all_ads = data["ads"]
    active_ads = [a for a in all_ads if a["status"] == "active"]

    # Chart colors by campaign type
    camp_labels = [c["name"] for c in camps]
    camp_roas = [c["roas"] for c in camps]
    camp_spend = [c["spend"] for c in camps]
    camp_cpr = [c["cost_per_result"] for c in camps]
    camp_freq = [c["frequency"] for c in camps]
    camp_colors = [CAMPAIGN_COLORS[c["type"]]["chart"] for c in camps]

    # Top/bottom ads by ROAS
    sorted_by_roas = sorted(active_ads, key=lambda a: a["roas"], reverse=True)
    top5 = sorted_by_roas[:5]
    bottom5 = sorted_by_roas[-5:] if len(sorted_by_roas) >= 5 else sorted_by_roas[:]
    bottom5 = sorted(bottom5, key=lambda a: a["roas"])

    top5_labels = json.dumps([a["name"][:30] for a in top5], ensure_ascii=False)
    top5_data = [a["roas"] for a in top5]
    top5_colors = json.dumps([CAMPAIGN_COLORS[a["campaign_type"]]["chart"] for a in top5])

    bottom5_labels = json.dumps([a["name"][:30] for a in bottom5], ensure_ascii=False)
    bottom5_data = [a["roas"] for a in bottom5]
    bottom5_colors = json.dumps([CAMPAIGN_COLORS[a["campaign_type"]]["chart"] for a in bottom5])

    opts = "responsive:true,maintainAspectRatio:false"

    js = f"""
const colors = {{primary:'#2563EB',positive:'#059669',negative:'#DC2626',warning:'#D97706',orange:'#F97316'}};

new Chart(document.getElementById('chartRoas'), {{
  type:'bar',
  data:{{labels:{json.dumps(camp_labels, ensure_ascii=False)},datasets:[{{data:{camp_roas},backgroundColor:{json.dumps(camp_colors)},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},plugins:{{legend:{{display:false}}}},scales:{{y:{{beginAtZero:true}}}}}}
}});

new Chart(document.getElementById('chartSpend'), {{
  type:'doughnut',
  data:{{labels:{json.dumps(camp_labels, ensure_ascii=False)},datasets:[{{data:{camp_spend},backgroundColor:{json.dumps(camp_colors)}}}]}},
  options:{{{opts},plugins:{{legend:{{position:'bottom'}}}}}}
}});

new Chart(document.getElementById('chartCostResult'), {{
  type:'bar',
  data:{{labels:{json.dumps(camp_labels, ensure_ascii=False)},datasets:[{{data:{camp_cpr},backgroundColor:{json.dumps(camp_colors)},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},plugins:{{legend:{{display:false}}}},scales:{{y:{{beginAtZero:true}}}}}}
}});

new Chart(document.getElementById('chartFreq'), {{
  type:'bar',
  data:{{labels:{json.dumps(camp_labels, ensure_ascii=False)},datasets:[{{data:{camp_freq},backgroundColor:{json.dumps(camp_colors)},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},plugins:{{legend:{{display:false}}}},scales:{{y:{{beginAtZero:true}}}}}}
}});

new Chart(document.getElementById('chartTopAds'), {{
  type:'bar',
  data:{{labels:{top5_labels},datasets:[{{data:{top5_data},backgroundColor:{top5_colors},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},indexAxis:'y',plugins:{{legend:{{display:false}}}},scales:{{x:{{beginAtZero:true}}}}}}
}});

new Chart(document.getElementById('chartBottomAds'), {{
  type:'bar',
  data:{{labels:{bottom5_labels},datasets:[{{data:{bottom5_data},backgroundColor:{bottom5_colors},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},indexAxis:'y',plugins:{{legend:{{display:false}}}},scales:{{x:{{beginAtZero:true}}}}}}
}});
"""
    return js
```

- [ ] **Step 8: Verify HTML generators compile without errors**

Run: `cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic && python3 -c "import generator; print('OK')"`
Expected: `OK`

---

### Task 5: Implement `run_generate` function

**Files:**
- Modify: `generator.py`

- [ ] **Step 9: Add run_generate that assembles everything and writes HTML**

Add after `run_parse`:

```python
def run_generate(casino_id, period, analysis_path):
    """Generate HTML dashboard from CSVs + LLM analysis JSON."""
    casino_info = CASINOS[casino_id]
    symbol = casino_info["symbol"]

    # Load analysis JSON
    with open(analysis_path, "r", encoding="utf-8") as f:
        analysis = json.load(f)

    # Load and process CSV data
    global_rows, campaign_ads = load_campaign_csvs(casino_id, period)
    data = build_data_model(global_rows, campaign_ads, casino_info)
    data = compute_analysis(data, casino_info)

    # Compute global KPIs
    total_spend = sum(c["spend"] for c in data["campaigns_active"])
    total_revenue = sum(c["spend"] * c["roas"] for c in data["campaigns_active"])
    weighted_roas = round(total_revenue / total_spend, 2) if total_spend > 0 else 0
    avg_cpm = round(sum(c["cpm"] for c in data["campaigns_active"]) / len(data["campaigns_active"]), 2) if data["campaigns_active"] else 0

    results_by_type = {}
    for camp in data["campaigns_active"]:
        label = camp["metric_label"]
        results_by_type[label] = results_by_type.get(label, 0) + camp["results"]

    data["global_kpis"] = {
        "total_spend": total_spend,
        "weighted_roas": weighted_roas,
        "avg_cpm": avg_cpm,
        "total_results_by_type": results_by_type,
    }

    # Load template
    template = TEMPLATE_PATH.read_text(encoding="utf-8")

    # Logo
    logo_path = LOGOS_DIR / casino_id / "logo.png"
    logo_img = ""
    if logo_path.exists():
        b64 = base64.b64encode(logo_path.read_bytes()).decode()
        logo_img = f'<img src="data:image/png;base64,{b64}" style="max-height:38px">'

    # Date range
    date_range = f"{data['date_start']} al {data['date_end']}"
    num_active = len(data["campaigns_active"])

    # Replace placeholders
    replacements = {
        "{{META_TITLE}}": f"Diagnóstico Meta Ads — {casino_info['name']} | {period}",
        "{{CASINO_NOMBRE}}": casino_info["name"],
        "{{CASINO_PERIODO}}": date_range,
        "{{CASINO_CAMPANAS_ACTIVAS}}": f"{num_active} campañas activas",
        "{{CASINO_LOGO_IMG}}": logo_img,
        "{{TAB1_KPIS}}": gen_tab1_kpis(data, symbol),
        "{{TAB1_GANADORES_PERDEDORES}}": gen_tab1_ganadores(data, symbol, analysis),
        "{{TAB1_NOTA_EJECUTIVA}}": gen_tab1_nota(analysis),
        "{{TAB1_KPI_COMPARATIVA}}": gen_tab1_kpi_comparativa(data, symbol),
        "{{TAB1_TABLA_CAMPANAS}}": gen_tab1_tabla_campanas(data, analysis),
        "{{TAB1_CREATIVOS}}": gen_tab1_creativos(data, analysis),
        "{{TAB1_TABLA_PRESUPUESTO}}": gen_tab1_presupuesto(data, symbol),
        "{{TAB2_CONTENIDO}}": gen_tab2(data, symbol, analysis),
        "{{TAB3_TOP5_ACCIONES}}": gen_tab3_actions(analysis),
        "{{TAB3_ESTRATEGIA_CAMPANAS}}": gen_tab3_strategy(data, analysis),
        "{{CHARTS_JS}}": gen_charts_js(data),
        "{{FOOTER_TEXTO}}": f"Diagnóstico Meta Ads — {casino_info['name']} — Período: {date_range} — Generado automáticamente",
    }

    html = template
    for placeholder, content in replacements.items():
        html = html.replace(placeholder, content)

    # Write output
    output_dir = OUTPUT_DIR / casino_id
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"diagnostico-{casino_id}_{period}.html"
    output_path.write_text(html, encoding="utf-8")

    print(json.dumps({"status": "ok", "path": str(output_path)}, ensure_ascii=False))
```

- [ ] **Step 10: Test full generate pipeline with a test JSON**

Create a minimal test analysis JSON and run generate:
```bash
cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic
cat > /tmp/test_analysis.json << 'TESTEOF'
{
  "campaigns": {
    "1 ALL 1": {"diagnosis":"Test diagnosis","main_problem":"Test problem","immediate_action":"Test action","creative_analysis":{"verdict":"NO","explanation":"Test"},"strategy":[{"aspect":"Objetivo","current":"Test","recommendation":"Test"}]},
    "2 Retener C Web-App": {"diagnosis":"Test","main_problem":"Test","immediate_action":"Test","creative_analysis":{"verdict":"SÍ","explanation":"Test"},"strategy":[{"aspect":"Objetivo","current":"Test","recommendation":"Test"}]},
    "3 Reactivar C Web-App +16": {"diagnosis":"Test","main_problem":"Test","immediate_action":"Test","creative_analysis":{"verdict":"PARCIAL","explanation":"Test"},"strategy":[{"aspect":"Objetivo","current":"Test","recommendation":"Test"}]}
  },
  "ads": {},
  "executive_note": "Test executive note",
  "top5_actions": [{"action":"Test action 1","impact":"Test impact","responsible":"Configuración Ads"}]
}
TESTEOF
python3 generator.py generate bmx 260326 --analysis /tmp/test_analysis.json
```
Expected: JSON output with `{"status": "ok", "path": "...diagnostico-bmx_260326.html"}`

---

## Chunk 3: Skill Update + End-to-End Test

### Task 6: Update the skill file to use generator.py

**Files:**
- Modify: `~/.claude/commands/meta-ads-diagnostic.md`

- [ ] **Step 11: Update skill — replace Pasos 3-6 with new flow using generator.py**

The skill keeps Steps 1-2 (casino + period selection) unchanged. Steps 3-6 change to:

**New Step 3:** Run `python3 generator.py parse {casino} {period}` and read the JSON output.

**New Step 4:** Analyze the parse output with IA. Write the qualitative analysis JSON to `/tmp/meta-ads-analysis.json` following the schema (campaigns, ads, executive_note, top5_actions).

**New Step 5:** Run `python3 generator.py generate {casino} {period} --analysis /tmp/meta-ads-analysis.json`

**New Step 6:** Open the HTML in browser + show time.

- [ ] **Step 12: End-to-end test with bmx 260326**

Run `/meta-ads-diagnostic` skill, select bmx, select 260326, verify the output HTML opens correctly and matches previous quality.

---

### Task 7: Update project documentation

**Files:**
- Modify: `CLAUDE.md` in project root

- [ ] **Step 13: Update CLAUDE.md to document generator.py and new flow**

Add section documenting:
- generator.py two modes (parse/generate)
- JSON schema for LLM analysis
- New execution flow
- Expected time improvement
