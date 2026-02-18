#!/bin/bash

echo "🚀 Iniciando AI Lesson Planner Web UI..."
echo ""
echo "📍 La interfaz estará disponible en:"
echo "   http://localhost:4567"
echo ""
echo "⚠️  Presiona Ctrl+C para detener el servidor"
echo ""

# Asegurar que el config existe
if [ ! -f "config.yml" ]; then
    echo "⚠️  config.yml no existe, copiando desde config.yml.example..."
    cp config.yml.example config.yml
fi

# Iniciar servidor
ruby web_ui.rb
