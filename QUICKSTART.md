# 🚀 Guía de Inicio Rápido - AI Lesson Planner v2.0

## ⚡ 3 Pasos para Empezar

### 1️⃣ Configurar APIs

```bash
# Copiar configuración
cp config.yml.example config.yml

# Editar y agregar tus API keys
nano config.yml  # o usa tu editor favorito
```

**Ya tienes 2 keys de Groq configuradas por defecto!** ✅

### 2️⃣ Instalar Dependencias

```bash
# Python para PDFs
pip3 install PyPDF2

# Ruby Gems (si no están)
gem install sinatra:2.2.0 --user-install
```

### 3️⃣ Iniciar Web UI

```bash
./start_ui.sh
```

Abre tu navegador en: **http://localhost:4567**

---

## 🎯 Uso Básico

### Opción A: Web UI (Más Fácil)

1. Abre http://localhost:4567
2. Llena el formulario:
   - **Tema:** "RAG para Product Managers"
   - **Nivel:** Intermedio
   - **Documentos:** (opcional) `/ruta/a/docs`
3. Click en "🚀 Generar Plan"
4. Espera 20-40 segundos
5. ¡Listo! Descarga el HTML/PDF

### Opción B: CLI (Más Rápido)

```bash
ruby lesson_planner.rb "RAG para PMs" "Intermedio" "/Users/tu/Documents/contexto"
```

---

## 📊 Lo Que Obtendrás

**7 archivos generados:**

| Archivo | Descripción |
|---------|-------------|
| `README.md` | Resumen ejecutivo |
| `plan_completo.md` | Plan completo en Markdown |
| `plan_completo.html` | Plan en HTML (imprimible a PDF) |
| `agente1_disenador.json` | Objetivos + Bloom |
| `agente2_contenido.md` | Contenido de la clase |
| `agente3_recursos.md` | Recursos y herramientas |
| `agente4_evaluacion.md` | Evaluaciones + Rúbricas |
| `agente5_actividades.md` | Actividades interactivas |

---

## 🎓 Características Principales

### Taxonomía de Bloom
Objetivos clasificados por nivel cognitivo:
- 🔵 Recordar/Comprender (Fundamentos)
- 🟢 Aplicar/Analizar (Intermedio)
- 🟠 Evaluar/Crear (Avanzado)

### Rúbricas Detalladas
Evaluaciones con 4 niveles:
- ⭐⭐⭐⭐ Excelente (4 pts)
- ⭐⭐⭐ Bueno (3 pts)
- ⭐⭐ Suficiente (2 pts)
- ⭐ Insuficiente (1 pt)

### Actividades Interactivas (Agente 5)
- Quiz y ejercicios digitales
- Dinámicas de grupo
- Breakout rooms
- Gamificación
- Timeline clase por clase

---

## 🤖 Multi-API Support

### Load Balancing Automático
Con 2+ API keys de Groq, el sistema rota automáticamente:
```
Request 1 → Key 1
Request 2 → Key 2
Request 3 → Key 1  (ciclo)
```

### Fallback Inteligente
Si un proveedor falla, cambia automáticamente:
```
Groq (falla) → Claude (funciona) ✅
```

### Elegir Proveedor
En Web UI: selector dropdown
En CLI: edita `config.yml`

---

## 📁 Estructura de Directorios

```
ai-lesson-planner/
├── lesson_planner.rb       # Script principal
├── web_ui.rb               # Interfaz web
├── api_provider.rb         # Multi-API abstraction
├── html_exporter.rb        # Exportador HTML/PDF
├── config.yml              # Tu configuración (gitignored)
├── config.yml.example      # Template de configuración
├── start_ui.sh             # Script de inicio
└── planes/                 # Planes generados
    └── tema_timestamp/
        ├── README.md
        ├── plan_completo.html
        └── ...
```

---

## 🆘 Troubleshooting

### "Rate limit exceeded"
✅ **Solución:** Tienes 2 keys configuradas, el sistema rota automáticamente

### "Invalid API Key"
❌ **Problema:** Key mal configurada
✅ **Solución:** Verifica `config.yml`

### "Port 4567 already in use"
❌ **Problema:** Otro proceso usando el puerto
✅ **Solución:**
```bash
# Encontrar proceso
lsof -i :4567

# Matar proceso
kill -9 <PID>
```

### PDFs no se leen
✅ **Solución:**
```bash
pip3 install PyPDF2
```

---

## 🎯 Próximos Pasos

1. **Genera tu primer plan** con la Web UI
2. **Prueba con documentos** (PDFs + imágenes)
3. **Experimenta con Claude** (mayor calidad)
4. **Comparte planes** en HTML/PDF
5. **Revisa** `PLAN_ESTRATEGICO.md` para ver el roadmap

---

## 💡 Tips Pro

- **Usa múltiples keys** para evitar rate limits
- **Claude para calidad**, Groq para velocidad
- **Documentos bien estructurados** = mejores planes
- **Imágenes con texto** se analizan automáticamente
- **HTML → PDF** con Cmd+P en el navegador

---

**¿Dudas?** Revisa `README.md` o `PLAN_ESTRATEGICO.md`

**¡Feliz generación de planes!** 🎓✨
