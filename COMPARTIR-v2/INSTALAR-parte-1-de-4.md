# INSTALAR Meta Ads Diagnostic — PARTE 1 de 4

**Cómo usar:** Pega este archivo completo en Claude Code y espera a que termine. Te pedirá continuar con las partes 2, 3 y 4.

---

## INSTRUCCIONES PARA CLAUDE

Eres el instalador automático de **Meta Ads Diagnostic** (diagnóstico de campañas Meta Ads de casinos digitales Lagersoft). La instalación se divide en 4 partes porque Claude Code tiene límite de ~50,000 caracteres por mensaje.

**Tu tarea en esta PARTE 1:**

### Paso 1 — Verificar Python
Ejecuta en Bash:
```bash
python3 -c "import sys, platform; print('OS:', platform.system()); print('Python:', sys.version.split()[0])"
```
Si `python3` no existe, prueba `python`. Si ninguno existe, detente y muéstrale al usuario cómo instalar Python 3:
- **Mac:** "Abre Terminal y ejecuta `xcode-select --install`"
- **Windows:** "Descarga Python 3 en https://python.org/downloads/ y marca 'Add Python to PATH' durante la instalación"

### Paso 2 — Detectar HOME
```bash
python3 -c "from pathlib import Path; print(Path.home())"
```
Guarda como `HOME`. La instalación va a `$HOME/meta-ads-diagnostic/` y `$HOME/.claude/commands/`.

### Paso 3 — Crear estructura de carpetas
```bash
mkdir -p "$HOME/meta-ads-diagnostic"/{analyser,output,assets/logos}/{bmx,bet4-br,bet4-pe,aposta,fazo,casinito}
mkdir -p "$HOME/.claude/commands"
```

### Paso 4 — Escribir generator.py
Usa la herramienta **Write** para crear `$HOME/meta-ads-diagnostic/generator.py` con el contenido EXACTO del bloque "Archivo 1" más abajo.

### Paso 5 — Mensaje al usuario
Al terminar esta parte, dile EXACTAMENTE:

```
✅ Parte 1 de 4 completa (generator.py instalado).

Ahora pégame la PARTE 2 (template.html + skill + logo bet4-br).
```

No hagas nada más, no des resúmenes, no verifiques nada más. Solo espera a que el usuario pegue la siguiente parte.

---

## Archivo 1 — generator.py

Ruta destino: `$HOME/meta-ads-diagnostic/generator.py`

``````python
#!/usr/bin/env python3
"""Meta Ads Diagnostic Generator — Parses CSVs and generates HTML dashboards."""

import argparse
import csv
import json
import base64
import os
import sys
import webbrowser
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

TYPE_LABELS = {"captacion": "Captación", "retencion": "Retención", "reactivacion": "Reactivación"}


# === UTILITIES ===

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
    return "captacion"


def parse_csv_file(filepath):
    raw = filepath.read_text(encoding="utf-8")
    raw = fix_encoding(raw)
    reader = csv.DictReader(StringIO(raw))
    return list(reader)


def safe_float(val, default=0.0):
    if not val or val == "-":
        return default
    try:
        return float(str(val).replace(",", ""))
    except (ValueError, AttributeError):
        return default


def safe_int(val, default=0):
    return int(safe_float(val, default))


def fmt_number(n):
    if isinstance(n, float):
        if n == int(n) and abs(n) > 100:
            return f"{int(n):,}"
        if abs(n) >= 100:
            return f"{n:,.2f}"
        return f"{n:.2f}"
    return f"{n:,}"


def fmt_money(n, symbol="$"):
    return f"{symbol}{fmt_number(n)}"


# === CSV LOADING ===

def load_campaign_csvs(casino_id, period):
    period_dir = ANALYSER_DIR / casino_id / period
    if not period_dir.exists():
        print(f"ERROR: No existe la carpeta {period_dir}", file=sys.stderr)
        sys.exit(1)

    csv_files = sorted(period_dir.glob("*.csv"))
    if not csv_files:
        print(f"ERROR: No hay CSV en {period_dir}", file=sys.stderr)
        sys.exit(1)

    global_rows = []
    campaign_ads = {}

    for f in csv_files:
        rows = parse_csv_file(f)
        if not rows:
            continue
        headers = list(rows[0].keys())
        if any("Nombre de la campaña" in h for h in headers):
            global_rows = rows
        elif any("Nombre del anuncio" in h for h in headers):
            fname = f.stem.lower()
            if "captacion" in fname:
                campaign_ads["captacion"] = rows
            elif "retencion" in fname:
                campaign_ads["retencion"] = rows
            elif "reactivacion" in fname:
                campaign_ads["reactivacion"] = rows
            else:
                campaign_ads[fname] = rows

    return global_rows, campaign_ads


