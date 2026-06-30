# INSTALAR Meta Ads Diagnostic — PARTE 2 de 4

## INSTRUCCIONES PARA CLAUDE

Esta es la **PARTE 2** de la instalación (continuación de la Parte 1). El usuario ya instaló `generator.py`. Ahora debes:

### Paso 1 — Escribir template.html
Usa **Write** para crear `$HOME/meta-ads-diagnostic/template.html` con el contenido del bloque "Archivo 2" más abajo.

### Paso 2 — Escribir la skill
Usa **Write** para crear `$HOME/.claude/commands/meta-ads-diagnostic.md` con el contenido del bloque "Archivo 3". Si ya existe, sobrescríbelo.

### Paso 3 — Decodificar y escribir logo bet4-br
Toma el contenido base64 del bloque "Archivo 4" y escríbelo como PNG binario:

```bash
python3 -c "
import base64, pathlib
data = '''<PEGA_AQUI_EL_CONTENIDO_DEL_ARCHIVO_4>'''
pathlib.Path('$HOME/meta-ads-diagnostic/assets/logos/bet4-br/logo.png').write_bytes(base64.b64decode(data))
print('bet4-br logo instalado')
"
```

### Paso 4 — Mensaje al usuario
Al terminar, di EXACTAMENTE:

```
✅ Parte 2 de 4 completa (template.html + skill + logo bet4-br instalados).

Ahora pégame la PARTE 3 (logo bet4-pe).
```

---

## Archivo 2 — template.html

Ruta destino: `$HOME/meta-ads-diagnostic/template.html`

