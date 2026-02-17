#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'base64'

# Intentar cargar pdf-reader (opcional)
begin
  require 'pdf-reader'
  PDF_READER_AVAILABLE = true
  puts "✅ Gema 'pdf-reader' disponible"
rescue LoadError
  PDF_READER_AVAILABLE = false
  puts "ℹ️  Gema 'pdf-reader' no instalada. Usando métodos alternativos para PDFs (PyPDF2/Python)"
end

# ============================================
# CONFIGURACIÓN
# ============================================

GROQ_API_KEY = ENV['GROQ_API_KEY'] || 'YOUR_GROQ_API_KEY_HERE'
GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions'
MODEL = 'llama-3.3-70b-versatile'  # Modelo actualizado
VISION_MODEL = 'meta-llama/llama-4-scout-17b-16e-instruct'  # Modelo para análisis de imágenes

# ============================================
# HELPER: Leer documentos de un directorio
# ============================================

def leer_pdf(archivo)
  nombre = File.basename(archivo)

  # Intentar con pdf-reader primero (gema Ruby)
  if PDF_READER_AVAILABLE
    begin
      reader = PDF::Reader.new(archivo)
      texto = reader.pages.map(&:text).join("\n")
      if texto && texto.strip.length > 100
        puts "   ✓ PDF leído con pdf-reader gem"
        return texto
      end
    rescue => e
      # Continuar con método alternativo
    end
  end

  # Método alternativo 1: Python con PyPDF2/pypdf
  script_dir = File.dirname(__FILE__)
  python_script = File.join(script_dir, 'pdf_to_text.py')

  if File.exist?(python_script)
    begin
      texto = `python3 "#{python_script}" "#{archivo}" 2>/dev/null`
      if $?.exitstatus == 0 && texto && texto.strip.length > 100
        puts "   ✓ PDF leído con PyPDF2 (Python)"
        return texto
      end
    rescue => e
      # Continuar con método alternativo 2
    end
  end

  # Método alternativo 2: pdftotext del sistema
  begin
    texto = `pdftotext "#{archivo}" - 2>/dev/null`
    if $?.exitstatus == 0 && texto && texto.strip.length > 100
      puts "   ✓ PDF leído con pdftotext"
      return texto
    end
  rescue => e
    # Continuar con método alternativo 3
  end

  # Último recurso: extraer texto con strings y filtrar
  begin
    texto = `strings "#{archivo}" 2>/dev/null | grep -E "^[A-Za-z]" | grep -v "^obj$\|^endobj$\|^stream$" | head -500`.force_encoding('UTF-8')
    if texto && texto.strip.length > 100
      resultado = texto.lines.select { |l| l.length > 20 && l.length < 200 }.join("\n")
      puts "   ✓ PDF leído con strings (método básico)"
      return resultado
    end
  rescue => e
    # No method worked
  end

  puts "   ✗ No se pudo extraer texto del PDF #{nombre}"
  nil
end

def analizar_imagen(archivo)
  # Leer y encodear imagen a base64
  imagen_data = File.binread(archivo)
  imagen_base64 = Base64.strict_encode64(imagen_data)

  # Determinar el tipo MIME
  extension = File.extname(archivo).downcase
  mime_type = case extension
              when '.jpg', '.jpeg' then 'image/jpeg'
              when '.png' then 'image/png'
              when '.gif' then 'image/gif'
              when '.webp' then 'image/webp'
              else 'image/jpeg'
              end

  # Llamar a Groq Vision API
  uri = URI(GROQ_API_URL)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{GROQ_API_KEY}"
  request['Content-Type'] = 'application/json'

  request.body = {
    model: VISION_MODEL,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: 'Analiza esta imagen en detalle. Extrae TODO el texto visible, describe gráficos, diagramas, tablas, y cualquier información educativa relevante. Si hay conceptos técnicos o educativos, explícalos. Sé exhaustivo y preciso.'
          },
          {
            type: 'image_url',
            image_url: {
              url: "data:#{mime_type};base64,#{imagen_base64}"
            }
          }
        ]
      }
    ],
    temperature: 0.3,
    max_tokens: 2000
  }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  data = JSON.parse(response.body)

  if data['error']
    puts "⚠️  Error analizando imagen #{File.basename(archivo)}: #{data['error']['message']}"
    return nil
  end

  data.dig('choices', 0, 'message', 'content')
