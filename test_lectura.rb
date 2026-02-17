require_relative 'lesson_planner'

directorio = '/Users/ultragresion/Documents/Prueba de contexto'
puts "🔍 Probando lectura de documentos en: #{directorio}\n\n"

docs = leer_documentos_directorio(directorio)

if docs
  puts "\n📊 RESUMEN DE LECTURA:"
  puts "="*60

  docs.each do |doc|
    puts "\n📄 #{doc[:nombre]} (#{doc[:tipo]})"
    puts "   Caracteres: #{doc[:contenido].length}"
    puts "   Vista previa:"
    puts "   " + doc[:contenido][0..300].gsub("\n", "\n   ")
    puts "   ..."
  end
else
  puts "❌ No se pudieron leer documentos"
end
