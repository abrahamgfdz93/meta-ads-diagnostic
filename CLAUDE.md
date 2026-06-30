# Meta Ads Diagnostic — Diagnóstico de Campañas Meta Ads

## Qué es esta herramienta

Sistema que analiza CSV exportados de Meta Ads y genera un dashboard HTML con diagnóstico completo por casino. Usa `generator.py` para el trabajo mecánico (parseo, KPIs, semáforos, HTML) y Claude IA para el análisis cualitativo (diagnósticos, causa raíz, estrategia). Incluye semáforos de 4 niveles, análisis de raíz causa por anuncio, estrategia por campaña, y gráficas comparativas.

## Dos formas de usar

### 1. Skill con IA (recomendado) — `/meta-ads-diagnostic`
- Ejecutar desde Claude Code: `/meta-ads-diagnostic` o `/meta-ads-diagnostic bet4-br`
- `generator.py` parsea los CSV y calcula semáforos, KPIs, benchmarks (~1 seg)
- Claude IA analiza los datos y genera diagnósticos cualitativos (~1-2 min)
- `generator.py` arma el HTML final con template + análisis (~1 seg)
- Tiempo total: ~2-3 minutos (antes ~7-10 min)
- El HTML se guarda en `output/{casino}/` y se abre automáticamente

### generator.py — Motor de generación
- **Modo parse:** `python3 generator.py parse {casino} {periodo}` → JSON con datos estructurados, semáforos, benchmarks, ganadores/perdedores
- **Modo generate:** `python3 generator.py generate {casino} {periodo} --analysis /tmp/analysis.json` → HTML final
- Python maneja: encoding CSV, clasificación campañas, semáforos 4 niveles, benchmarks, ganadores/perdedores, KPIs globales, HTML de todos los placeholders, gráficas Chart.js, logo base64, formato de moneda
- La IA solo escribe: diagnósticos, causa raíz, nota ejecutiva, análisis creativos, top 5 acciones, estrategia
- Sin dependencias externas — solo Python 3 stdlib

### Template system
- `template.html` contiene todo el CSS, layout y JS estático del dashboard
- `generator.py` lee el template, inyecta el contenido vía placeholders `{{VARIABLE}}`, y escribe el output
- Para cambiar el diseño visual: editar `template.html` directamente
- Los canvas de Chart.js tienen IDs fijos en Tab 4: chartRoas, chartSpend, chartCostResult, chartFreq, chartTopAds, chartBottomAds
- Las carpetas de periodos pueden tener cualquier nombre (no se valida formato)

### 2. Dashboard interactivo (backup) — `index.html`
- Abrir `index.html` en Chrome (doble clic)
- Drag & drop de CSV, análisis instantáneo con reglas fijas
- Útil para análisis rápidos sin Claude Code

## Stack técnico

- **Skill:** `generator.py` (Python 3 stdlib) + Claude IA para análisis cualitativo
- **Dashboard backup:** HTML/CSS/JS vanilla + Chart.js + html2canvas + jsPDF
- **Output:** HTML autocontenido con Chart.js (CDN) e Inter (Google Fonts)

## Estructura del proyecto

```
meta-ads-diagnostic/
├── CLAUDE.md              # Esta documentación
├── generator.py           # Motor de parseo CSV + generación HTML (Python 3)
├── template.html          # Template con placeholders para el generador
├── index.html             # Dashboard interactivo (backup)
├── analyser/              # CSV de Meta Ads organizados por casino y periodo
│   ├── bmx/
│   │   └── {nombre-periodo}/   ← carpeta con CSV (cualquier nombre)
│   ├── bet4-br/
│   ├── bet4-pe/
│   ├── aposta/
│   ├── fazo/
│   └── casinito/
├── assets/
│   └── logos/             # Logos de cada casino (logo.png)
│       ├── bmx/logo.png       ✓
│       ├── bet4-br/logo.png   ✓
│       ├── bet4-pe/logo.png   ✓
│       ├── aposta/
│       ├── fazo/
│       └── casinito/
├── output/                # HTML generados por la skill
│   ├── bmx/
│   ├── bet4-br/
│   ├── bet4-pe/
│   ├── aposta/
│   ├── fazo/
│   └── casinito/
├── COMPARTIR/             # Kit de instalación v1 (legacy — INSTALAR.txt + INSTRUCCIONES.md)
│   ├── INSTRUCCIONES.md
│   ├── INSTALAR.txt
│   └── meta-ads-diagnostic.md
└── COMPARTIR-v2/          # Kit de instalación v2 — 4 archivos .md cross-platform
    ├── LEEME-PRIMERO.md
    ├── INSTALAR-parte-1-de-4.md   # instrucciones + generator.py
    ├── INSTALAR-parte-2-de-4.md   # template.html + skill + logo bet4-br
    ├── INSTALAR-parte-3-de-4.md   # logo bet4-pe
    └── INSTALAR-parte-4-de-4.md   # logo bmx (optimizado) + verificación
```