def build_data_model(global_rows, campaign_ads, casino_info):
    currency = casino_info["currency"]
    spend_col = f"Importe gastado ({currency})"
    cpm_col = f"CPM (costo por mil impresiones) ({currency})"
    roas_col = "ROAS (retorno de la inversión en publicidad) de compras"

    campaigns = []
    for row in global_rows:
        name = row.get("Nombre de la campaña", "")
        status = row.get("Entrega de la campaña", "")
        result_indicator = row.get("Indicador de resultado", "")
        camp = {
            "name": name,
            "status": status,
            "type": classify_campaign(name),
            "results": safe_int(row.get("Resultados", 0)),
            "result_indicator": result_indicator,
            "cost_per_result": safe_float(row.get("Costo por resultados", 0)),
            "budget": row.get("Presupuesto del conjunto de anuncios", ""),
            "budget_type": row.get("Tipo de presupuesto del conjunto de anuncios", ""),
            "spend": safe_float(row.get(spend_col, 0)),
            "impressions": safe_int(row.get("Impresiones", 0)),
            "reach": safe_int(row.get("Alcance", 0)),
            "frequency": safe_float(row.get("Frecuencia", 0)),
            "cpm": safe_float(row.get(cpm_col, 0)),
            "purchases": safe_int(row.get("Compras", 0)),
            "finalization": row.get("Finalización", ""),
            "attribution": row.get("Configuración de atribución", ""),
            "roas": safe_float(row.get(roas_col, 0)),
            "metric_label": "registros" if "registration" in result_indicator else "compras",
        }
        campaigns.append(camp)

    active = [c for c in campaigns if c["status"] == "active"]
    inactive = [c for c in campaigns if c["status"] != "active"]

    # Parse ads
    all_ads = []
    for ctype, rows in campaign_ads.items():
        name_count = {}
        for row in rows:
            raw_name = row.get("Nombre del anuncio", "")
            name_count[raw_name] = name_count.get(raw_name, 0) + 1

        name_seen = {}
        for row in rows:
            raw_name = row.get("Nombre del anuncio", "")
            if name_count[raw_name] > 1:
                name_seen[raw_name] = name_seen.get(raw_name, 0) + 1
                suffix = chr(64 + name_seen[raw_name])
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
                "spend": safe_float(row.get(spend_col, 0)),
                "impressions": safe_int(row.get("Impresiones", 0)),
                "reach": safe_int(row.get("Alcance", 0)),
                "frequency": safe_float(row.get("Frecuencia", 0)),
                "cpm": safe_float(row.get(cpm_col, 0)),
                "purchases": safe_int(row.get("Compras", 0)),
                "roas": safe_float(row.get(roas_col, 0)),
                "bid": row.get("Puja", "-"),
                "bid_type": row.get("Tipo de puja", ""),
                "last_change": row.get("Último cambio significativo", "-"),
                "quality": row.get("Clasificación de calidad", "-"),
                "engagement": row.get("Clasificación del porcentaje de interacción", "-"),
                "conversion": row.get("Clasificación del porcentaje de conversiones", "-"),
                "ad_set": row.get("Nombre del conjunto de anuncios", ""),
            }
            all_ads.append(ad)

    date_start = global_rows[0].get("Inicio del informe", "") if global_rows else ""
    date_end = global_rows[0].get("Fin del informe", "") if global_rows else ""

    return {
        "date_start": date_start,
        "date_end": date_end,
        "campaigns_active": active,
        "campaigns_inactive": inactive,
        "ads": all_ads,
    }


# === ANALYSIS ENGINE ===