rescue => e
  puts "⚠️  Error procesando imagen #{File.basename(archivo)}: #{e.message}"
  nil
end

def leer_documentos_directorio(directorio)
  return nil unless directorio && Dir.exist?(directorio)

  documentos = []
  extensiones_texto = %w[.txt .md .markdown .rb .py .js .java .cpp .c .h]
  extensiones_imagen = %w[.jpg .jpeg .png .gif .webp]

  Dir.glob("#{directorio}/**/*").each do |archivo|
    next unless File.file?(archivo)

    extension = File.extname(archivo).downcase
    nombre_archivo = File.basename(archivo)
    contenido = nil
    tipo_contenido = extension

    begin
      if extensiones_texto.include?(extension)
        # Leer archivos de texto
        contenido = File.read(archivo)
      elsif extension == '.pdf'
        # Leer PDFs (con métodos alternativos si pdf-reader no está disponible)
        contenido = leer_pdf(archivo)
        next if contenido.nil? || contenido.strip.empty?
      elsif extensiones_imagen.include?(extension)
        # Analizar imágenes con Vision API
        puts "🖼️  Analizando imagen: #{nombre_archivo}..."
        contenido = analizar_imagen(archivo)
        next if contenido.nil? || contenido.strip.empty?
        tipo_contenido = "imagen#{extension}"
      else
        # Extensión no soportada
        next
      end

      documentos << {
        nombre: nombre_archivo,
        contenido: contenido,
        ruta: archivo,
        tipo: tipo_contenido
      }
    rescue => e
      puts "⚠️  No se pudo leer #{nombre_archivo}: #{e.message}"
    end
  end

  if documentos.empty?
    puts "⚠️  No se encontraron documentos legibles en #{directorio}"
    return nil
  end

  puts "📚 #{documentos.size} documento(s) encontrado(s) en #{directorio}"
  documentos.each { |doc| puts "   - #{doc[:nombre]} (#{doc[:tipo]})" }

  documentos
end

def formatear_contexto_documentos(documentos)
  return "" if documentos.nil? || documentos.empty?

  # Ajustar límite según cantidad de documentos para evitar rate limits
  chars_por_doc = case documentos.size
                  when 1 then 4000
                  when 2 then 3000
                  when 3 then 2000
                  else 1500
                  end

  contexto = "\n\n## CONTEXTO ADICIONAL (Documentos Base - #{documentos.size} documento(s)):\n\n"

  documentos.each do |doc|
    contexto += "### Documento: #{doc[:nombre]}\n\n"
    extracto = doc[:contenido][0..chars_por_doc]
    contexto += "```\n#{extracto}\n```\n\n"
    contexto += "(extracto de #{chars_por_doc} caracteres de #{doc[:contenido].length} totales)\n\n" if doc[:contenido].length > chars_por_doc
  end

  puts "ℹ️  Contexto: #{contexto.length} caracteres (~#{(contexto.length / 4).to_i} tokens)"
  contexto
end

# ============================================
# HELPER: Llamar a Groq API
# ============================================

def call_groq(system_prompt, user_prompt, max_retries: 3)
  uri = URI(GROQ_API_URL)
  retries = 0

  loop do
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{GROQ_API_KEY}"
    request['Content-Type'] = 'application/json'

    request.body = {
      model: MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: user_prompt }
      ],
      temperature: 0.7
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    data = JSON.parse(response.body)

    # Manejar errores
    if data['error']
      error_msg = data['error']['message'] || data['error'].to_s

      # Si es rate limit y tenemos retries disponibles
      if error_msg.include?('rate_limit_exceeded') && retries < max_retries
        # Extraer tiempo de espera del mensaje (ej: "Please try again in 22.885s")
        wait_time = error_msg.match(/try again in ([\d.]+)s/)
        sleep_duration = wait_time ? wait_time[1].to_f + 1 : 2

        retries += 1
        puts "⏳ Rate limit alcanzado. Esperando #{sleep_duration.round(1)}s... (reintento #{retries}/#{max_retries})"
        sleep(sleep_duration)
        next
      else
        puts "❌ Error de Groq: #{error_msg}"
        return nil
      end
    end

    return data.dig('choices', 0, 'message', 'content')
  end
