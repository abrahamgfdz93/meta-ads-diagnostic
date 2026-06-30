# Cómo usar Meta Ads Diagnostic

## Qué es

Una herramienta que analiza los CSV que exportas de Meta Ads Manager y genera un **reporte visual completo** en tu navegador (Chrome, Safari, etc).

El reporte incluye:
- Ganadores y Perdedores por anuncio (CPA + volumen) — lo primero que ves al abrir
- KPIs comparativos lado a lado por campaña
- Diagnóstico de cada campaña con semáforos de colores
- Secciones colapsables para navegar fácilmente
- Recomendaciones específicas (qué cambiar en Configuración Ads y qué cambiar en Dirección Creativa)
- Gráficas de rendimiento
- Nota ejecutiva para directivos
- Todo en un solo archivo HTML que puedes compartir por correo o Slack

Funciona dentro de **Claude Code** (la terminal de Claude).

---

## Requisitos previos

- Tener **Claude Code** instalado y funcionando en tu computadora
  - Descárgalo aquí: https://claude.ai/download
  - Si no lo tienes o no sabes cómo instalarlo, **pídele a Abraham que te ayude**

---

## Paso 1 — Instalar la herramienta (solo la primera vez)

Esto solo se hace **una vez**. Después ya no necesitas repetirlo.

1. Abre **Claude Code** (la terminal negra con texto)
2. Abre el archivo `INSTALAR.txt` que viene junto a estas instrucciones
3. **Copia TODO el texto** del archivo `INSTALAR.txt` (selecciona todo con Cmd+A o Ctrl+A, luego Cmd+C o Ctrl+C)
4. **Pega el texto** en Claude Code (Cmd+V o Ctrl+V)
5. Presiona **Enter**
6. Claude te preguntará **en qué carpeta quieres instalar**. Solo dile el nombre de tu carpeta de trabajo (ejemplo: `CLAUDE CODE`, `Trabajo`, `Projects`). Claude la busca automáticamente y crea todo lo necesario dentro.
7. **Confirma** la ruta que Claude detectó y espera a que termine. Te dirá "Listo" cuando acabe y te mostrará la ruta donde quedó instalado

**Recuerda esa ruta** — es donde pondrás los CSV y donde se guardarán los reportes.

---

## Paso 2 — Preparar los CSV de Meta Ads

Cada vez que quieras generar un reporte, necesitas descargar los datos de Meta Ads Manager.

### 2.1 Descargar los CSV desde Meta Ads Manager