def compute_analysis(data, casino_info):
    for camp in data["campaigns_active"]:
        camp_type = camp["type"]
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp_type]
        active_ads = [a for a in camp_ads if a["status"] == "active"]

        # BENCHMARK: best ROAS in campaign
        if active_ads:
            best = max(active_ads, key=lambda a: a["roas"])
            for ad in camp_ads:
                ad["is_benchmark"] = (ad["name"] == best["name"] and ad["status"] == "active")
        else:
            for ad in camp_ads:
                ad["is_benchmark"] = False

        # SEMAPHORE per ad (4 levels, relative to campaign)
        avg_cpm = sum(a["cpm"] for a in active_ads) / len(active_ads) if active_ads else 0

        for ad in camp_ads:
            if ad["status"] != "active":
                ad["semaphore"] = "gray"
                ad["semaphore_label"] = "Inactivo"
                ad["semaphore_emoji"] = "⚪"
                continue

            quality = ad.get("quality", "-") or "-"
            has_penalty = quality != "-" and "por debajo" in quality.lower()
            significant_spend = ad["spend"] > camp["spend"] * 0.05 if camp["spend"] > 0 else False

            if has_penalty:
                ad["semaphore"] = "red"
                ad["semaphore_label"] = "PAUSAR YA"
                ad["semaphore_emoji"] = "🔴"
            elif significant_spend and ad["results"] == 0:
                ad["semaphore"] = "red"
                ad["semaphore_label"] = "PAUSAR YA"
                ad["semaphore_emoji"] = "🔴"
            elif ad["roas"] < 0.3 and significant_spend:
                ad["semaphore"] = "red"
                ad["semaphore_label"] = "PAUSAR YA"
                ad["semaphore_emoji"] = "🔴"
            elif ad["roas"] < 1.0 and significant_spend:
                ad["semaphore"] = "orange"
                ad["semaphore_label"] = "Pausar"
                ad["semaphore_emoji"] = "🟠"
            elif ad["results"] < 50 and significant_spend:
                ad["semaphore"] = "orange"
                ad["semaphore_label"] = "Pausar"
                ad["semaphore_emoji"] = "🟠"
            elif ad["frequency"] > 7 or (avg_cpm > 0 and ad["cpm"] > avg_cpm * 1.5):
                ad["semaphore"] = "yellow"
                ad["semaphore_label"] = "Monitorear"
                ad["semaphore_emoji"] = "🟡"
            elif 1.0 <= ad["roas"] <= 5.0:
                ad["semaphore"] = "yellow"
                ad["semaphore_label"] = "Monitorear"
                ad["semaphore_emoji"] = "🟡"
            else:
                ad["semaphore"] = "green"
                ad["semaphore_label"] = "Óptimo"
                ad["semaphore_emoji"] = "🟢"

        # GANADORES/PERDEDORES — La IA los clasifica en el JSON de análisis.
        # El script solo inicializa los campos para que el parse los incluya vacíos.
        for ad in camp_ads:
            if ad["status"] != "active":
                ad["gp_verdict"] = "gray"
                ad["gp_label"] = "Inactivo"
            else:
                ad["gp_verdict"] = ""
                ad["gp_label"] = ""

        # CAMPAIGN STATUS
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


def compute_global_kpis(data):
    active = data["campaigns_active"]
    total_spend = sum(c["spend"] for c in active)
    total_revenue = sum(c["spend"] * c["roas"] for c in active)
    weighted_roas = round(total_revenue / total_spend, 2) if total_spend > 0 else 0
    avg_cpm = round(sum(c["cpm"] for c in active) / len(active), 2) if active else 0

    results_by_type = {}
    for camp in active:
        label = camp["metric_label"]
        results_by_type[label] = results_by_type.get(label, 0) + camp["results"]

    return {
        "total_spend": total_spend,
        "weighted_roas": weighted_roas,
        "avg_cpm": avg_cpm,
        "total_results_by_type": results_by_type,
    }


# === HTML GENERATORS ===

def gen_tab1_kpis(data, symbol):
    kpis = data["global_kpis"]
    results_parts = [f"{fmt_number(count)} {label}" for label, count in kpis["total_results_by_type"].items()]
    results_str = " + ".join(results_parts)
    roas_class = "green" if kpis["weighted_roas"] > 5 else ("red" if kpis["weighted_roas"] < 1 else "yellow")

    return f'''<div class="grid-4">
  <div class="kpi-card"><div class="value">{fmt_money(kpis["total_spend"], symbol)}</div><div class="label">Gasto Total</div></div>
  <div class="kpi-card"><div class="value">{results_str}</div><div class="label">Resultados Totales</div></div>
  <div class="kpi-card {roas_class}"><div class="value">{kpis["weighted_roas"]}x</div><div class="label">ROAS Ponderado</div></div>
  <div class="kpi-card"><div class="value">{fmt_money(kpis["avg_cpm"], symbol)}</div><div class="label">CPM Promedio</div></div>
</div>'''


