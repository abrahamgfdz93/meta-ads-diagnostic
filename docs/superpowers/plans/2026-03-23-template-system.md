# Template System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear `template.html` con placeholders y actualizar la skill `/meta-ads-diagnostic` para inyectar análisis en el template en lugar de generar HTML desde cero.

**Architecture:** Un archivo HTML estático con placeholders `{{VARIABLE}}` que Claude lee, reemplaza con contenido de análisis, y escribe como output. La skill se actualiza para usar este flujo.

**Tech Stack:** HTML/CSS/JS vanilla, Chart.js 4.x (CDN), Google Fonts Inter (CDN)

**Spec:** `docs/superpowers/specs/2026-03-23-template-system-design.md`

---

## Chunk 1: Crear template.html

### Task 1: Crear template.html — Head + CSS completo

**Files:**
- Create: `template.html`

- [ ] **Step 1: Crear archivo con DOCTYPE, head, CSS completo**

Crear `template.html` en la raíz del proyecto con:
- `<!DOCTYPE html>`, `<html lang="es">`, `<head>` con charset, viewport, title con `{{META_TITLE}}`
- CDN: Google Fonts Inter + Chart.js 4.x
- Comentario `<!-- template v1.0 -->`
- CSS completo (~114 líneas) extraído del reporte existente (`output/bet4-br/diagnostico-bet4-br_2026-02-07_2026-03-08.html`) pero con el header actualizado a `#111` (negro) en lugar del gradient azul

CSS a incluir (todos los componentes):
- Reset + body + container + headings
- `.header` — fondo `#111`, border-radius 14px, flex between, logo container con `:empty { display: none }`
- `.tabs` + `.tab-btn` + `.tab-content`
- `.card` + `.card-header` + `.grid-2/3/4`
- `.kpi-card` + variantes `.red`, `.green`, `.yellow`
- `.table-wrap` + `table` + thead/td/th + zebra + hover
- `.badge` + `.badge-green/red/yellow/gray` + `.dot` + `.dot-green/red/yellow/gray`
- `.expandable` + `.expandable-header` + `.expandable-body` + `.expandable-arrow`
- `.alert-box` + `.alert-yellow/green/red/blue`
- `.chart-container` + `.chart-container-sm`
- `.action-item` + `.action-num` + `.action-body`
- `.strategy-table`
- `.footer`
- Media query `@media(max-width:768px)`

- [ ] **Step 2: Verificar que el CSS está completo**

Comparar contra el CSS del reporte existente (líneas 9-114 de `output/bet4-br/diagnostico-bet4-br_2026-02-07_2026-03-08.html`). Todos los selectores deben estar presentes. El único cambio es el header: de gradient azul a `#111` negro.

---

### Task 2: template.html — Body: Header + Tabs + Estructura de 4 tabs

**Files:**
- Modify: `template.html`

- [ ] **Step 1: Agregar header con placeholders**

Después de `<body>`, agregar:
```html
<div class="container">

<!-- HEADER -->
<div class="header">
  <div class="header-left">
    <h1>{{CASINO_NOMBRE}} — Diagnóstico Meta Ads</h1>
    <p style="color:#94A3B8">{{CASINO_PERIODO}} | {{CASINO_CAMPANAS_ACTIVAS}}</p>
  </div>
  <div class="header-logo">{{CASINO_LOGO_IMG}}</div>
</div>
```

- [ ] **Step 2: Agregar navegación de tabs**

```html
<!-- TABS -->
<div class="tabs">
  <button class="tab-btn active" onclick="switchTab(0)">Resumen Ejecutivo</button>
  <button class="tab-btn" onclick="switchTab(1)">Detalle por Campaña</button>
  <button class="tab-btn" onclick="switchTab(2)">Acciones y Estrategia</button>
  <button class="tab-btn" onclick="switchTab(3)">Gráficas</button>
</div>
```

- [ ] **Step 3: Agregar estructura de Tab 1 — Resumen Ejecutivo**

```html
<!-- TAB 1: RESUMEN EJECUTIVO -->
<div class="tab-content active" id="tab-0">
  {{TAB1_NOTA_EJECUTIVA}}
  {{TAB1_KPIS}}
  {{TAB1_TABLA_CAMPANAS}}
  {{TAB1_CREATIVOS}}
  {{TAB1_TABLA_PRESUPUESTO}}
</div>
```

- [ ] **Step 4: Agregar estructura de Tab 2 — Detalle por Campaña**

```html
<!-- TAB 2: DETALLE POR CAMPAÑA -->
<div class="tab-content" id="tab-1">
  {{TAB2_CONTENIDO}}
</div>
```

