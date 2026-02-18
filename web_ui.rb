#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'
require_relative 'lesson_planner'
require_relative 'api_provider'

# Configuración
set :port, 4567
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/public'

# Variables globales
$current_generation = nil
$generation_progress = []

# ========================================
# RUTAS
# ========================================

# Página principal
get '/' do
  erb :index
end

# API: Obtener configuración
get '/api/config' do
  config = APIProvider.load_config
  json({
    providers: {
      groq: {
        keys_count: config['groq']['api_keys'].size,
        model: config['groq']['models']['default']
      },
      claude: {
        configured: config['claude']['api_key'] != 'YOUR_CLAUDE_API_KEY_HERE',
        model: config['claude']['models']['default']
      }
    },
    default_provider: config['default_provider'],
    settings: config['settings']
  })
end

# API: Generar plan
post '/api/generate' do
  content_type :json

  data = JSON.parse(request.body.read)

  tema = data['tema']
  nivel = data['nivel']
  directorio_docs = data['directorio_docs']
  provider = data['provider']

  # Validar
  if tema.nil? || tema.strip.empty?
    status 400
    return json({ error: 'Tema es requerido' })
  end

  # Resetear progreso
  $generation_progress = []
  $current_generation = {
    status: 'running',
    tema: tema,
    nivel: nivel,
    started_at: Time.now
  }

  # Generar en thread separado
  Thread.new do
    begin
      # Aquí iría la integración con lesson_planner
      # Por ahora simulamos
      add_progress("🚀 Iniciando generación...")
      sleep(1)

      add_progress("📚 Leyendo documentos...")
      sleep(1)

      add_progress("🎓 Agente 1: Diseñador Curricular...")
      sleep(2)

      add_progress("📝 Agente 2: Creador de Contenido...")
      sleep(2)

      add_progress("🔧 Agente 3: Curador de Recursos...")
      sleep(2)

      add_progress("📊 Agente 4: Evaluaciones...")
      sleep(2)

      add_progress("🎮 Agente 5: Actividades Interactivas...")
      sleep(2)

      add_progress("📄 Exportando HTML/PDF...")
      sleep(1)

      add_progress("✅ ¡Completado!")

      $current_generation[:status] = 'completed'
      $current_generation[:output_dir] = "planes/test_#{Time.now.to_i}"

    rescue => e
      add_progress("❌ Error: #{e.message}")
      $current_generation[:status] = 'error'
      $current_generation[:error] = e.message
    end
  end

  json({
    success: true,
    message: 'Generación iniciada',
    generation_id: Time.now.to_i
  })
end

# API: Obtener progreso
get '/api/progress' do
  json({
    status: $current_generation&.dig(:status) || 'idle',
    progress: $generation_progress,
    generation: $current_generation
  })
end