def gen_tab1_ganadores(data, symbol, analysis):
    """Ganadores/Perdedores — clasificados por la IA en analysis JSON."""
    gp_data = analysis.get("ganadores_perdedores", {})

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

        # Build lookup from IA analysis
        camp_gp = gp_data.get(camp["name"], {})

        html += f'<h3 style="margin-top:16px">{camp["name"]} <span class="badge {colors["badge"]}">{label}</span></h3>'
        html += '<div class="table-wrap"><table><thead><tr>'
        html += '<th>Anuncio</th><th>CPA</th><th>Volumen</th><th>ROAS</th><th>Veredicto</th>'
        html += '</tr></thead><tbody>'

        # Apply IA verdicts to ads
        for ad in camp_ads:
            ad_gp = camp_gp.get(ad["name"], {})
            ad["gp_verdict"] = ad_gp.get("verdict", "yellow")
            ad["gp_label"] = ad_gp.get("label", "Monitorear")

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
                total_paused_spend += ad["spend"] / 30
                total_paused_count += 1
            elif v == "green":
                total_winner_results += ad["results"]

        html += '</tbody></table></div>'

    winner_pct = (total_winner_results / total_results * 100) if total_results > 0 else 0
    if total_paused_count > 0:
        html += f'<div class="alert-box alert-yellow" style="margin-top:16px">'
        html += f'Pausar <strong>{total_paused_count} anuncio{"s" if total_paused_count > 1 else ""}</strong> ahorra ~{fmt_money(total_paused_spend, symbol)}/día. '
        html += f'Los ganadores concentran el <strong>{winner_pct:.0f}%</strong> de los resultados.</div>'
    elif total_results > 0:
        html += f'<div class="alert-box alert-green" style="margin-top:16px">'
        html += f'Todos los anuncios activos están en rango aceptable. Los ganadores concentran el <strong>{winner_pct:.0f}%</strong> de los resultados.</div>'

    html += '</div></div>'
    return html


