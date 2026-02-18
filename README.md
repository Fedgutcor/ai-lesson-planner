# 🎓 AI Lesson Planner - Sistema Multi-Agente

Generador de planes de clase completos usando un sistema de 5 agentes de IA especializados, con soporte para documentos (PDFs, texto, imágenes) como contexto base.

## 🆕 Nuevas Características (v2.0)

- ✨ **Web UI Interactiva** - Interfaz web intuitiva con Sinatra
- 🤖 **Multi-API Support** - Groq, Claude, OpenAI (futuro)
- ⚖️ **Load Balancing** - Rotación automática entre múltiples API keys
- 📊 **Taxonomía de Bloom** - Objetivos clasificados por nivel cognitivo
- 📝 **Rúbricas Detalladas** - Evaluaciones con 4 niveles de desempeño
- 🎮 **Agente 5** - Diseñador de actividades interactivas
- 📄 **Export HTML/PDF** - Planes en formato profesional compartible

## ✨ Características

- 🤖 **Sistema Multi-Agente**: 4 agentes especializados trabajando en equipo
- 📄 **Soporte de Documentos**: PDFs, Markdown, archivos de texto, código
- 🖼️ **Análisis de Imágenes**: Extrae texto y conceptos de imágenes usando Vision AI
- 🎯 **Curación Estricta**: Los agentes solo usan contenido de los documentos proporcionados
- 🔄 **Auto-Retry**: Manejo inteligente de rate limits con reintentos automáticos
- 📊 **Múltiples Outputs**: Genera README, plan completo, y archivos por agente

## 🤖 Los 4 Agentes

1. **Agente 1: Diseñador Curricular**
   - Analiza el tema y diseña la estructura curricular
   - Define objetivos, conceptos clave, duración y prerequisitos

2. **Agente 2: Creador de Contenido**
   - Crea el contenido educativo con ejemplos prácticos
   - Estructura: Introducción, Desarrollo, Práctica Guiada

3. **Agente 3: Curador de Recursos**
   - Recomienda herramientas y recursos específicos
   - Propone proyectos hands-on basados en los documentos

4. **Agente 4: Generador de Evaluaciones**
   - Crea evaluaciones completas y variadas
   - Incluye: Opción múltiple, preguntas abiertas, ejercicios prácticos, casos de estudio

## 🚀 Instalación

### Prerequisitos

```bash
# Ruby 2.6+ (ya instalado en tu sistema)
ruby --version

# Python 3 con PyPDF2 para leer PDFs
pip3 install PyPDF2
```

### Configuración de APIs

**Archivo:** `config.yml`

```bash
# 1. Copiar ejemplo
cp config.yml.example config.yml

# 2. Editar config.yml y agregar tus API keys
```

**Proveedores soportados:**

1. **Groq** (Recomendado - Rápido y Gratuito)
   - Obtén keys en: https://console.groq.com
   - Soporta múltiples keys para load balancing
   - Modelo: Llama 3.3 70B

2. **Claude (Anthropic)**
   - Obtén key en: https://console.anthropic.com
   - Modelo: Claude Sonnet 4.5
   - Mayor calidad, más costoso

3. **OpenAI** (Próximamente)
   - GPT-4 Turbo

**Ejemplo config.yml:**

```yaml
default_provider: groq

groq:
  api_keys:
    - gsk_key1_here
    - gsk_key2_here  # Opcional: para load balancing

claude:
  api_key: sk-ant-key_here

settings:
  auto_fallback: true      # Cambiar a otro proveedor si uno falla
  load_balance: true       # Rotar entre múltiples keys
```

**Nota:** `config.yml` está en `.gitignore` para proteger tus keys.

## 📖 Uso

### 🌐 Web UI (Recomendado)

**Inicio rápido:**

```bash
./start_ui.sh
```

Luego abre tu navegador en: **http://localhost:4567**

**Características de la Web UI:**
- ✨ Interfaz visual intuitiva
- 📊 Progreso en tiempo real
- 📁 Explorador de planes generados
- 🎨 Diseño moderno y responsive
- 🚀 Un solo clic para generar

---

### 💻 Modo CLI (Avanzado)

```bash
ruby lesson_planner.rb "Tema" "Nivel" "/ruta/al/directorio/de/documentos"
```

**Ejemplos:**

```bash
# Sin documentos de contexto
ruby lesson_planner.rb "Introducción a RAG" "Principiante"

# Con directorio de documentos
ruby lesson_planner.rb "IA y Periodismo" "Intermedio" "/Users/tu_usuario/Documents/Contexto"
```

### Niveles disponibles
- `Principiante`
- `Intermedio`
- `Avanzado`

## 📂 Estructura de Output

Cada ejecución genera un directorio con timestamp:

```
planes/
└── tema_20260217_161332/
    ├── README.md                  # Resumen ejecutivo ⭐
    ├── plan_completo.md          # Plan de clase completo
    ├── agente1_disenador.json    # Diseño curricular
    ├── agente2_contenido.md      # Contenido de la clase
    ├── agente3_recursos.md       # Herramientas y recursos
    └── agente4_evaluacion.md     # Test y evaluaciones
```

## 📚 Documentos Soportados

### Formatos de Texto
- `.md`, `.markdown` - Markdown
- `.txt` - Texto plano
- `.rb`, `.py`, `.js`, `.java`, `.cpp`, `.c`, `.h` - Código fuente

### PDFs
- Usa PyPDF2 (Python) para extracción de texto
- Soporte para múltiples páginas
- Fallback a `pdftotext` si está disponible

### Imágenes
- `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`
- Análisis con Vision AI (Llama 4 Scout)
- Extrae texto, describe diagramas y conceptos

## 🎯 Curación Estricta

Cuando proporcionas documentos, los agentes:

✅ **SOLO** usan información de los documentos
✅ **Citan** las fuentes explícitamente
✅ **NO inventan** ejemplos, herramientas o conceptos
❌ **NO agregan** información externa

## ⚙️ Configuración Avanzada

### Ajustar contexto por documento

En `formatear_contexto_documentos()`:
```ruby
chars_por_doc = case documentos.size
                when 1 then 4000
                when 2 then 3000
                when 3 then 2000
                else 1500
                end
```

### Cambiar modelo de IA

```ruby
MODEL = 'llama-3.3-70b-versatile'        # Modelo principal
VISION_MODEL = 'meta-llama/llama-4-scout-17b-16e-instruct'  # Para imágenes
```

## 🔧 Troubleshooting

### PDFs no se leen

1. Verifica que PyPDF2 esté instalado:
   ```bash
   pip3 install PyPDF2
   ```

2. Verifica que `pdf_to_text.py` existe en el directorio del proyecto

### Rate Limit de Groq

- **Límite por minuto**: 12,000 tokens
- **Límite diario**: 100,000 tokens
- El sistema espera automáticamente y reintenta
- Reduce documentos si alcanzas el límite frecuentemente

### Agente 4 falla frecuentemente

El Agente 4 (evaluaciones) es el que más contexto necesita. Soluciones:

1. Reduce el número de documentos
2. Usa documentos más cortos
3. Espera unos segundos entre ejecuciones

## 🛠️ Archivos del Proyecto

- `lesson_planner.rb` - Script principal con los 4 agentes
- `pdf_to_text.py` - Helper para extraer texto de PDFs
- `test_lectura.rb` - Script de prueba para verificar lectura de documentos

## 📄 Licencia

Este proyecto es de código abierto. Úsalo libremente para crear contenido educativo.

## 🤝 Contribuciones

Mejoras, sugerencias y contribuciones son bienvenidas.

---

**✨ Generado con Groq + Llama 3.3**