- [ ] **Step 5: Agregar estructura de Tab 3 — Acciones y Estrategia**

```html
<!-- TAB 3: ACCIONES Y ESTRATEGIA -->
<div class="tab-content" id="tab-2">
  {{TAB3_TOP5_ACCIONES}}
  {{TAB3_ESTRATEGIA_CAMPANAS}}
</div>
```

- [ ] **Step 6: Agregar estructura de Tab 4 — Gráficas con canvas hardcodeados**

```html
<!-- TAB 4: GRÁFICAS -->
<div class="tab-content" id="tab-3">
  <div class="grid-2" style="margin-bottom:24px">
    <div class="card">
      <h3>ROAS por Campaña</h3>
      <div class="chart-container"><canvas id="chartRoas"></canvas></div>
    </div>
    <div class="card">
      <h3>Distribución de Gasto</h3>
      <div class="chart-container"><canvas id="chartSpend"></canvas></div>
    </div>
  </div>
  <div class="grid-2" style="margin-bottom:24px">
    <div class="card">
      <h3>Costo por Resultado</h3>
      <div class="chart-container"><canvas id="chartCostResult"></canvas></div>
    </div>
    <div class="card">
      <h3>Frecuencia por Campaña</h3>
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
```

- [ ] **Step 7: Agregar footer con placeholder**

```html
<!-- FOOTER -->
<div class="footer">
  <div class="container">{{FOOTER_TEXTO}}</div>
</div>
```

---

### Task 3: template.html — JavaScript estático + placeholder de charts

**Files:**
- Modify: `template.html`

- [ ] **Step 1: Agregar JavaScript de tabs y expandibles**

Antes de `</body>`:
```html
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

// CHART.JS DEFAULTS
Chart.defaults.font.family = 'Inter';
Chart.defaults.font.size = 12;
</script>
```

- [ ] **Step 2: Agregar placeholder para datos de charts**

Después del script anterior, antes de `</body>`:
```html
<script>
{{CHARTS_JS}}
</script>
```

- [ ] **Step 3: Cerrar body y html**

```html
</body>
</html>
```

- [ ] **Step 4: Verificar template completo**

Abrir `template.html` en el navegador. Debe mostrar:
- Header negro con placeholders visibles como texto `{{CASINO_NOMBRE}}`
- 4 tabs funcionales (click cambia contenido)
- Tab 4 con 6 canvas vacíos (sin datos aún)
- Layout limpio, sin errores de CSS

```bash
open ~/Desktop/HTECH/CLAUDE CODE/projects/meta-ads-diagnostic/template.html
```

- [ ] **Step 5: Commit template.html**

```bash
cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic
git add template.html
git commit -m "feat: create template.html with placeholders for Meta Ads diagnostic"
```

---

## Chunk 2: Actualizar skill y documentación

### Task 4: Actualizar skill `/meta-ads-diagnostic`

**Files:**
- Modify: `~/Desktop/HTECH/CLAUDE CODE/commands/meta-ads-diagnostic.md`

- [ ] **Step 1: Leer la skill actual**

Leer `~/Desktop/HTECH/CLAUDE CODE/commands/meta-ads-diagnostic.md` para entender la estructura actual.

- [ ] **Step 2: Actualizar Paso 2 — Selección de periodo**

Reemplazar la lógica de selección de carpetas con:
- **0 carpetas:** Mensaje de error
- **1-5 carpetas:** Listar todas (sin auto-seleccionar)
- **6+ carpetas:** Mostrar 5 más recientes + "Ver más carpetas..."
- Paginación de 10 en 10 con "Regresar al menú anterior"
- Las carpetas pueden tener cualquier nombre, ordenar alfabéticamente en reversa

- [ ] **Step 3: Actualizar Paso 5 — Inyección en template**

Reemplazar la sección "Generar Dashboard HTML" con:

```
## Paso 5 — Inyectar análisis en template

1. Lee el archivo `~/Desktop/HTECH/CLAUDE CODE/projects/meta-ads-diagnostic/template.html`
2. Para cada placeholder, genera el HTML correspondiente con los datos del análisis
3. Reemplaza cada `{{PLACEHOLDER}}` con el contenido generado
4. Escribe el HTML final en: `output/{casino}/diagnostico-{casino}_{nombre-carpeta}.html`

### Placeholders a reemplazar:
- {{META_TITLE}} — título del documento
- {{CASINO_NOMBRE}} — nombre del casino
- {{CASINO_PERIODO}} — rango de fechas
- {{CASINO_CAMPANAS_ACTIVAS}} — conteo de campañas activas
- {{CASINO_LOGO_IMG}} — tag <img> con logo base64, o vacío
- {{TAB1_NOTA_EJECUTIVA}} — alert-box amarilla
- {{TAB1_KPIS}} — grid-4 de KPI cards
- {{TAB1_TABLA_CAMPANAS}} — tabla diagnóstico rápido
- {{TAB1_TABLA_PRESUPUESTO}} — tabla presupuesto
- {{TAB1_CREATIVOS}} — cards de cambio creativo
- {{TAB2_CONTENIDO}} — cards por campaña + archivadas
- {{TAB3_TOP5_ACCIONES}} — lista de acciones
- {{TAB3_ESTRATEGIA_CAMPANAS}} — tablas de estrategia
- {{CHARTS_JS}} — new Chart(...) para las 6 gráficas
- {{FOOTER_TEXTO}} — texto del footer

### Clases CSS disponibles en el template:
(listar las clases para que Claude sepa qué HTML generar)
```

- [ ] **Step 4: Actualizar Paso 6 — Nombre del archivo output**

Cambiar el formato del nombre de archivo de `diagnostico-{casino}_{fecha-inicio}_{fecha-fin}.html` a `diagnostico-{casino}_{nombre-carpeta}.html` usando el nombre exacto de la carpeta.

- [ ] **Step 5: Commit skill actualizada**

```bash
git add ~/Desktop/HTECH/CLAUDE CODE/commands/meta-ads-diagnostic.md
git commit -m "feat: update meta-ads-diagnostic skill to use template system"
```

---

### Task 5: Actualizar CLAUDE.md del proyecto

**Files:**
- Modify: `~/Desktop/HTECH/CLAUDE CODE/projects/meta-ads-diagnostic/CLAUDE.md`

- [ ] **Step 1: Agregar sección sobre el template**

Agregar después de "## Dos formas de usar":

```markdown
### Template system
- `template.html` contiene todo el CSS, layout y JS estático
- La skill lee el template, inyecta el análisis vía placeholders `{{VARIABLE}}`, y escribe el output
- Para cambiar el diseño visual: editar `template.html` directamente
- Los canvas de Chart.js tienen IDs fijos en Tab 4: chartRoas, chartSpend, chartCostResult, chartFreq, chartTopAds, chartBottomAds
```

- [ ] **Step 2: Actualizar la estructura del proyecto**

Agregar `template.html` al árbol de archivos en la sección "Estructura del proyecto".

- [ ] **Step 3: Actualizar el pendiente del roadmap**

Cambiar el item `PRIORITARIO: Migrar a template con placeholders` de `[ ]` a `[x]` y agregar fecha.

- [ ] **Step 4: Commit CLAUDE.md**

```bash
cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with template system documentation"
```

---

### Task 6: Prueba de integración — Generar reporte de bet4-br con el template

**Files:**
- Input: `analyser/bet4-br/260323/*.csv`
- Output: `output/bet4-br/diagnostico-bet4-br_260323.html`

- [ ] **Step 1: Ejecutar `/meta-ads-diagnostic bet4-br`**

Correr la skill completa con los datos existentes de bet4-br. Verificar:
- Se muestran las carpetas (incluyendo `260323`)
- Se lee el template correctamente
- Se inyectan todos los placeholders
- Se genera el HTML final

- [ ] **Step 2: Abrir y verificar visualmente**

Abrir el HTML generado en el navegador. Verificar:
- Header negro con "Bet4 Brasil — Diagnóstico Meta Ads" + logo
- 4 tabs funcionales
- Tab 1: KPIs, tabla diagnóstico, creativos, presupuesto
- Tab 2: Cards por campaña con tablas y expandibles
- Tab 3: Top 5 acciones + estrategia
- Tab 4: 6 gráficas renderizadas con datos
- Footer correcto
- Responsive en móvil (reducir ventana)

- [ ] **Step 3: Comparar con reporte anterior**

Abrir side-by-side con `output/bet4-br/diagnostico-bet4-br_2026-02-07_2026-03-08.html`. El contenido de análisis debe ser equivalente (mismo semáforo, mismas recomendaciones). El diseño visual cambia (header negro vs gradient).

- [ ] **Step 4: Commit reporte generado**

```bash
cd ~/Desktop/HTECH/CLAUDE\ CODE/projects/meta-ads-diagnostic
git add output/bet4-br/diagnostico-bet4-br_260323.html
git commit -m "test: generate bet4-br report using template system"
```