# API: Listar planes generados
get '/api/plans' do
  plans = []

  if Dir.exist?('planes')
    Dir.glob('planes/*').sort_by { |f| File.mtime(f) }.reverse.each do |dir|
      next unless File.directory?(dir)

      readme_path = "#{dir}/README.md"
      next unless File.exist?(readme_path)

      readme = File.read(readme_path)
      titulo = readme.match(/# (.+)/)&.captures&.first
      fecha = readme.match(/\*\*📅 Generado:\*\* (.+)/)&.captures&.first

      plans << {
        dir: File.basename(dir),
        titulo: titulo,
        fecha: fecha,
        archivos: Dir.glob("#{dir}/*").map { |f| File.basename(f) }
      }
    end
  end

  json({ plans: plans })
end

# API: Ver plan
get '/api/plans/:dir' do
  dir = params[:dir]
  plan_path = "planes/#{dir}"

  unless Dir.exist?(plan_path)
    status 404
    return json({ error: 'Plan no encontrado' })
  end

  archivos = {}

  Dir.glob("#{plan_path}/*.{md,json,html}").each do |file|
    nombre = File.basename(file)
    archivos[nombre] = File.read(file)
  end

  json({
    dir: dir,
    archivos: archivos
  })
end

# ========================================
# HELPERS
# ========================================

def add_progress(message)
  $generation_progress << {
    timestamp: Time.now,
    message: message
  }
end

# ========================================
# VIEWS
# ========================================

__END__

@@layout
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Lesson Planner - Web UI</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            text-align: center;
        }

        .header h1 {
            color: #667eea;
            font-size: 36px;
            margin-bottom: 10px;
        }

        .header p {
            color: #666;
            font-size: 16px;
        }

        .card {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }

        input[type="text"],
        select,
        textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }

        input[type="text"]:focus,
        select:focus,
        textarea:focus {
            outline: none;
            border-color: #667eea;
        }

        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 40px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            width: 100%;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }

        .btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }

        .progress-container {
            display: none;
            margin-top: 20px;
        }

        .progress-container.active {
            display: block;
        }

        .progress-log {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 8px;
            max-height: 400px;
            overflow-y: auto;
            font-family: 'Courier New', monospace;
            font-size: 14px;
        }

        .progress-log .log-entry {
            margin-bottom: 8px;
            padding: 5px;
            background: white;
            border-radius: 4px;
        }

        .progress-log .log-entry .timestamp {
            color: #999;
            font-size: 12px;
        }

        .provider-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-left: 10px;
        }

        .provider-badge.groq {
            background: #e3f2fd;
            color: #1976d2;
        }

        .provider-badge.claude {
            background: #f3e5f5;
            color: #7b1fa2;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }

        .stat-card .number {
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
        }

        .stat-card .label {
            color: #666;
            margin-top: 8px;
        }

        .plans-list {
            list-style: none;
        }

        .plan-item {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 10px;
            cursor: pointer;
            transition: transform 0.2s;
        }

        .plan-item:hover {
            transform: translateX(5px);
            background: #f0f0f0;
        }

        .plan-item h3 {
            color: #333;
            margin-bottom: 5px;
        }

        .plan-item .meta {
            color: #999;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎓 AI Lesson Planner</h1>
            <p>Sistema Multi-Agente para Generación de Planes de Clase</p>
        </div>

        <%= yield %>
    </div>

    <script>
        // JavaScript para interactividad
        <%= yield_content :scripts %>
    </script>
</body>
</html>

@@index
<div class="card">
    <h2 style="margin-bottom: 20px; color: #333;">✨ Generar Nuevo Plan</h2>

    <form id="generateForm">
        <div class="form-group">
            <label for="tema">📋 Tema del Plan de Clase *</label>
            <input type="text" id="tema" name="tema" placeholder="Ej: Prompt Engineering Avanzado" required>
        </div>

        <div class="form-group">
            <label for="nivel">📊 Nivel *</label>
            <select id="nivel" name="nivel" required>
                <option value="Principiante">Principiante</option>
                <option value="Intermedio" selected>Intermedio</option>
                <option value="Avanzado">Avanzado</option>
            </select>
        </div>

        <div class="form-group">
            <label for="directorio">📁 Directorio de Documentos (opcional)</label>
            <input type="text" id="directorio" name="directorio" placeholder="/ruta/a/documentos">
            <small style="color: #999;">Deja vacío para generar sin documentos base</small>
        </div>

        <div class="form-group">
            <label for="provider">🤖 Proveedor de IA</label>
            <select id="provider" name="provider">
                <option value="groq">Groq (Llama 3.3) - 2 API Keys</option>
                <option value="claude">Claude (Anthropic)</option>
            </select>
        </div>

        <button type="submit" class="btn" id="generateBtn">
            🚀 Generar Plan de Clase
        </button>
    </form>

    <div class="progress-container" id="progressContainer">
        <h3 style="margin-top: 20px; margin-bottom: 10px;">📊 Progreso</h3>
        <div class="progress-log" id="progressLog"></div>
    </div>
</div>

<div class="card">
    <h2 style="margin-bottom: 20px; color: #333;">📚 Planes Generados Recientemente</h2>
    <ul class="plans-list" id="plansList">
        <li style="color: #999; text-align: center; padding: 20px;">Cargando...</li>
    </ul>
</div>

<% content_for :scripts do %>
<script>
    const form = document.getElementById('generateForm');
    const progressContainer = document.getElementById('progressContainer');
    const progressLog = document.getElementById('progressLog');
    const generateBtn = document.getElementById('generateBtn');
    const plansList = document.getElementById('plansList');

    let progressInterval;

    // Submit form
    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const data = {
            tema: document.getElementById('tema').value,
            nivel: document.getElementById('nivel').value,
            directorio_docs: document.getElementById('directorio').value || null,
            provider: document.getElementById('provider').value
        };

        generateBtn.disabled = true;
        generateBtn.textContent = '⏳ Generando...';
        progressContainer.classList.add('active');
        progressLog.innerHTML = '';

        try {
            const response = await fetch('/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.success) {
                // Poll progress
                progressInterval = setInterval(checkProgress, 1000);
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Error al generar plan');
            generateBtn.disabled = false;
            generateBtn.textContent = '🚀 Generar Plan de Clase';
        }
    });

    // Check progress
    async function checkProgress() {
        try {
            const response = await fetch('/api/progress');
            const data = await response.json();

            // Update log
            progressLog.innerHTML = '';
            data.progress.forEach(entry => {
                const div = document.createElement('div');
                div.className = 'log-entry';
                div.innerHTML = `
                    <span class="timestamp">${new Date(entry.timestamp).toLocaleTimeString()}</span>
                    <span>${entry.message}</span>
                `;
                progressLog.appendChild(div);
            });

            progressLog.scrollTop = progressLog.scrollHeight;

            // Check if completed
            if (data.status === 'completed' || data.status === 'error') {
                clearInterval(progressInterval);
                generateBtn.disabled = false;
                generateBtn.textContent = '🚀 Generar Plan de Clase';

                if (data.status === 'completed') {
                    setTimeout(() => {
                        loadPlans();
                        alert('✅ ¡Plan generado exitosamente!');
                    }, 1000);
                }
            }
        } catch (error) {
            console.error('Error checking progress:', error);
        }
    }

    // Load plans
    async function loadPlans() {
        try {
            const response = await fetch('/api/plans');
            const data = await response.json();

            plansList.innerHTML = '';

            if (data.plans.length === 0) {
                plansList.innerHTML = '<li style="color: #999; text-align: center; padding: 20px;">No hay planes generados todavía</li>';
                return;
            }

            data.plans.forEach(plan => {
                const li = document.createElement('li');
                li.className = 'plan-item';
                li.innerHTML = `
                    <h3>${plan.titulo || plan.dir}</h3>
                    <div class="meta">
                        📅 ${plan.fecha || 'Sin fecha'} |
                        📁 ${plan.archivos.length} archivos
                    </div>
                `;
                li.onclick = () => window.open(\`planes/\${plan.dir}/plan_completo.html\`, '_blank');
                plansList.appendChild(li);
            });
        } catch (error) {
            console.error('Error loading plans:', error);
        }
    }

    // Load plans on page load
    loadPlans();
</script>
<% end %>