## Cómo ejecutar (Skill con IA)

1. Colocar los CSV en `analyser/{casino}/{nombre-carpeta}/` (cualquier nombre)
2. Abrir Claude Code
3. Escribir `/meta-ads-diagnostic` (o `/meta-ads-diagnostic bet4-br`)
4. Seleccionar casino y periodo si hay varios
5. Esperar ~2-3 minutos (generator.py parsea + IA analiza + generator.py genera HTML)
6. El reporte HTML se abre automáticamente en el navegador
7. El archivo queda en `output/{casino}/`

## Compartir con el equipo (v2 — recomendada, 2026-04-20)

**4 archivos pequeños** en `COMPARTIR-v2/`:
- `LEEME-PRIMERO.md` — instrucciones de orden
- `INSTALAR-parte-1-de-4.md` (~42 KB) — instrucciones + `generator.py`
- `INSTALAR-parte-2-de-4.md` (~35 KB) — `template.html` + skill + logo `bet4-br`
- `INSTALAR-parte-3-de-4.md` (~34 KB) — logo `bet4-pe`
- `INSTALAR-parte-4-de-4.md` (~42 KB) — logo `bmx` (optimizado 400px) + verificación final

**Por qué 4 partes:** Claude Code tiene un límite de ~50,000 caracteres por mensaje. La versión monolítica anterior (~327 KB) excedía el límite y se truncaba. Cada parte queda bajo 45 KB con margen de seguridad.

**Flujo para el equipo:**
1. Abre parte 1 → Cmd+A → Cmd+C → pega en Claude Code → Enter. Claude instala `generator.py`.
2. Espera "Parte 1 completa" → pega parte 2 en el mismo chat → Enter. Claude instala template + skill + logo bet4-br.
3. Espera "Parte 2 completa" → pega parte 3 → Enter. Claude instala logo bet4-pe.
4. Espera "Parte 3 completa" → pega parte 4 → Enter. Claude instala logo bmx + verifica + muestra mensaje final.

En la parte 1, Claude detecta el SO (Mac/Windows/Linux), verifica Python 3 y crea las carpetas. Las partes 2-4 solo pegan archivos.

**Optimización del logo bmx:** el original era 3840×2114 px (159 KB). Para distribución se reduce a 400 px de ancho (~30 KB) — más que suficiente para el reporte (se muestra a max-height 38 px). Los logos bet4-br y bet4-pe se distribuyen idénticos al original.

**Instalación destino** (fija en el home del usuario):
- Proyecto: `~/meta-ads-diagnostic/`
- Skill: `~/.claude/commands/meta-ads-diagnostic.md`

Si ya existe una instalación previa, sobrescribe `generator.py`, `template.html`, logos y skill, pero **preserva** los CSVs en `analyser/` y los reportes en `output/`.

### Diferencias con el proyecto local de Abraham
El `.md` de distribución es funcionalmente idéntico al proyecto local, con 2 cambios mecánicos:
1. **Ruta del proyecto:** `~/meta-ads-diagnostic/` (en vez de `~/Desktop/HTECH/CLAUDE CODE/projects/meta-ads-diagnostic/`) — simplifica para equipo no técnico, sin espacios ni mayúsculas.
2. **Apertura del HTML:** `generator.py --open` usa `webbrowser` de Python (cross-platform) en vez del comando `open` de Mac.

El HTML generado es byte-idéntico al del proyecto local (mismo template, misma lógica, mismos logos).

## Compartir con el equipo (v1 — legacy)

La carpeta `COMPARTIR/` contiene la primera versión (INSTALAR.txt + INSTRUCCIONES.md + copia de skill). Sigue existiendo por histórico pero **no usar para nuevos integrantes** — tiene rutas hardcoded al Desktop de Abraham y no incluye logos.

## Exportar PDF

- Primera vez: Chrome pide seleccionar la carpeta `output` del proyecto
- A partir de ahí, se guarda automáticamente en `output/{casino-id}/` sin volver a preguntar (dentro de la misma sesión)
- Si usa Safari u otro navegador sin File System Access API, descarga normal

## Estructura de los CSV de Meta

### CSV Global (Resumen de campañas) — 18 columnas
Inicio/Fin del informe, Nombre de la campaña, Entrega, Resultados, Indicador de resultado, Costo por resultados, Presupuesto del conjunto de anuncios, Tipo de presupuesto, Importe gastado, Impresiones, Alcance, Frecuencia, CPM, Compras, Finalización, Configuración de atribución, ROAS