def gen_tab1_nota(analysis):
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
    html = ""

    for camp in data["campaigns_active"]:
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp["type"]]
        colors = CAMPAIGN_COLORS[camp["type"]]
        label = TYPE_LABELS[camp["type"]]
        camp_analysis = analysis.get("campaigns", {}).get(camp["name"], {})

        html += '<div class="card">'
        html += f'<div class="card-header"><h2>{camp["name"]}</h2>'
        html += f'<span class="badge {colors["badge"]}">{label}</span></div>'

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
            badge_cls = f"badge-{'yellow' if sem == 'orange' else sem}"

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

        # Expandable root cause per active ad
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

        html += '</div>'

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
    camps = data["campaigns_active"]
    active_ads = [a for a in data["ads"] if a["status"] == "active"]

    camp_labels = json.dumps([c["name"] for c in camps], ensure_ascii=False)
    camp_roas = [c["roas"] for c in camps]
    camp_spend = [c["spend"] for c in camps]
    camp_cpr = [c["cost_per_result"] for c in camps]
    camp_freq = [c["frequency"] for c in camps]
    camp_colors = json.dumps([CAMPAIGN_COLORS[c["type"]]["chart"] for c in camps])

    sorted_by_roas = sorted(active_ads, key=lambda a: a["roas"], reverse=True)
    top5 = sorted_by_roas[:5]
    bottom5 = sorted(sorted_by_roas[-5:] if len(sorted_by_roas) >= 5 else sorted_by_roas[:], key=lambda a: a["roas"])

    top5_labels = json.dumps([a["name"][:35] for a in top5], ensure_ascii=False)
    top5_data = [a["roas"] for a in top5]
    top5_colors = json.dumps([CAMPAIGN_COLORS[a["campaign_type"]]["chart"] for a in top5])

    bottom5_labels = json.dumps([a["name"][:35] for a in bottom5], ensure_ascii=False)
    bottom5_data = [a["roas"] for a in bottom5]
    bottom5_colors = json.dumps([CAMPAIGN_COLORS[a["campaign_type"]]["chart"] for a in bottom5])

    opts = "responsive:true,maintainAspectRatio:false"

    return f"""
new Chart(document.getElementById('chartRoas'), {{
  type:'bar',
  data:{{labels:{camp_labels},datasets:[{{data:{camp_roas},backgroundColor:{camp_colors},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},plugins:{{legend:{{display:false}}}},scales:{{y:{{beginAtZero:true}}}}}}
}});

new Chart(document.getElementById('chartSpend'), {{
  type:'doughnut',
  data:{{labels:{camp_labels},datasets:[{{data:{camp_spend},backgroundColor:{camp_colors}}}]}},
  options:{{{opts},plugins:{{legend:{{position:'bottom'}}}}}}
}});

new Chart(document.getElementById('chartCostResult'), {{
  type:'bar',
  data:{{labels:{camp_labels},datasets:[{{data:{camp_cpr},backgroundColor:{camp_colors},borderRadius:6,maxBarThickness:60}}]}},
  options:{{{opts},plugins:{{legend:{{display:false}}}},scales:{{y:{{beginAtZero:true}}}}}}
}});

new Chart(document.getElementById('chartFreq'), {{
  type:'bar',
  data:{{labels:{camp_labels},datasets:[{{data:{camp_freq},backgroundColor:{camp_colors},borderRadius:6,maxBarThickness:60}}]}},
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


# === MAIN FUNCTIONS ===

def run_parse(casino_id, period):
    casino_info = CASINOS[casino_id]
    global_rows, campaign_ads = load_campaign_csvs(casino_id, period)
    data = build_data_model(global_rows, campaign_ads, casino_info)
    data = compute_analysis(data, casino_info)
    data["global_kpis"] = compute_global_kpis(data)

    output = {
        "casino": casino_info,
        "casino_id": casino_id,
        "period": period,
        "date_range": f"{data['date_start']} al {data['date_end']}",
        "active_campaigns": [],
        "inactive_campaigns": [],
        "global_kpis": data["global_kpis"],
    }

    for camp in data["campaigns_active"]:
        camp_ads = [a for a in data["ads"] if a["campaign_type"] == camp["type"]]
        c = {
            "name": camp["name"],
            "type": camp["type"],
            "type_label": TYPE_LABELS[camp["type"]],
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
                "semaphore_emoji": ad.get("semaphore_emoji", ""),
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

    print(json.dumps(output, indent=2, ensure_ascii=False))


def run_generate(casino_id, period, analysis_path, open_after=False):
    casino_info = CASINOS[casino_id]
    symbol = casino_info["symbol"]

    with open(analysis_path, "r", encoding="utf-8") as f:
        analysis = json.load(f)

    global_rows, campaign_ads = load_campaign_csvs(casino_id, period)
    data = build_data_model(global_rows, campaign_ads, casino_info)
    data = compute_analysis(data, casino_info)
    data["global_kpis"] = compute_global_kpis(data)

    template = TEMPLATE_PATH.read_text(encoding="utf-8")

    # Logo
    logo_path = LOGOS_DIR / casino_id / "logo.png"
    logo_img = ""
    if logo_path.exists():
        b64 = base64.b64encode(logo_path.read_bytes()).decode()
        logo_img = f'<img src="data:image/png;base64,{b64}" style="max-height:38px">'

    date_range = f"{data['date_start']} al {data['date_end']}"
    num_active = len(data["campaigns_active"])

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

    output_dir = OUTPUT_DIR / casino_id
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find next consecutive number (01, 02, 03...)
    existing = sorted(output_dir.glob(f"diagnostico-{casino_id}_{period}_*.html"))
    if existing:
        # Extract last number from existing files
        last_file = existing[-1].stem  # e.g. diagnostico-bmx_260326_03
        try:
            last_num = int(last_file.split("_")[-1])
        except ValueError:
            last_num = 0
        next_num = last_num + 1
    else:
        next_num = 1

    output_path = output_dir / f"diagnostico-{casino_id}_{period}_{next_num:02d}.html"
    output_path.write_text(html, encoding="utf-8")

    opened = False
    if open_after:
        try:
            webbrowser.open(output_path.absolute().as_uri())
            opened = True
        except Exception:
            opened = False

    print(json.dumps({"status": "ok", "path": str(output_path), "opened": opened}, ensure_ascii=False))


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
    p_gen.add_argument("--open", action="store_true", help="Open HTML in default browser after generation")

    args = parser.parse_args()

    if args.mode == "parse":
        run_parse(args.casino, args.period)
    elif args.mode == "generate":
        run_generate(args.casino, args.period, args.analysis, open_after=args.open)


if __name__ == "__main__":
    main()

``````
