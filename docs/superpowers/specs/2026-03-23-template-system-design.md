# Spec: Sistema de Template con Placeholders para Meta Ads Diagnostic

**Fecha:** 2026-03-23
**Proyecto:** meta-ads-diagnostic
**Casino de referencia:** bet4-br (Bet4 Brasil)

---

## Problema

Cada vez que se ejecuta `/meta-ads-diagnostic`, Claude genera ~1,200 líneas de HTML desde cero (CSS + layout + contenido + JS + charts). Esto toma ~8 minutos porque Claude reescribe toda la estructura visual cada vez, aunque el 60% del archivo es idéntico entre reportes.

## Solución

Crear un archivo `template.html` con todo el CSS, layout HTML y JavaScript estático, usando placeholders `{{VARIABLE}}` donde va el contenido dinámico. Claude solo genera los bloques de análisis (~400 líneas) y los inyecta en el template.

**Tiempo estimado post-migración:** ~2-3 minutos por reporte.

---

## Arquitectura

### Archivo nuevo: `template.html`

Ubicación: `~/Desktop/HTECH/CLAUDE CODE/projects/meta-ads-diagnostic/template.html`

Contenido (~300 líneas):
- CSS completo (estilos aprobados: header negro #111, paleta de colores, cards, badges, tablas, expandibles, alertas, responsive)
- Estructura HTML de 4 tabs vacía con placeholders
- JavaScript estático (switchTab, toggleExpand, Chart.js defaults)
- Placeholder `{{CHARTS_JS}}` para los datos de gráficas

### Placeholders definidos

#### Metadata y header
| Placeholder | Tipo | Ejemplo |
|-------------|------|---------|
| `{{META_TITLE}}` | texto | `Diagnóstico Meta Ads — Bet4 Brasil \| 2026-02-07 al 2026-03-08` |
| `{{CASINO_NOMBRE}}` | texto | `Bet4 Brasil` |
| `{{CASINO_PERIODO}}` | texto | `2026-02-07 al 2026-03-08` |
| `{{CASINO_CAMPANAS_ACTIVAS}}` | texto | `3 campañas activas` |
| `{{CASINO_LOGO_IMG}}` | HTML | `<img src="data:image/png;base64,..." style="max-height:38px">` si existe logo. Si no hay logo, se reemplaza con cadena vacía y el contenedor CSS se oculta automáticamente (`:empty { display: none }`) |

#### Tab 1 — Resumen Ejecutivo
| Placeholder | Tipo | Descripción |
|-------------|------|-------------|
| `{{TAB1_NOTA_EJECUTIVA}}` | HTML | Alert-box amarilla con nota para directivos |
| `{{TAB1_KPIS}}` | HTML | Grid de 4 KPI cards (Gasto Total, Resultados, ROAS Ponderado, CPM Promedio) |
| `{{TAB1_TABLA_CAMPANAS}}` | HTML | Tabla "Diagnóstico Rápido por Campaña" (Campaña, Tipo, Estado, Problema, Acción) |
| `{{TAB1_TABLA_PRESUPUESTO}}` | HTML | Tabla distribución de presupuesto con recomendaciones |
| `{{TAB1_CREATIVOS}}` | HTML | Cards "¿Es suficiente solo cambiar imágenes?" (grid-3 con alertas) |

#### Tab 2 — Detalle por Campaña
| Placeholder | Tipo | Descripción |
|-------------|------|-------------|
| `{{TAB2_CONTENIDO}}` | HTML | Cards por campaña activa: header + diagnóstico + KPIs + tabla anuncios + expandibles con análisis por anuncio. Al final: sección de campañas archivadas (colapsada, atenuada) |

#### Tab 3 — Acciones y Estrategia
| Placeholder | Tipo | Descripción |
|-------------|------|-------------|
| `{{TAB3_TOP5_ACCIONES}}` | HTML | Lista de 5 acciones con action-items |
| `{{TAB3_ESTRATEGIA_CAMPANAS}}` | HTML | Strategy tables por campaña (Aspecto / Situación Actual / Recomendación) |

#### Tab 4 — Gráficas
Los 6 canvas con IDs fijos están hardcodeados en el template (no son placeholders). Solo se inyecta el JavaScript con los datos:

#### Charts (JavaScript)
| Placeholder | Tipo | Descripción |
|-------------|------|-------------|
| `{{CHARTS_JS}}` | JavaScript | Bloque completo con `new Chart(...)` para las 6 gráficas, con datos embebidos. Los canvas con IDs fijos están hardcodeados en el template: `chartRoas`, `chartSpend`, `chartCostResult`, `chartFreq`, `chartTopAds`, `chartBottomAds` |

#### Footer
| Placeholder | Tipo | Descripción |
|-------------|------|-------------|
| `{{FOOTER_TEXTO}}` | texto | `Diagnóstico Meta Ads — Bet4 Brasil — Período: ...` |

---

## Diseño visual (aprobado)

### Header
```css
background: #111;
border-radius: 14px;
padding: 28px 32px;
display: flex;
align-items: center;
justify-content: space-between;
```
- Izquierda: título 24px blanco + subtítulo con fecha y campañas activas en #94A3B8
- Derecha: logo del casino (max-height: 38px) embebido en base64

### Paleta
- Primary: `#2563EB`
- Positivo: `#059669` | Negativo: `#DC2626` | Warning: `#D97706` | Naranja: `#F97316`
- Background: `#F8FAFC` | Surface: `#FFFFFF`
- Texto: `#0F172A` (t1), `#475569` (t2), `#94A3B8` (t3)

### 4 Tabs
1. Resumen Ejecutivo
2. Detalle por Campaña
3. Acciones y Estrategia
4. Gráficas

### Componentes CSS (del reporte existente)
- `.card` — cards con borde sutil y sombra
- `.kpi-card` — KPI con variantes `.red`, `.green`, `.yellow`
- `.badge` / `.badge-green` / `.badge-red` / `.badge-yellow` / `.badge-gray`
- `.dot` / `.dot-green` / `.dot-red` / `.dot-yellow` / `.dot-gray`
- `.table-wrap` + `table` — tablas responsive con zebra striping
- `.expandable` / `.expandable-header` / `.expandable-body` — secciones colapsibles
- `.alert-box` + `.alert-yellow` / `.alert-green` / `.alert-red` / `.alert-blue`
- `.action-item` / `.action-num` / `.action-body` — lista numerada de acciones
- `.strategy-table` — tablas de estrategia (primera columna bold)
- `.chart-container` / `.chart-container-sm` — contenedores de Chart.js
- `.grid-2` / `.grid-3` / `.grid-4` — layouts de grid responsive

### Dependencias CDN
- Google Fonts: Inter (wght 300-800)
- Chart.js 4.x: `https://cdn.jsdelivr.net/npm/chart.js`

---

## Flujo de la skill `/meta-ads-diagnostic` (actualizado)

### Paso 1 — Selección de casino
Sin cambios. Pregunta o recibe argumento.

### Paso 2 — Selección de periodo (MODIFICADO)

Busca subcarpetas en `analyser/{casino}/`. **Siempre muestra las carpetas**, incluso si hay solo 1. Las carpetas pueden tener cualquier nombre (no se valida formato). Se ordenan alfabéticamente en reversa (más recientes primero asumiendo nombres con fecha).

**0 carpetas:**
```
No hay carpetas de CSV para este casino.
Crea una carpeta en analyser/{casino}/ y coloca los CSV dentro.
```

**1-5 carpetas:**
```
Periodos disponibles para Bet4 Brasil:
1. 260323
2. 150323
```

**6+ carpetas (primera vista — 5 más recientes):**
```
Periodos disponibles para Bet4 Brasil (más recientes):
1. 260323
2. 150323
3. 010323
4. 150223
5. 010223

6. Ver más carpetas...
```

**Al seleccionar "Ver más carpetas..." — paginación de 10:**
```
Más carpetas para Bet4 Brasil (6-15):
6. 301222
7. 151222
...
15. 150722

16. Ver más carpetas...
0. Regresar al menú anterior
```

"Regresar al menú anterior" → vuelve a mostrar las 5 más recientes.
La paginación continúa de 10 en 10 hasta agotar carpetas.

### Paso 3 — Lectura y parseo de CSVs
Sin cambios respecto a la skill actual.

### Paso 4 — Análisis con IA
Sin cambios. Claude analiza los datos con la misma lógica (semáforos, raíz causa, estrategia, etc.).

### Paso 5 — Inyección en template (NUEVO — reemplaza "Generar HTML desde cero")

1. Claude lee `template.html`
2. Claude genera cada bloque de contenido HTML para los placeholders
3. Claude reemplaza `{{PLACEHOLDER}}` → contenido generado
4. Claude escribe el HTML final en `output/{casino}/diagnostico-{casino}_{nombre-carpeta}.html` (donde `nombre-carpeta` es el nombre exacto de la carpeta seleccionada, ej: `260323`)

### Paso 6 — Abrir en navegador
Sin cambios. `open {ruta}`.

---

## Notas de diseño

### Referencia visual
El diseño aprobado es el del screenshot mostrado por Abraham el 2026-03-23, que tiene:
- Header negro (#111) con título + subtítulo + logo (NO el gradient azul del HTML viejo)
- KPIs como cards dentro del Tab 1 (NO como badges en el header)
- 4 tabs: Resumen Ejecutivo, Detalle por Campaña, Acciones y Estrategia, Gráficas

El HTML existente en `output/bet4-br/` usa un diseño anterior (header gradient, tabs diferentes). El template se basa en el diseño aprobado, no en el HTML viejo.

### Canvas IDs para Chart.js
Los 6 canvas están hardcodeados en el template dentro de Tab 4 (Gráficas) con la estructura de grids:
- `chartRoas` — ROAS por Campaña (bar)
- `chartSpend` — Distribución de Gasto (doughnut)
- `chartCostResult` — Costo por Resultado (bar)
- `chartFreq` — Frecuencia por Campaña (bar)
- `chartTopAds` — Top 5 Anuncios por ROAS (horizontal bar)
- `chartBottomAds` — Bottom 5 Anuncios por ROAS (horizontal bar)

### Manejo sin logo
El contenedor del logo en el header usa `:empty { display: none }` para no dejar espacio vacío cuando `{{CASINO_LOGO_IMG}}` se reemplaza con cadena vacía.

### Formato de carpetas
Las carpetas en `analyser/{casino}/` pueden tener cualquier nombre. No se valida formato. Se ordenan alfabéticamente en reversa para mostrar las más recientes primero.

### Versionado del template
El template incluye un comentario HTML: `<!-- template v1.0 -->` para rastrear cambios futuros.

---

## Estructura de archivos

```
meta-ads-diagnostic/
├── template.html              ← NUEVO
├── CLAUDE.md                  (actualizar con info del template)
├── index.html                 (sin cambios — backup interactivo)
├── analyser/{casino}/         (sin cambios)
├── output/{casino}/           (sin cambios)
├── assets/logos/{casino}/     (sin cambios)
├── docs/superpowers/specs/    ← NUEVO
│   └── 2026-03-23-template-system-design.md
└── COMPARTIR/                 (sin cambios)
```

---

## Qué NO cambia

- La lógica de análisis de IA (semáforos, raíz causa, estrategia)
- El formato de los CSVs
- La estructura de carpetas de analyser/ y output/
- El dashboard interactivo (index.html)
- Los logos y assets
- El kit COMPARTIR

## Qué SÍ cambia

- Se crea `template.html` con todo el CSS/JS/layout y placeholders
- La skill ya no genera HTML desde cero, sino que inyecta en el template
- Se actualiza el flujo de selección de carpetas (siempre mostrar, paginación)
- Se actualiza CLAUDE.md con la documentación del template
- Se actualiza la skill `meta-ads-diagnostic` para usar el template

---

## Criterios de éxito

1. Generar un reporte idéntico visualmente al actual usando el template
2. Tiempo de generación < 3 minutos (vs ~8 actuales)
3. Cambiar un estilo CSS en template.html se refleja en todos los futuros reportes
4. La selección de carpetas funciona con 0, 1, 5 y 6+ carpetas