### CSV por Campaña (Anuncios individuales) — 25 columnas
Las 18 anteriores + Puja, Tipo de puja, Último cambio significativo, Clasificación de calidad, Clasificación del porcentaje de interacción, Clasificación del porcentaje de conversiones, Nombre del conjunto de anuncios

**Nota encoding:** Los CSV de Meta tienen problemas UTF-8 (ej: "campaÃ±a"). El parser corrige esto automáticamente.

## Motor de análisis

### Semáforo de campaña (3 niveles — basado en ROAS)
| ROAS | Estado | Significado |
|------|--------|-------------|
| < 1.0 | 🔴 Crítico | Perdiendo dinero |
| 1.0 - 5.0 | 🟡 Atención | Aceptable pero necesita mejora |
| > 5.0 | 🟢 Saludable | Buen rendimiento |

### Semáforo de anuncio (4 niveles — relativo a la campaña)
| Nivel | Criterios |
|-------|-----------|
| 🟢 Óptimo | Top performer relativo a su campaña, sin penalización Meta |
| 🟡 Monitorear | ROAS 1-5x sin problemas de calidad, o frecuencia >7, o CPM >1.5× promedio |
| 🟠 Pausar | ROAS <1x con gasto significativo SIN penalización, o vol <50 en 30d |
| 🔴 PAUSAR YA | Clasificación "por debajo del promedio" de Meta (SIEMPRE, independiente del ROAS) |

El semáforo se evalúa **en contexto de cada campaña**, no con umbrales absolutos. Si el BENCHMARK de una campaña tiene ROAS < 1.5, la campaña entera es problemática.

### Análisis de raíz causa por anuncio (3 columnas)
- **Origen del Problema** — diagnóstico contextual (ej: "Meta penalizó este anuncio", "audiencia saturada")
- **Configuración Ads** — qué cambiar en Meta Ads Manager (puja, segmentación, presupuesto)
- **Dirección Creativa** — qué hacer con los creativos (renovar, pausar, nuevo concepto)

### Diagnóstico por campaña (4 estados)
- **Crítica** (🔴): ROAS < 1.0
- **Media-alta** (🟡): ROAS 1-5x, o ROAS bueno pero >40% gasto en anuncios débiles
- **Funciona bien** (🟢): ROAS > 5x con distribución razonable
- **Excelente** (🟢🟢): ROAS > 15x con mayoría de anuncios saludables
- **Problema principal** y **acción inmediata quirúrgica** (nombrar anuncios específicos)
- **Estrategia por campaña:** tabla Aspecto / Situación Actual / Recomendación con 6 aspectos

### Tipos de campaña (detección automática por nombre)
- Contiene "ALL" → **Captación** — Rojo `#DC2626` (badge-red) — métrica: registros
- Contiene "Retener" o "Retargeting" → **Retención** — Azul `#2563EB` (badge-blue) — métrica: compras/depósitos
- Contiene "Reactivar" o "Revivir" → **Reactivación** — Morado `#7C3AED` (badge-purple) — métrica: compras/depósitos

### Áreas responsables en recomendaciones
- **Configuración Ads** — pujas, audiencias, presupuesto, segmentación en Meta Ads Manager
- **Dirección Creativa** — diseño, formato, mensaje visual de los anuncios
- **Ambas áreas** — decisiones que requieren cambio conjunto

### Alertas de frecuencia
| Frecuencia | Nivel |
|-----------|-------|
| > 7 | ⚠️ Fatiga creativa — renovar artes |
| > 15 | 🔴 Alerta — renovación urgente |
| > 25 | 🔴🔴 Emergencia |

## Casinos configurados

| Casino | ID | Moneda | País |
|--------|----|--------|------|
| Betmexico | bmx | MXN | México |
| Bet4 Perú | bet4-pe | MXN | Perú |
| Bet4 Brasil | bet4-br | BRL | Brasil |
| Aposta | aposta | BRL | Brasil |
| Fazo | fazo | BRL | Brasil |
| Casinito | casinito | TBD | TBD |

## 4 Pestañas del dashboard

1. **Resumen Ejecutivo** — KPIs globales (siempre visible arriba), ⚡ Ganadores/Perdedores por CPA+volumen, nota ejecutiva, KPI comparativa lado a lado, diagnóstico rápido, análisis de creativos, distribución presupuesto. Todas las secciones son cards colapsables excepto KPIs globales.
2. **Detalle por Campaña** — Cards por campaña con tabla de anuncios, semáforo 4 niveles, expandibles por anuncio con raíz causa (Origen / Configuración Ads / Dirección Creativa). Archivadas al final colapsadas.
3. **Acciones y Estrategia** — Top 5 acciones quirúrgicas con impacto estimado y área responsable, estrategia por campaña
4. **Gráficas** — ROAS comparativo, costo/resultado, distribución gasto, frecuencia, top 5 mejores/peores anuncios

## Funcionalidades