rescue => e
  puts "❌ Error de conexión: #{e.message}"
  return nil
end

# ============================================
# AGENTE 1: DISEÑADOR CURRICULAR
# ============================================

def agente_disenador(tema, nivel, contexto_docs = nil)
  puts "\n🎓 AGENTE 1: Diseñador Curricular trabajando..."
  start_time = Time.now

  system_prompt = if contexto_docs
    "Eres un diseñador curricular experto. REGLA CRÍTICA: Debes basarte ESTRICTAMENTE en los documentos proporcionados. NO inventes información, NO agregues conceptos que no estén en los documentos. Si algo no está en los documentos, NO lo incluyas."
  else
    "Eres un diseñador curricular experto en educación sobre IA y tecnología."
  end

  user_prompt = <<~PROMPT
    Analiza el tema: "#{tema}" para nivel "#{nivel}".
    #{contexto_docs}

    #{contexto_docs ? <<~RESTRICCIONES : ""}
    ⚠️ RESTRICCIONES ESTRICTAS:
    - SOLO usa información que aparezca explícitamente en los documentos proporcionados
    - NO inventes conceptos, herramientas o ejemplos que no estén mencionados en los documentos
    - Si un documento menciona una herramienta específica, úsala; si no, NO agregues otras
    - Los objetivos y conceptos clave deben derivarse DIRECTAMENTE del contenido de los documentos
    - Si los documentos no cubren cierto aspecto del tema, NO lo incluyas
    RESTRICCIONES

    Genera SOLO un JSON válido con esta estructura:
    {
      "objetivos_aprendizaje": ["objetivo 1", "objetivo 2", "objetivo 3"],
      "conceptos_clave": ["concepto 1", "concepto 2", "concepto 3"],
      "prerequisitos": ["requisito 1", "requisito 2"],
      "duracion_sugerida": "45 minutos",
      "nivel_dificultad": 3
    }

    Responde ÚNICAMENTE con el JSON, sin texto adicional.
  PROMPT

  resultado = call_groq(system_prompt, user_prompt)
  elapsed = Time.now - start_time

  if resultado.nil?
    puts "❌ Agente 1 falló (#{elapsed.round(2)}s)"
    return {
      "objetivos_aprendizaje" => ["Error: No se pudieron generar objetivos"],
      "conceptos_clave" => ["Error al generar conceptos"],
      "prerequisitos" => ["No disponible"],
      "duracion_sugerida" => "45 minutos",
      "nivel_dificultad" => 3
    }
  end

  puts "✅ Agente 1 completado (#{elapsed.round(2)}s)"

  # Limpiar markdown code blocks si existen
  json_limpio = resultado.strip
  json_limpio = json_limpio.gsub(/^```json\s*\n?/, '').gsub(/\n?```\s*$/, '')

  JSON.parse(json_limpio)
rescue JSON::ParserError => e
  puts "⚠️  Error parseando JSON del Agente 1: #{e.message}"
  puts "⚠️  Respuesta cruda: #{resultado[0..200]}..." if resultado
  { raw: resultado }
end

# ============================================
# AGENTE 2: CREADOR DE CONTENIDO
# ============================================

