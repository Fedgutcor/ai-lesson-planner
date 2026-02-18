#!/usr/bin/env ruby
# frozen_string_literal: true

class HTMLExporter
  def self.export(plan_dir, output_file = nil)
    # Leer archivos del plan
    readme = File.read("#{plan_dir}/README.md") rescue "No disponible"
    contenido = File.read("#{plan_dir}/agente2_contenido.md") rescue "No disponible"
    recursos = File.read("#{plan_dir}/agente3_recursos.md") rescue "No disponible"
    evaluacion = File.read("#{plan_dir}/agente4_evaluacion.md") rescue "No disponible"
    actividades = File.read("#{plan_dir}/agente5_actividades.md") rescue "No disponible"

    # Extraer información del README
    titulo = readme.match(/# (.+)/)&.captures&.first || "Plan de Clase"
    fecha = readme.match(/\*\*📅 Generado:\*\* (.+)/)&.captures&.first || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    nivel = readme.match(/\*\*📊 Nivel:\*\* (.+)/)&.captures&.first || "No especificado"
    duracion = readme.match(/\*\*⏱️  Duración:\*\* (.+)/)&.captures&.first || "No especificado"
    dificultad = readme.match(/\*\*⭐ Dificultad:\*\* (.+)/)&.captures&.first || "No especificado"

    # Extraer objetivos y conceptos
    objetivos = readme.match(/## 🎯 Objetivos de Aprendizaje(.+?)##/m)&.captures&.first&.strip || "No disponible"
    conceptos = readme.match(/## 📚 Conceptos Clave(.+?)##/m)&.captures&.first&.strip || "No disponible"
    prerequisitos = readme.match(/## ⚠️ Prerequisitos(.+?)---/m)&.captures&.first&.strip || "No disponible"

    # Nombre del archivo HTML
    output_file ||= "#{plan_dir}/plan_completo.html"

    # Generar HTML
    html = <<~HTML
      <!DOCTYPE html>
      <html lang="es">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{titulo}</title>
          <style>
              @media print {
                  @page { margin: 2cm; }
                  body { margin: 0; }
                  .no-print { display: none; }
                  .page-break { page-break-before: always; }
              }

              body {
                  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                  line-height: 1.6;
                  max-width: 900px;
                  margin: 0 auto;
                  padding: 20px;
                  background: #f5f5f5;
              }

              .container {
                  background: white;
                  padding: 40px;
                  border-radius: 10px;
                  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
              }

              .header {
                  text-align: center;
                  border-bottom: 3px solid #4CAF50;
                  padding-bottom: 30px;
                  margin-bottom: 30px;
              }

              h1 {
                  color: #2C3E50;
                  font-size: 32px;
                  margin-bottom: 10px;
              }

              .metadata {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                  gap: 15px;
                  background: #f8f9fa;
                  padding: 20px;
                  border-radius: 8px;
                  margin: 20px 0;
              }

              .metadata-item {
                  font-size: 14px;
              }

              .metadata-item strong {
                  color: #4CAF50;
              }

              h2 {
                  color: #4CAF50;
                  font-size: 24px;
                  margin-top: 40px;
                  padding-bottom: 10px;
                  border-bottom: 2px solid #e0e0e0;
              }

              h3 {
                  color: #34495E;
                  font-size: 18px;
                  margin-top: 25px;
              }

              ul, ol {
                  padding-left: 30px;
              }

              li {
                  margin: 8px 0;
              }

              .bloom-basic { color: #2196F3; }
              .bloom-intermediate { color: #4CAF50; }
              .bloom-advanced { color: #FF9800; }

              table {
                  width: 100%;
                  border-collapse: collapse;
                  margin: 20px 0;
                  font-size: 14px;
              }

              th, td {
                  border: 1px solid #ddd;
                  padding: 12px;
                  text-align: left;
              }

              th {
                  background-color: #4CAF50;
                  color: white;
                  font-weight: bold;
              }

              tr:nth-child(even) {
                  background-color: #f9f9f9;
              }

              .section-box {
                  background: #f8f9fa;
                  padding: 20px;
                  border-left: 4px solid #4CAF50;
                  margin: 20px 0;
                  border-radius: 4px;
              }

              pre {
                  background: #2C3E50;
                  color: #ECF0F1;
                  padding: 15px;
                  border-radius: 5px;
                  overflow-x: auto;
              }

              code {
                  background: #e9ecef;
                  padding: 2px 6px;
                  border-radius: 3px;
                  font-family: 'Courier New', monospace;
              }

              .footer {
                  text-align: center;
                  margin-top: 50px;
                  padding-top: 20px;
                  border-top: 2px solid #e0e0e0;
                  color: #666;
                  font-size: 12px;
              }

              .print-button {
                  background: #4CAF50;
                  color: white;
                  border: none;
                  padding: 15px 30px;
                  font-size: 16px;
                  border-radius: 5px;
                  cursor: pointer;
                  margin: 20px 0;
                  display: block;
                  width: 200px;
                  margin-left: auto;
                  margin-right: auto;
              }

              .print-button:hover {
                  background: #45a049;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <button class="print-button no-print" onclick="window.print()">🖨️ Imprimir / Guardar PDF</button>

              <div class="header">
                  <h1>#{titulo}</h1>
                  <p style="color: #666; font-style: italic;">Sistema Multi-Agente con IA</p>
              </div>

              <div class="metadata">
                  <div class="metadata-item"><strong>📅 Generado:</strong> #{fecha}</div>
                  <div class="metadata-item"><strong>📊 Nivel:</strong> #{nivel}</div>
                  <div class="metadata-item"><strong>⏱️ Duración:</strong> #{duracion}</div>
                  <div class="metadata-item"><strong>⭐ Dificultad:</strong> #{dificultad}</div>
              </div>

              <h2>🎯 Objetivos de Aprendizaje</h2>
              <div class="section-box">
                  #{markdown_to_html(objetivos)}
              </div>

              <h2>📚 Conceptos Clave</h2>
              <div class="section-box">
                  #{markdown_to_html(conceptos)}
              </div>

              <h2>⚠️ Prerequisitos</h2>
              <div class="section-box">
                  #{markdown_to_html(prerequisitos)}
              </div>

              <div class="page-break"></div>

              <h2>📖 Contenido de la Clase</h2>
              #{markdown_to_html(contenido)}

              <div class="page-break"></div>

              <h2>🔧 Recursos y Herramientas</h2>
              #{markdown_to_html(recursos)}

              <div class="page-break"></div>

              <h2>📝 Evaluaciones y Rúbricas</h2>
              #{markdown_to_html(evaluacion)}

              #{if actividades != "No disponible"
                  "<div class='page-break'></div><h2>🎮 Actividades Interactivas</h2>#{markdown_to_html(actividades)}"
                else
                  ""
                end}

              <div class="footer">
                  <p>✨ Generado por AI Lesson Planner</p>
                  <p>Sistema Multi-Agente (5 agentes) con Groq + Llama 3.3</p>
                  <p><a href="https://github.com/Fedgutcor/ai-lesson-planner" target="_blank">github.com/Fedgutcor/ai-lesson-planner</a></p>
              </div>
          </div>
      </body>
      </html>
    HTML

    File.write(output_file, html)
    puts "✅ HTML exportado: #{output_file}"
    puts "💡 Abre el archivo en el navegador y usa Ctrl+P (Cmd+P) para guardar como PDF"
    true
  rescue => e
    puts "❌ Error exportando HTML: #{e.message}"
    false
  end

  # Convertir markdown básico a HTML
  def self.markdown_to_html(text)
    text.gsub(/^### (.+)$/, '<h3>\1</h3>')
        .gsub(/^## (.+)$/, '<h3>\1</h3>')
        .gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
        .gsub(/\*(.+?)\*/, '<em>\1</em>')
        .gsub(/`(.+?)`/, '<code>\1</code>')
        .gsub(/^- (.+)$/, '<li>\1</li>')
        .gsub(/^🔵 (.+)$/, '<li class="bloom-basic">🔵 \1</li>')
        .gsub(/^🟢 (.+)$/, '<li class="bloom-intermediate">🟢 \1</li>')
        .gsub(/^🟠 (.+)$/, '<li class="bloom-advanced">🟠 \1</li>')
        .gsub(/(<li>.*<\/li>)+/m) { |match| "<ul>#{match}</ul>" }
        .gsub(/^\|(.+)\|$/, '<tr><td>\1</td></tr>')
        .gsub(/(<tr>.*<\/tr>)+/m) { |match| "<table>#{match}</table>" }
        .gsub(/\n\n/, '</p><p>')
        .then { |html| "<p>#{html}</p>" }
        .gsub(/<p><\/p>/, '')
        .gsub(/<p>(<h[23]>)/, '\1')
        .gsub(/(<\/h[23]>)<\/p>/, '\1')
        .gsub(/<p>(<ul>)/, '\1')
        .gsub(/(<\/ul>)<\/p>/, '\1')
        .gsub(/<p>(<table>)/, '\1')
        .gsub(/(<\/table>)<\/p>/, '\1')
  end
end

# Si se ejecuta directamente
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Uso: ruby html_exporter.rb /ruta/al/plan/directorio [output.html]"
    exit 1
  end

  plan_dir = ARGV[0]
  output_file = ARGV[1]

  unless Dir.exist?(plan_dir)
    puts "❌ Directorio no existe: #{plan_dir}"
    exit 1
  end

  HTMLExporter.export(plan_dir, output_file)
end
