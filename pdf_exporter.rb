#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  require 'prawn'
  require 'prawn/table'
  PDF_AVAILABLE = true
rescue LoadError
  PDF_AVAILABLE = false
  puts "⚠️  Gema 'prawn' no instalada. Exportación PDF no disponible."
  puts "   Instala con: gem install prawn prawn-table"
end

class PDFExporter
  def self.export(plan_dir, output_file = nil)
    unless PDF_AVAILABLE
      puts "❌ No se puede exportar a PDF sin la gema 'prawn'"
      return false
    end

    # Leer archivos del plan
    readme = File.read("#{plan_dir}/README.md") rescue "No disponible"
    contenido = File.read("#{plan_dir}/agente2_contenido.md") rescue "No disponible"
    recursos = File.read("#{plan_dir}/agente3_recursos.md") rescue "No disponible"
    evaluacion = File.read("#{plan_dir}/agente4_evaluacion.md") rescue "No disponible"
    actividades = File.read("#{plan_dir}/agente5_actividades.md") rescue "No disponible"

    # Extraer título del README
    titulo = readme.match(/# (.+)/)&.captures&.first || "Plan de Clase"

    # Nombre del archivo PDF
    output_file ||= "#{plan_dir}/plan_completo.pdf"

    # Generar PDF
    Prawn::Document.generate(output_file, page_size: 'LETTER', margin: 50) do |pdf|
      # PORTADA
      pdf.font_size 28
      pdf.text titulo, align: :center, style: :bold
      pdf.move_down 20

      pdf.font_size 12
      pdf.text "Generado: #{Time.now.strftime('%Y-%m-%d %H:%M')}", align: :center
      pdf.text "Sistema Multi-Agente con IA", align: :center, style: :italic
      pdf.move_down 40

      # Logo o separador
      pdf.stroke do
        pdf.horizontal_rule
      end
      pdf.move_down 30

      # TABLA DE CONTENIDOS
      pdf.font_size 18
      pdf.text "📋 Contenido", style: :bold
      pdf.move_down 15

      pdf.font_size 11
      toc_items = [
        "1. Objetivos de Aprendizaje (Bloom)",
        "2. Conceptos Clave",
        "3. Contenido de la Clase",
        "4. Recursos y Herramientas",
        "5. Evaluaciones con Rúbricas",
        "6. Actividades Interactivas"
      ]
      toc_items.each { |item| pdf.text "• #{item}" }

      pdf.move_down 40

      # NUEVA PÁGINA - CONTENIDO
      pdf.start_new_page

      # OBJETIVOS Y CONCEPTOS (del README)
      pdf.font_size 16
      pdf.text "🎯 Objetivos de Aprendizaje", style: :bold
      pdf.move_down 10

      pdf.font_size 10
      objetivos_section = readme.match(/## 🎯 Objetivos de Aprendizaje(.+?)##/m)
      if objetivos_section
        objetivos_text = objetivos_section[1].strip
        pdf.text objetivos_text
      end
      pdf.move_down 20

      pdf.font_size 16
      pdf.text "📚 Conceptos Clave", style: :bold
      pdf.move_down 10

      pdf.font_size 10
      conceptos_section = readme.match(/## 📚 Conceptos Clave(.+?)##/m)
      if conceptos_section
        conceptos_text = conceptos_section[1].strip
        pdf.text conceptos_text
      end

      pdf.move_down 30

      # CONTENIDO DE LA CLASE
      pdf.start_new_page
      pdf.font_size 16
      pdf.text "📖 Contenido de la Clase", style: :bold
      pdf.move_down 15

      pdf.font_size 10
      # Limpiar markdown básico
      contenido_limpio = clean_markdown(contenido)
      pdf.text contenido_limpio
      pdf.move_down 30

      # RECURSOS
      pdf.start_new_page
      pdf.font_size 16
      pdf.text "🔧 Recursos y Herramientas", style: :bold
      pdf.move_down 15

      pdf.font_size 10
      recursos_limpio = clean_markdown(recursos)
      pdf.text recursos_limpio
      pdf.move_down 30

      # EVALUACIONES
      pdf.start_new_page
      pdf.font_size 16
      pdf.text "📝 Evaluaciones y Rúbricas", style: :bold
      pdf.move_down 15

      pdf.font_size 10
      evaluacion_limpia = clean_markdown(evaluacion)
      pdf.text evaluacion_limpia
      pdf.move_down 30

      # ACTIVIDADES INTERACTIVAS
      if actividades != "No disponible"
        pdf.start_new_page
        pdf.font_size 16
        pdf.text "🎮 Actividades Interactivas", style: :bold
        pdf.move_down 15

        pdf.font_size 10
        actividades_limpias = clean_markdown(actividades)
        pdf.text actividades_limpias
      end

      # FOOTER EN TODAS LAS PÁGINAS
      pdf.number_pages "Página <page> de <total>",
                       at: [pdf.bounds.right - 150, 0],
                       width: 150,
                       align: :right,
                       size: 9

      # Footer con branding
      pdf.repeat(:all) do
        pdf.bounding_box([0, 15], width: pdf.bounds.width, height: 15) do
          pdf.font_size 8
          pdf.text "✨ Generado por AI Lesson Planner | github.com/Fedgutcor/ai-lesson-planner",
                   align: :center,
                   color: "666666"
        end
      end
    end

    puts "✅ PDF exportado: #{output_file}"
    true
  rescue => e
    puts "❌ Error exportando PDF: #{e.message}"
    false
  end

  # Limpiar markdown básico para PDF
  def self.clean_markdown(text)
    text.gsub(/^##\s+(.+)$/, '\1')  # Headers
        .gsub(/\*\*(.+?)\*\*/, '\1')  # Bold
        .gsub(/\*(.+?)\*/, '\1')      # Italic
        .gsub(/`(.+?)`/, '\1')        # Code
        .gsub(/^```.*$\n/, '')        # Code blocks start
        .gsub(/^```$/, '')            # Code blocks end
        .gsub(/^\|(.+)\|$/, '\1')     # Tables (simple)
  end
end

# Si se ejecuta directamente
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Uso: ruby pdf_exporter.rb /ruta/al/plan/directorio [output.pdf]"
    exit 1
  end

  plan_dir = ARGV[0]
  output_file = ARGV[1]

  unless Dir.exist?(plan_dir)
    puts "❌ Directorio no existe: #{plan_dir}"
    exit 1
  end

  PDFExporter.export(plan_dir, output_file)
end