- **Limpiar** — botón que resetea archivos adjuntos, análisis, gráficas y vuelve al estado inicial
- **Historial** — almacena análisis anteriores en IndexedDB del navegador
- **Exportar PDF** — guarda directamente en `output/{casino}/` (Chrome con File System Access)

## Convenciones

- Idioma interfaz: español
- Idioma código: inglés (variables, funciones)
- Tema visual: light mode, paleta multicolor para gráficas
- Sin frameworks — vanilla HTML/CSS/JS

## Diseño del dashboard (aprobado 2026-03-23)

- **Header:** Bloque negro completo (#111, border-radius 14px, padding 28px 32px)
  - Izquierda: título 24px blanco + subtítulo con fecha y conteo de campañas
  - Derecha: logo del casino (max-height 38px) embebido en base64
  - Sin fecha duplicada
- **Tema:** Light mode, Inter font, paleta multicolor para gráficas
- **Mockup aprobado:** `/tmp/template_preview.html` (referencia temporal)

## Pendientes (roadmap)

- [x] **Migrar a template con placeholders** — Completado 2026-03-23. `template.html` con 15 placeholders. Reduce tiempo de ~8 min a ~2-3 min.
- [x] **Fix CSS strategy-table** — 2026-03-23. Texto en tablas de causa raíz ahora hace wrap (no scroll horizontal).
- [x] **Actualizar COMPARTIR** — 2026-03-23. Los 3 archivos sincronizados con template system (skill, INSTALAR.txt con template embebido, instrucciones con carpetas flexibles).
- [x] **Semáforos calibrados por contexto** — 2026-03-23. Evaluación relativa a campaña, no absoluta. "Por debajo del promedio" de Meta SIEMPRE es 🔴.
- [x] **Columnas genéricas** — 2026-03-23. "Config Pablo" → "Configuración Ads", "Arte Abraham" → "Dirección Creativa".
- [x] **Ganadores/Perdedores** — 2026-03-23. Nueva sección Tab 1 basada en CPA+volumen. Primer bloque visible tras KPIs.
- [x] **KPI comparativa lado a lado** — 2026-03-23. Tabla con campañas en columnas, indicadores en filas.
- [x] **Cards colapsables** — 2026-03-23. Todas las secciones de cards son colapsables (excepto KPIs globales).
- [x] **KPIs globales arriba** — 2026-03-23. Grid-4 siempre visible como primer elemento de Tab 1.
- [x] **Cronómetro** — 2026-03-23. Mide tiempo total del proceso y lo muestra al finalizar.
- [x] **Estados de campaña matizados** — 2026-03-23. 4 niveles: Crítica/Media-alta/Funciona bien/Excelente.
- [x] **Logos bmx y bet4-pe** — 2026-03-26. Agregados.
- [ ] Agregar logos faltantes: aposta, fazo, casinito
- [ ] Comparación side-by-side de dos periodos del mismo casino
- [ ] Gráficas de tendencia histórica (ROAS/CPA en el tiempo)
- [ ] Modo offline (embeber CDNs como fallback)
- [x] **COMPARTIR universal** — 2026-03-24. Rutas hardcodeadas → `{BASE}` placeholder. Skill se instala en `~/.claude/commands/` (universal). INSTALAR.txt pregunta carpeta base al usuario, busca automáticamente, confirma antes de instalar.
- [x] **generator.py — Motor de generación** — 2026-03-26. Python script con dos modos (parse/generate). Reduce tiempo de ~7 min a ~2-3 min. Maneja: parseo CSV, encoding, clasificación campañas, semáforos 4 niveles, benchmarks, ganadores/perdedores, KPIs, HTML completo, Chart.js, logo base64. La IA solo escribe el análisis cualitativo como JSON.
- [x] **COMPARTIR-v2 — archivo .md único** — 2026-04-20. Reemplaza el approach de INSTALAR.txt + archivos separados por un solo `.md` con todo embebido (generator.py, template.html, skill, 3 logos en base64). Tu compañero copia y pega el .md en Claude Code; Claude detecta SO, verifica Python, instala todo en `~/meta-ads-diagnostic/`. Cross-platform (Mac/Windows/Linux).
- [x] **Flag `--open` en generator.py** — 2026-04-20. El modo `generate` acepta `--open` para abrir el HTML automáticamente con `webbrowser` de Python (cross-platform). Reemplaza la dependencia del comando `open` de Mac en la skill.
- [ ] Agregar logos faltantes: aposta, fazo, casinito
- [ ] Comparación side-by-side de dos periodos del mismo casino
- [ ] Gráficas de tendencia histórica (ROAS/CPA en el tiempo)
- [ ] Modo offline (embeber CDNs como fallback)

---

*Creado: 23 de marzo de 2026*
*Última actualización: 20 de abril de 2026*