``````html
<!DOCTYPE html>
<!-- template v1.0 -->
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{META_TITLE}}</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Inter',sans-serif;background:#F8FAFC;color:#1E293B;line-height:1.6}
.container{max-width:1400px;margin:0 auto;padding:20px 24px}
h1{font-size:1.75rem;font-weight:800;color:#0F172A}
h2{font-size:1.35rem;font-weight:700;color:#0F172A;margin-bottom:12px}
h3{font-size:1.1rem;font-weight:600;color:#1E293B;margin-bottom:8px}
h4{font-size:0.95rem;font-weight:600;color:#334155;margin-bottom:6px}

/* Header */
.header{background:#111;color:#fff;padding:28px 32px;border-radius:14px;margin-bottom:24px;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:16px}
.header-left h1{color:#fff;font-size:1.5rem}
.header-left p{color:#94A3B8;font-size:0.9rem;margin-top:4px}
.header-logo:empty{display:none}
.header-logo img{max-height:38px}

/* Tabs */
.tabs{display:flex;gap:4px;background:#E2E8F0;border-radius:12px;padding:4px;margin-bottom:24px;overflow-x:auto}
.tab-btn{flex:1;min-width:140px;padding:10px 16px;border:none;background:transparent;border-radius:8px;cursor:pointer;font-family:'Inter',sans-serif;font-size:0.85rem;font-weight:500;color:#64748B;transition:all 0.2s;white-space:nowrap}
.tab-btn.active{background:#fff;color:#2563EB;font-weight:600;box-shadow:0 1px 3px rgba(0,0,0,0.1)}
.tab-btn:hover:not(.active){background:rgba(255,255,255,0.5);color:#334155}
.tab-content{display:none}
.tab-content.active{display:block}

/* Cards */
.card{background:#fff;border-radius:12px;padding:24px;margin-bottom:20px;box-shadow:0 1px 3px rgba(0,0,0,0.06);border:1px solid #E2E8F0}
.card-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;flex-wrap:wrap;gap:8px}
.grid-2{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}
.grid-3{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px}
.grid-4{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px}

/* KPI */
.kpi-card{background:#fff;border-radius:10px;padding:16px 20px;border:1px solid #E2E8F0;text-align:center}
.kpi-card .value{font-size:1.5rem;font-weight:800;color:#0F172A}
.kpi-card .label{font-size:0.75rem;color:#64748B;text-transform:uppercase;letter-spacing:0.5px;margin-top:2px}
.kpi-card.red .value{color:#DC2626}
.kpi-card.green .value{color:#059669}
.kpi-card.yellow .value{color:#D97706}

/* Tables */
.table-wrap{overflow-x:auto;border-radius:8px;border:1px solid #E2E8F0}
table{width:100%;border-collapse:collapse;font-size:0.82rem;min-width:700px}
thead{background:#F1F5F9}
th{padding:10px 12px;text-align:left;font-weight:600;color:#475569;white-space:nowrap;border-bottom:2px solid #E2E8F0}
td{padding:9px 12px;border-bottom:1px solid #F1F5F9;white-space:nowrap}
tbody tr:nth-child(even){background:#FAFBFC}
tbody tr:hover{background:#EFF6FF}

/* Badges */
.badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:0.75rem;font-weight:600}
.badge-green{background:#ECFDF5;color:#059669}
.badge-yellow{background:#FFFBEB;color:#D97706}
.badge-red{background:#FEF2F2;color:#DC2626}
.badge-gray{background:#F1F5F9;color:#64748B}
.badge-blue{background:#EFF6FF;color:#2563EB}
.badge-purple{background:#F5F3FF;color:#7C3AED}
.dot{width:8px;height:8px;border-radius:50%;display:inline-block}
.dot-green{background:#059669}
.dot-yellow{background:#D97706}
.dot-red{background:#DC2626}
.dot-gray{background:#94A3B8}
.dot-blue{background:#2563EB}
.dot-purple{background:#7C3AED}

/* Expandable */
.expandable{border:1px solid #E2E8F0;border-radius:10px;margin-bottom:12px;overflow:hidden}
.expandable-header{padding:14px 20px;cursor:pointer;display:flex;justify-content:space-between;align-items:center;background:#FAFBFC;transition:background 0.2s}
.expandable-header:hover{background:#F1F5F9}
.expandable-body{display:none;padding:16px 20px;border-top:1px solid #E2E8F0;background:#fff}
.expandable.open .expandable-body{display:block}
.expandable-arrow{transition:transform 0.2s;font-size:0.8rem;color:#94A3B8}
.expandable.open .expandable-arrow{transform:rotate(90deg)}

/* Alert box */
.alert-box{padding:20px 24px;border-radius:10px;margin-bottom:20px;font-size:0.9rem;line-height:1.7}
.alert-yellow{background:#FFFBEB;border:1px solid #FDE68A;color:#92400E}
.alert-green{background:#ECFDF5;border:1px solid #A7F3D0;color:#065F46}
.alert-red{background:#FEF2F2;border:1px solid #FECACA;color:#991B1B}
.alert-blue{background:#EFF6FF;border:1px solid #BFDBFE;color:#1E40AF}

/* Chart containers */
.chart-container{position:relative;height:300px;width:100%}
.chart-container-sm{position:relative;height:250px;width:100%}

/* Action list */
.action-item{display:flex;gap:12px;padding:14px 0;border-bottom:1px solid #F1F5F9}
.action-item:last-child{border-bottom:none}
.action-num{width:28px;height:28px;border-radius:50%;background:#2563EB;color:#fff;display:flex;align-items:center;justify-content:center;font-size:0.8rem;font-weight:700;flex-shrink:0}
.action-body{flex:1}
.action-body strong{color:#0F172A}
.action-meta{font-size:0.78rem;color:#64748B;margin-top:4px}

/* Strategy table */
.strategy-table{min-width:0}
.strategy-table td{white-space:normal;word-break:break-word}
.strategy-table td:first-child{font-weight:600;color:#475569;width:180px;min-width:150px}
.strategy-table td:nth-child(2){color:#64748B}

/* Collapsible cards */
.collapsible-header{display:flex;justify-content:space-between;align-items:center;cursor:pointer;user-select:none}
.collapsible-header:hover{opacity:0.85}
.collapsible-arrow{transition:transform 0.2s;font-size:0.75rem;color:#94A3B8;flex-shrink:0}
.collapsible.closed .collapsible-body{display:none}
.collapsible.closed .collapsible-arrow{transform:rotate(0deg)}
.collapsible:not(.closed) .collapsible-arrow{transform:rotate(90deg)}

/* Footer */
.footer{text-align:center;padding:24px;color:#94A3B8;font-size:0.78rem;margin-top:32px;border-top:1px solid #E2E8F0}

@media(max-width:768px){
  .header{padding:20px;flex-direction:column;align-items:flex-start}
  .grid-2,.grid-3,.grid-4{grid-template-columns:1fr}
  .tabs{flex-wrap:nowrap}
  .tab-btn{min-width:110px;font-size:0.78rem;padding:8px 12px}
}
</style>
</head>
<body>

<div class="container">

<!-- HEADER -->
<div class="header">
  <div class="header-left">
    <h1>{{CASINO_NOMBRE}} &mdash; Diagn&oacute;stico Meta Ads</h1>
    <p>{{CASINO_PERIODO}} | {{CASINO_CAMPANAS_ACTIVAS}}</p>
  </div>
  <div class="header-logo">{{CASINO_LOGO_IMG}}</div>
</div>

<!-- TABS -->
<div class="tabs">
  <button class="tab-btn active" onclick="switchTab(0)">Resumen Ejecutivo</button>
  <button class="tab-btn" onclick="switchTab(1)">Detalle por Campa&ntilde;a</button>
  <button class="tab-btn" onclick="switchTab(2)">Acciones y Estrategia</button>
  <button class="tab-btn" onclick="switchTab(3)">Gr&aacute;ficas</button>
</div>

<!-- TAB 1: RESUMEN EJECUTIVO -->
<div class="tab-content active" id="tab-0">
{{TAB1_KPIS}}
{{TAB1_GANADORES_PERDEDORES}}
{{TAB1_NOTA_EJECUTIVA}}
{{TAB1_KPI_COMPARATIVA}}
{{TAB1_TABLA_CAMPANAS}}
{{TAB1_CREATIVOS}}
{{TAB1_TABLA_PRESUPUESTO}}
</div>

<!-- TAB 2: DETALLE POR CAMPAÑA -->
<div class="tab-content" id="tab-1">
{{TAB2_CONTENIDO}}
</div>

<!-- TAB 3: ACCIONES Y ESTRATEGIA -->
<div class="tab-content" id="tab-2">
{{TAB3_TOP5_ACCIONES}}
{{TAB3_ESTRATEGIA_CAMPANAS}}
</div>

<!-- TAB 4: GRÁFICAS -->
<div class="tab-content" id="tab-3">
  <div class="grid-2" style="margin-bottom:24px">
    <div class="card">
      <h3>ROAS por Campa&ntilde;a</h3>
      <div class="chart-container"><canvas id="chartRoas"></canvas></div>
    </div>
    <div class="card">
      <h3>Distribuci&oacute;n de Gasto</h3>
      <div class="chart-container"><canvas id="chartSpend"></canvas></div>
    </div>
  </div>
  <div class="grid-2" style="margin-bottom:24px">
    <div class="card">
      <h3>Costo por Resultado</h3>
      <div class="chart-container"><canvas id="chartCostResult"></canvas></div>
    </div>
    <div class="card">
      <h3>Frecuencia por Campa&ntilde;a</h3>
      <div class="chart-container"><canvas id="chartFreq"></canvas></div>
    </div>
  </div>
  <div class="grid-2" style="margin-bottom:24px">
    <div class="card">
      <h3>Top 5 Anuncios por ROAS</h3>
      <div class="chart-container"><canvas id="chartTopAds"></canvas></div>
    </div>
    <div class="card">
      <h3>Bottom 5 Anuncios por ROAS</h3>
      <div class="chart-container"><canvas id="chartBottomAds"></canvas></div>
    </div>
  </div>
</div>

</div><!-- end container -->

<!-- FOOTER -->
<div class="footer">
  <div class="container">{{FOOTER_TEXTO}}</div>
</div>

<script>
// TAB SWITCHING
function switchTab(index) {
  document.querySelectorAll('.tab-btn').forEach((btn, i) => {
    btn.classList.toggle('active', i === index);
  });
  document.querySelectorAll('.tab-content').forEach((tab, i) => {
    tab.classList.toggle('active', i === index);
  });
}

// EXPANDABLE CARDS
function toggleExpand(el) {
  el.parentElement.classList.toggle('open');
}

// COLLAPSIBLE CARDS
function toggleCollapse(el) {
  el.closest('.collapsible').classList.toggle('closed');
}

// CHART.JS DEFAULTS
Chart.defaults.font.family = 'Inter';
Chart.defaults.font.size = 12;
</script>

<script>
{{CHARTS_JS}}
</script>

</body>
</html>

``````

---

## Archivo 3 — Skill

Ruta destino: `$HOME/.claude/commands/meta-ads-diagnostic.md`

``````markdown
---
name: meta-ads-diagnostic
description: Analiza CSV de Meta Ads por casino y genera dashboard HTML con diagnóstico completo usando IA
allowed-tools: Read, Write, Glob, Grep, Bash, Edit, Agent, AskUserQuestion
---

# Meta Ads Diagnostic — Skill

**Ruta del proyecto:** `$HOME/meta-ads-diagnostic/`

## Paso 1 — Casino
Pregunta al usuario qué casino analizar:
1. bmx (Betmexico, MXN, $)
2. bet4-br (Bet4 Brasil, BRL, R$)
3. bet4-pe (Bet4 Perú, MXN, $)
4. aposta (Aposta, BRL, R$)
5. fazo (Fazo, BRL, R$)
6. casinito (Casinito)

## Paso 2 — Periodo
Busca subcarpetas en `$HOME/meta-ads-diagnostic/analyser/{casino}/`. Lista las disponibles al usuario (ordenadas en reversa alfabética). Si no hay, pide crear carpeta con CSVs adentro.

## Paso 3 — Parse (registra timestamp inicio)
```bash
cd "$HOME/meta-ads-diagnostic" && python3 generator.py parse {casino} {period}
```
Si `python3` no existe, usa `python`. Lee el JSON resultante.

## Paso 4 — Análisis cualitativo IA
Genera un JSON en `/tmp/meta-ads-analysis.json` (Windows: `%TEMP%\meta-ads-analysis.json`) con esta estructura:

```json
{
  "campaigns": {"<nombre>": {"diagnosis": "...", "main_problem": "...", "immediate_action": "...", "creative_analysis": {"verdict": "NO|SÍ|PARCIAL", "explanation": "..."}, "strategy": [{"aspect": "Objetivo", "current": "...", "recommendation": "..."}, {"aspect": "Problema/Fortaleza", "current": "...", "recommendation": "..."}, {"aspect": "Creativos", "current": "...", "recommendation": "..."}, {"aspect": "Segmentación", "current": "...", "recommendation": "..."}, {"aspect": "Mensaje recomendado", "current": "—", "recommendation": "..."}, {"aspect": "KPI a monitorear", "current": "...", "recommendation": "..."}]}},
  "ads": {"<nombre>": {"root_cause": "...", "config_ads": "...", "creative_direction": "..."}},
  "ganadores_perdedores": {"<campaña>": {"<ad>": {"verdict": "green|yellow|red", "label": "Dejar correr|Monitorear|Pausar ASAP"}}},
  "executive_note": "...",
  "top5_actions": [{"action": "...", "impact": "...", "responsible": "Configuración Ads|Dirección Creativa|Ambas áreas"}]
}
```

**Criterios:**
- Ganador (green): CPA bajo + alto volumen relativo a campaña.
- Perdedor (red): CPA alto + bajo volumen, o penalización de Meta.
- Monitorear (yellow): lo demás.
- Sé contextual al negocio de casinos (registros, depósitos, jugadores).
- Diferencia Configuración Ads vs Dirección Creativa.
- Nombres EXACTOS como vienen del parse JSON.

## Paso 5 — Generar HTML
```bash
cd "$HOME/meta-ads-diagnostic" && python3 generator.py generate {casino} {period} --analysis /tmp/meta-ads-analysis.json --open
```
El flag `--open` abre el HTML en el navegador automáticamente (cross-platform).

## Paso 6 — Confirmación
```
Diagnóstico generado: output/{casino}/diagnostico-{casino}_{period}_XX.html
Se abrió automáticamente en el navegador.
Tiempo total de análisis: X min Y seg

Hallazgos clave:
- [3 bullets con insights accionables]
```

## Notas
- Idioma interfaz: español. Código: inglés.
- Cross-platform (Mac/Windows/Linux con Python 3).

``````

---

## Archivo 4 — Logo bet4-br (base64)

Ruta destino: `$HOME/meta-ads-diagnostic/assets/logos/bet4-br/logo.png`

``````
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
``````