1. Entra a **Meta Ads Manager** (https://adsmanager.facebook.com)
2. Selecciona la cuenta del casino que quieres analizar
3. Ajusta el **rango de fechas** del periodo que quieres analizar (ejemplo: 8 marzo al 22 marzo)
4. Necesitas descargar **mínimo 2 archivos CSV**:

**Archivo 1 — Resumen global (campañas):**
- En la vista de **Campañas**, selecciona todas las campañas
- Haz clic en **Exportar** (icono de flecha hacia abajo o botón "Exportar")
- Selecciona **CSV**
- Guarda el archivo

**Archivo 2 — Detalle por anuncio:**
- Cambia a la vista de **Anuncios** (la pestaña de hasta la derecha)
- Selecciona todos los anuncios
- Haz clic en **Exportar** > **CSV**
- Guarda el archivo

Si tienes varias campañas y quieres exportar los anuncios de cada una por separado, puedes descargar un CSV por campaña (esto da más detalle en el reporte).

### 2.2 Organizar los archivos

Los CSV deben ir en una carpeta dentro de la carpeta del casino. **La carpeta puede tener cualquier nombre** — puedes usar el formato que prefieras. Ejemplos:

```
260323
2026-03-08_2026-03-22
marzo-2026
semana-12
```

**Ruta completa donde debes poner los archivos:**

> **Nota:** `{TU_CARPETA}` es la carpeta donde instalaste la herramienta (la que elegiste en el Paso 1). Si no recuerdas cuál es, escribe `/meta-ads-diagnostic` en Claude Code y él te la mostrará.

| Casino       | Ruta de la carpeta                                                              |
|--------------|---------------------------------------------------------------------------------|
| Betmexico    | `{TU_CARPETA}/projects/meta-ads-diagnostic/analyser/bmx/{nombre-periodo}/`            |
| Bet4 Brasil  | `{TU_CARPETA}/projects/meta-ads-diagnostic/analyser/bet4-br/{nombre-periodo}/`        |
| Bet4 Perú    | `{TU_CARPETA}/projects/meta-ads-diagnostic/analyser/bet4-pe/{nombre-periodo}/`        |
| Aposta       | `{TU_CARPETA}/projects/meta-ads-diagnostic/analyser/aposta/{nombre-periodo}/`         |
| Fazo         | `{TU_CARPETA}/projects/meta-ads-diagnostic/analyser/fazo/{nombre-periodo}/`           |
| Casinito     | `{TU_CARPETA}/projects/meta-ads-diagnostic/analyser/casinito/{nombre-periodo}/`       |

**Cómo llegar a esas carpetas:**
1. Abre **Finder** (Mac) o **Explorador de archivos** (Windows)
2. Presiona **Cmd+Shift+G** (Mac) o escribe en la barra de dirección
3. Escribe la ruta de tu carpeta seguida de `/projects/meta-ads-diagnostic/analyser/`
4. Entra a la carpeta del casino correspondiente
5. Crea una carpeta nueva con el nombre que quieras (ejemplo: `260323`)
6. Mete los CSV dentro de esa carpeta

---

## Paso 3 — Ejecutar el análisis

1. Abre **Claude Code**
2. Escribe exactamente: `/meta-ads-diagnostic`
3. Presiona **Enter**
4. Claude te preguntará **qué casino** quieres analizar. Escribe el número y presiona Enter.
5. Claude te preguntará **qué periodo**. Escribe el número y presiona Enter.
6. **Espera aproximadamente ~2-3 minutos** mientras Claude analiza los datos y genera el reporte.
7. El reporte se **abre automáticamente** en tu navegador.
8. El archivo queda guardado en: `{TU_CARPETA}/projects/meta-ads-diagnostic/output/{casino}/`

---

## Paso 4 — Compartir el reporte

El reporte es un archivo HTML. Para compartirlo:

- **Por correo o Slack:** Adjunta el archivo `.html` que está en la carpeta `output/{casino}/`
- **Cualquier persona** puede abrirlo con Chrome, Safari, Firefox, Edge... no necesita instalar nada
- **Para convertirlo a PDF:** Abre el HTML en Chrome, presiona **Cmd+P** (Mac) o **Ctrl+P** (Windows), y selecciona "Guardar como PDF"

---

## Logos de casino

El reporte incluye automáticamente el logo del casino si está disponible. Los logos se guardan en:

```
{TU_CARPETA}/projects/meta-ads-diagnostic/assets/logos/{casino}/logo.png
```

Abraham se encarga de colocar los logos. Si un casino no tiene logo, el reporte se genera sin él — no es necesario para que funcione.

---

## Preguntas frecuentes / Problemas comunes

### "No me aparece /meta-ads-diagnostic cuando escribo en Claude Code"
La herramienta no está instalada. Repite el **Paso 1** (copiar y pegar el contenido de `INSTALAR.txt`).

### "Claude dice que no encuentra los CSV"
Revisa que:
- La carpeta esté en la ruta correcta (dentro de `analyser/{casino}/`)
- Que hayas creado una subcarpeta para el periodo (puede tener cualquier nombre, ej: `260323`)
- Los archivos CSV estén **dentro** de esa carpeta (no en una subcarpeta)

### "El reporte no se abre automáticamente"
Busca el archivo manualmente:
1. Abre Finder
2. Presiona Cmd+Shift+G
3. Escribe la ruta de tu carpeta seguida de `/projects/meta-ads-diagnostic/output/`
4. Entra a la carpeta del casino
5. Abre el archivo `.html` con Chrome

### "Los datos del reporte se ven raros o con caracteres extraños"
Esto puede pasar si el CSV se guardó con un formato diferente. Asegúrate de exportar como **CSV** desde Meta Ads Manager (no Excel ni otro formato).

---

## Soporte

Si tienes cualquier problema, contacta a **Abraham**. El te ayudará a resolverlo.
