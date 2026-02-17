# 🎓 AI Lesson Planner - Sistema Multi-Agente

Generador de planes de clase completos usando un sistema de 4 agentes de IA especializados, con soporte para documentos (PDFs, texto, imágenes) como contexto base.

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

### API Key de Groq

1. Obtén tu API key gratis en [https://console.groq.com](https://console.groq.com)
2. Configura la variable de entorno:

```bash
# Opción 1: Variable de entorno temporal
export GROQ_API_KEY=tu_key_aqui

# Opción 2: Crear archivo .env (recomendado)
cp .env.example .env
# Edita .env y agrega tu key
```

**Nota:** Nunca subas tu API key a Git. El archivo `.env` está en `.gitignore`.

## 📖 Uso

### Modo CLI

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