def agente_contenido(tema, nivel, diseño, contexto_docs = nil)
  puts "\n📝 AGENTE 2: Creador de Contenido trabajando..."
  start_time = Time.now

  system_prompt = if contexto_docs
    "Eres un creador de contenido educativo. REGLA CRÍTICA: Todo el contenido debe provenir EXCLUSIVAMENTE de los documentos proporcionados. NO inventes ejemplos, NO agregues información externa. Si no está en los documentos, NO existe para esta clase."
  else
    "Eres un creador de contenido educativo experto en IA."
  end

  user_prompt = <<~PROMPT
    Tema: "#{tema}" (Nivel: #{nivel})

    Objetivos: #{diseño['objetivos_aprendizaje']}
    Conceptos clave: #{diseño['conceptos_clave']}
    #{contexto_docs}

    #{contexto_docs ? <<~RESTRICCIONES : ""}
    ⚠️ RESTRICCIONES ESTRICTAS - LEE CUIDADOSAMENTE:
    - TODOS los ejemplos deben venir de los documentos proporcionados
    - TODAS las explicaciones deben basarse en lo que dicen los documentos
    - NO inventes casos de uso, herramientas o conceptos que no estén en los documentos
    - Si los documentos mencionan ejemplos específicos, ÚSALOS tal cual
    - Si necesitas un ejemplo y no está en los documentos, OMITE ese ejemplo
    - Cita o parafrasea directamente de los documentos cuando sea posible
    - NO agregues "mejores prácticas" o "recomendaciones" que no estén en los documentos
    RESTRICCIONES

    Crea el CONTENIDO de la clase con:
    1. INTRODUCCIÓN (5 min): Hook, contexto, por qué es importante (basado en los documentos)
    2. DESARROLLO (25 min): Explicación de conceptos con ejemplos de los documentos
    3. PRÁCTICA GUIADA (15 min): 2-3 ejercicios derivados del contenido de los documentos

    Hazlo práctico usando ÚNICAMENTE información de los documentos proporcionados.
  PROMPT

  resultado = call_groq(system_prompt, user_prompt)
  elapsed = Time.now - start_time

  if resultado.nil? || resultado.strip.empty?
    puts "❌ Agente 2 falló (#{elapsed.round(2)}s)"
    return "**Error:** No se pudo generar el contenido de la clase. Por favor, intenta de nuevo."
  end

  puts "✅ Agente 2 completado (#{elapsed.round(2)}s)"
  resultado
end

# ============================================
# AGENTE 3: CURADOR DE RECURSOS
# ============================================

def agente_recursos(tema, nivel, contexto_docs = nil)
  puts "\n🔧 AGENTE 3: Curador de Recursos trabajando..."
  start_time = Time.now

  system_prompt = if contexto_docs
    "Eres un curador de recursos educativos. REGLA CRÍTICA: SOLO recomienda herramientas y recursos que estén explícitamente mencionados en los documentos proporcionados. NO agregues herramientas externas."
  else
    "Eres un curador de recursos educativos sobre IA y tecnología."
  end

  user_prompt = <<~PROMPT
    Tema: "#{tema}" (Nivel: #{nivel})
    #{contexto_docs}

    #{contexto_docs ? <<~RESTRICCIONES : ""}
    ⚠️ RESTRICCIONES ESTRICTAS:
    - SOLO recomienda herramientas que estén mencionadas en los documentos
    - SOLO sugiere recursos que aparezcan en los documentos
    - NO agregues herramientas populares si no están en los documentos
    - Si los documentos no mencionan herramientas, indica que se deben usar las del material base
    - El proyecto hands-on debe basarse en herramientas/conceptos de los documentos
    RESTRICCIONES

    Recomienda:
    1. HERRAMIENTAS: Herramientas mencionadas en los documentos (nombre + para qué sirve según los docs)
    2. RECURSOS: Recursos mencionados en los documentos para profundizar
    3. PROYECTO HANDS-ON: 1 proyecto práctico basado en los conceptos de los documentos

    #{contexto_docs ? "Basa TODO en los documentos proporcionados." : "Sé específico con nombres reales de herramientas y recursos."}
  PROMPT

  resultado = call_groq(system_prompt, user_prompt)
  elapsed = Time.now - start_time

  if resultado.nil? || resultado.strip.empty?
    puts "❌ Agente 3 falló (#{elapsed.round(2)}s)"
    return "**Error:** No se pudieron generar recursos. Por favor, intenta de nuevo."
  end

  puts "✅ Agente 3 completado (#{elapsed.round(2)}s)"
  resultado
end

# ============================================
# AGENTE 4: GENERADOR DE EVALUACIONES
# ============================================

def agente_evaluador(tema, nivel, diseño, contenido, contexto_docs = nil)
  puts "\n📝 AGENTE 4: Generador de Evaluaciones trabajando..."
  start_time = Time.now

  system_prompt = if contexto_docs
    "Eres un experto en evaluaciones educativas. REGLA CRÍTICA: Las preguntas y ejercicios deben basarse EXCLUSIVAMENTE en el contenido de los documentos proporcionados. NO crees preguntas sobre conceptos que no estén en los documentos."
  else
    "Eres un experto en diseño de evaluaciones educativas y assessment."
  end

  user_prompt = <<~PROMPT
    Tema: "#{tema}" (Nivel: #{nivel})

    Objetivos de aprendizaje:
    #{diseño['objetivos_aprendizaje']&.join(', ')}

    Conceptos clave:
    #{diseño['conceptos_clave']&.join(', ')}

    #{contexto_docs}

    #{contexto_docs ? <<~RESTRICCIONES : ""}
    ⚠️ RESTRICCIONES ESTRICTAS PARA EVALUACIÓN:
    - TODAS las preguntas deben evaluar contenido que esté en los documentos
    - NO hagas preguntas sobre conceptos que no fueron cubiertos en los documentos
    - Los ejercicios prácticos deben usar herramientas/técnicas mencionadas en los documentos
    - Los casos de estudio deben basarse en ejemplos de los documentos
    - Las respuestas modelo deben citar o referenciar los documentos
    - Si un concepto no está en los documentos, NO lo evalúes
    RESTRICCIONES

    Crea una EVALUACIÓN COMPLETA Y VARIADA con:

    ## 1. PREGUNTAS DE OPCIÓN MÚLTIPLE (5 preguntas)
    - Cada pregunta con 4 opciones (A, B, C, D)
    - Marca la respuesta correcta con [✓]
    - Incluye una breve explicación de por qué es correcta

    ## 2. PREGUNTAS ABIERTAS (3 preguntas)
    - Preguntas que requieran análisis y pensamiento crítico
    - Incluye una respuesta modelo para el docente
    - Incluye criterios de evaluación (rúbrica simple)

    ## 3. EJERCICIOS PRÁCTICOS (2 ejercicios)
    - Ejercicios hands-on aplicando los conceptos
    - Paso a paso de la solución para el docente
    - Estimación de tiempo de resolución

    ## 4. CASO DE ESTUDIO / PROYECTO MINI (1)
    - Situación realista donde aplicar lo aprendido
    - Preguntas guía para el estudiante
    - Solución propuesta para el docente

    ## 5. PREGUNTAS DE REFLEXIÓN (2 preguntas)
    - Preguntas metacognitivas para que el estudiante reflexione sobre su aprendizaje
    - Ejemplos de respuestas esperadas

    Haz las preguntas INTERACTIVAS, ENGANCHADORAS y RELEVANTES para el nivel #{nivel}.
  PROMPT

  resultado = call_groq(system_prompt, user_prompt)
  elapsed = Time.now - start_time

  if resultado.nil? || resultado.strip.empty?
    puts "❌ Agente 4 falló (#{elapsed.round(2)}s)"
    return "**Error:** No se pudo generar la evaluación. Por favor, intenta de nuevo o reduce la cantidad de documentos de entrada."
  end

  puts "✅ Agente 4 completado (#{elapsed.round(2)}s)"
  resultado
end

# ============================================
# ORQUESTADOR: Coordina los 4 agentes
# ============================================

def generar_plan_clase(tema, nivel, directorio_docs = nil)
  # CREAR DIRECTORIO CON TIMESTAMP
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  tema_slug = tema.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')
  output_dir = "planes/#{tema_slug}_#{timestamp}"
  Dir.mkdir("planes") unless Dir.exist?("planes")
  Dir.mkdir(output_dir)

  puts "\n" + "="*60
  puts "🤖 GENERADOR DE PLANES DE CLASE - SISTEMA MULTI-AGENTE"
  puts "   (4 AGENTES TRABAJANDO EN EQUIPO)"
  puts "="*60
  puts "\n📋 Tema: #{tema}"
  puts "📊 Nivel: #{nivel}"
  puts "📁 Output: #{output_dir}"

  # LEER DOCUMENTOS SI SE PROPORCIONA DIRECTORIO
  documentos = nil
  contexto_docs = nil

  if directorio_docs
    puts "\n📚 Leyendo documentos de: #{directorio_docs}"
    documentos = leer_documentos_directorio(directorio_docs)
    contexto_docs = formatear_contexto_documentos(documentos) if documentos
  end

  # EJECUTAR LOS 4 AGENTES EN SECUENCIA
  diseño = agente_disenador(tema, nivel, contexto_docs)

  # GUARDAR OUTPUT DEL AGENTE 1
  if diseño && !diseño.empty?
    File.write("#{output_dir}/agente1_disenador.json", JSON.pretty_generate(diseño))
    puts "\n📄 Output Agente 1 guardado"
  else
    puts "\n⚠️  Agente 1 no generó contenido válido"
  end

  contenido = agente_contenido(tema, nivel, diseño, contexto_docs)

  # GUARDAR OUTPUT DEL AGENTE 2
  if contenido && contenido.strip.length > 50
    File.write("#{output_dir}/agente2_contenido.md", contenido)
    puts "📄 Output Agente 2 guardado"
  else
    puts "⚠️  Agente 2 no generó contenido válido"
    contenido = "Error: No se pudo generar contenido"
  end

  recursos = agente_recursos(tema, nivel, contexto_docs)

  # GUARDAR OUTPUT DEL AGENTE 3
  if recursos && recursos.strip.length > 50
    File.write("#{output_dir}/agente3_recursos.md", recursos)
    puts "📄 Output Agente 3 guardado"
  else
    puts "⚠️  Agente 3 no generó contenido válido"
    recursos = "Error: No se pudieron generar recursos"
  end

  # AGENTE 4: Generar evaluación basada en todo lo anterior
  evaluacion = agente_evaluador(tema, nivel, diseño, contenido, contexto_docs)

  # GUARDAR OUTPUT DEL AGENTE 4
  if evaluacion && evaluacion.strip.length > 50
    File.write("#{output_dir}/agente4_evaluacion.md", evaluacion)
    puts "📄 Output Agente 4 guardado"
  else
    puts "⚠️  Agente 4 no generó contenido válido - Reintentando..."
    # Reintentar Agente 4 una vez más
    sleep(2)
    evaluacion = agente_evaluador(tema, nivel, diseño, contenido, contexto_docs)
    if evaluacion && evaluacion.strip.length > 50
      File.write("#{output_dir}/agente4_evaluacion.md", evaluacion)
      puts "✅ Agente 4 completado en segundo intento"
    else
      evaluacion = "Error: No se pudo generar la evaluación después de reintentar"
      File.write("#{output_dir}/agente4_evaluacion.md", evaluacion)
      puts "❌ Agente 4 falló después de reintentar"
    end
  end

  # COMPILAR RESULTADO FINAL
  plan = <<~PLAN
    # Plan de Clase: #{tema}

    **Nivel:** #{nivel}
    **Duración:** #{diseño['duracion_sugerida']}
    **Dificultad:** #{diseño['nivel_dificultad']}/5

    ---

    ## 🎯 Objetivos de Aprendizaje

    #{diseño['objetivos_aprendizaje']&.map { |obj| "- #{obj}" }&.join("\n")}

    ## 📚 Conceptos Clave

    #{diseño['conceptos_clave']&.map { |conc| "- #{conc}" }&.join("\n")}

    ## ⚠️ Prerequisitos

    #{diseño['prerequisitos']&.map { |req| "- #{req}" }&.join("\n")}

    ---

    ## 📖 Contenido de la Clase

    #{contenido}

    ---

    ## 🔧 Recursos y Herramientas

    #{recursos}

    ---

    ## 📝 Evaluación

    #{evaluacion}

    ---

    _✨ Generado por Sistema Multi-Agente (4 agentes) con Groq + Llama 3.3_
  PLAN

  # GUARDAR PLAN COMPLETO
  File.write("#{output_dir}/plan_completo.md", plan)

  # GENERAR README CON RESUMEN EJECUTIVO
  readme = <<~README
# Plan de Clase: #{tema}

**📅 Generado:** #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
**📊 Nivel:** #{nivel}
**⏱️  Duración:** #{diseño['duracion_sugerida']}
**⭐ Dificultad:** #{diseño['nivel_dificultad']}/5
#{documentos ? "**📚 Documentos base:** #{documentos.size} archivo(s)" : ""}

---

## 🎯 Objetivos de Aprendizaje

#{diseño['objetivos_aprendizaje']&.map { |obj| "- #{obj}" }&.join("\n")}

## 📚 Conceptos Clave

#{diseño['conceptos_clave']&.map { |conc| "- #{conc}" }&.join("\n")}

## ⚠️ Prerequisitos

#{diseño['prerequisitos']&.map { |req| "- #{req}" }&.join("\n")}

---

## 📁 Archivos Generados

| Archivo | Descripción | Agente Responsable |
|---------|-------------|-------------------|
| `plan_completo.md` | Plan de clase completo | Todos los agentes |
| `agente1_disenador.json` | Diseño curricular (objetivos, conceptos, duración) | Agente 1: Diseñador Curricular |
| `agente2_contenido.md` | Contenido de la clase (intro, desarrollo, práctica) | Agente 2: Creador de Contenido |
| `agente3_recursos.md` | Herramientas y recursos recomendados | Agente 3: Curador de Recursos |
| `agente4_evaluacion.md` | Test y evaluaciones completas | Agente 4: Generador de Evaluaciones |

---

## 💡 Cómo Usar Este Plan

1. **Lee primero:** `plan_completo.md` para tener la visión general
2. **Explora por agente:** Revisa cada archivo individual para ver el trabajo específico
3. **Personaliza:** Modifica según las necesidades de tu clase
4. **Imparte la clase:** Usa el contenido estructurado
5. **Evalúa:** Aplica el test del Agente 4

---

## 🤖 Sistema Multi-Agente

Este plan fue generado por un sistema de 4 agentes de IA trabajando en equipo:

- **Agente 1:** Analiza el tema y diseña la estructura curricular
- **Agente 2:** Crea el contenido educativo con ejemplos prácticos
- **Agente 3:** Recomienda herramientas y recursos específicos
- **Agente 4:** Genera evaluaciones variadas e interactivas

Cada agente se especializa en su área y pasa información al siguiente.

---

## 📞 Feedback

¿Mejoras? ¿Sugerencias? Este sistema es escalable y personalizable.

---

_✨ Generado por Sistema Multi-Agente con Groq + Llama 3.3_
  README

  File.write("#{output_dir}/README.md", readme)

  puts "\n" + "="*60
  puts "✅ PLAN DE CLASE GENERADO"
  puts "="*60
  puts "\n📁 Directorio: #{output_dir}"
  puts "\n📄 Archivos generados:"
  puts "   - README.md                     ⭐ Resumen ejecutivo"
  puts "   - plan_completo.md              (Plan completo)"
  puts "   - agente1_disenador.json        (Diseño curricular)"
  puts "   - agente2_contenido.md          (Contenido de clase)"
  puts "   - agente3_recursos.md           (Herramientas y recursos)"
  puts "   - agente4_evaluacion.md         (Test y evaluaciones)"
  puts "\n💡 Abre #{output_dir}/README.md para empezar"

  { plan: plan, output_dir: output_dir, diseño: diseño }
end

# ============================================
# EJECUTAR
# ============================================

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    # MODO INTERACTIVO
    puts "\n" + "="*60
    puts "🎓 GENERADOR DE PLANES DE CLASE - MODO INTERACTIVO"
    puts "="*60
    puts "\n"

    print "📋 ¿Sobre qué tema quieres crear el plan de clase?\n   Tema: "
    tema = gets.chomp

    puts "\n📊 ¿Para qué nivel?"
    puts "   1) Principiante"
    puts "   2) Intermedio"
    puts "   3) Avanzado"
    print "   Selecciona (1-3): "
    nivel_opcion = gets.chomp

    nivel = case nivel_opcion
            when "1" then "Principiante"
            when "2" then "Intermedio"
            when "3" then "Avanzado"
            else "Intermedio"
            end

    puts "\n📚 ¿Tienes documentos base para usar como contexto?"
    puts "   (Deja vacío si no, o proporciona la ruta del directorio)"
    print "   Directorio: "
    dir_docs = gets.chomp
    dir_docs = nil if dir_docs.empty?

    puts "\n🚀 Generando plan de clase sobre '#{tema}' (Nivel: #{nivel})...\n"

    generar_plan_clase(tema, nivel, dir_docs)
  else
    # MODO CLI (mantener compatibilidad)
    tema = ARGV[0]
    nivel = ARGV[1] || "Intermedio"
    dir_docs = ARGV[2]  # Directorio de documentos opcional

    generar_plan_clase(tema, nivel, dir_docs)
  end
end
