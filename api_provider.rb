#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'yaml'

class APIProvider
  attr_reader :config, :current_key_index

  def initialize(config_file = 'config.yml')
    @config = YAML.load_file(config_file)
    @current_key_index = {}
    @config['groq']['api_keys'].each_with_index { |_, i| @current_key_index["groq_#{i}"] = 0 }
  end

  # Llamada principal que maneja múltiples proveedores
  def call(system_prompt, user_prompt, provider: nil, model: nil, max_retries: nil)
    provider ||= @config['default_provider']
    max_retries ||= @config['settings']['max_retries']

    retries = 0
    last_error = nil

    loop do
      begin
        case provider
        when 'groq'
          return call_groq(system_prompt, user_prompt, model, max_retries - retries)
        when 'claude'
          return call_claude(system_prompt, user_prompt, model)
        when 'openai'
          return call_openai(system_prompt, user_prompt, model)
        else
          raise "Proveedor desconocido: #{provider}"
        end
      rescue => e
        last_error = e
        retries += 1

        if retries < max_retries && @config['settings']['auto_fallback']
          puts "⚠️  Error con #{provider}, intentando fallback..."
          provider = fallback_provider(provider)
          sleep(1)
        else
          puts "❌ Error después de #{retries} intentos: #{e.message}"
          return nil
        end
      end
    end
  end

  # ========================================
  # GROQ API
  # ========================================

  def call_groq(system_prompt, user_prompt, model = nil, max_retries = 3)
    model ||= @config['groq']['models']['default']
    api_key = get_next_groq_key
    uri = URI(@config['groq']['base_url'])
    retries = 0

    loop do
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{api_key}"
      request['Content-Type'] = 'application/json'

      request.body = {
        model: model,
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: user_prompt }
        ],
        temperature: 0.7
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.read_timeout = @config['settings']['timeout']
        http.request(request)
      end

      data = JSON.parse(response.body)

      if data['error']
        error_msg = data['error']['message'] || data['error'].to_s

        # Rate limit: esperar y reintentar
        if error_msg.include?('rate_limit_exceeded') && retries < max_retries
          wait_time = extract_wait_time(error_msg)
          retries += 1
          puts "⏳ Rate limit (Groq #{api_key[0..15]}...). Esperando #{wait_time}s... (#{retries}/#{max_retries})"
          sleep(wait_time)

          # Rotar a siguiente key si hay más
          if @config['settings']['load_balance'] && @config['groq']['api_keys'].size > 1
            api_key = get_next_groq_key
            puts "🔄 Rotando a otra API key de Groq..."
          end
          next
        else
          puts "❌ Error de Groq: #{error_msg}"
          return nil
        end
      end

      return data.dig('choices', 0, 'message', 'content')
    end
  rescue => e
    puts "❌ Error de conexión Groq: #{e.message}"
    nil
  end

  # ========================================
  # CLAUDE API (Anthropic)
  # ========================================

  def call_claude(system_prompt, user_prompt, model = nil)
    model ||= @config['claude']['models']['default']
    api_key = @config['claude']['api_key']

    if api_key == 'YOUR_CLAUDE_API_KEY_HERE'
      puts "⚠️  Claude API key no configurada en config.yml"
      return nil
    end

    uri = URI(@config['claude']['base_url'])

    request = Net::HTTP::Post.new(uri)
    request['x-api-key'] = api_key
    request['anthropic-version'] = '2023-06-01'
    request['Content-Type'] = 'application/json'

    request.body = {
      model: model,
      max_tokens: 4096,
      system: system_prompt,
      messages: [
        { role: 'user', content: user_prompt }
      ]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.read_timeout = @config['settings']['timeout']
      http.request(request)
    end

    data = JSON.parse(response.body)

    if data['error']
      puts "❌ Error de Claude: #{data['error']['message']}"
      return nil
    end

    data.dig('content', 0, 'text')
  rescue => e
    puts "❌ Error de conexión Claude: #{e.message}"
    nil
  end

  # ========================================
  # OPENAI API (futuro)
  # ========================================

  def call_openai(system_prompt, user_prompt, model = nil)
    puts "⚠️  OpenAI API no implementada todavía"
    nil
  end

  # ========================================
  # HELPERS
  # ========================================

  # Rotar entre múltiples keys de Groq para load balancing
  def get_next_groq_key
    keys = @config['groq']['api_keys']
    return keys.first if keys.size == 1 || !@config['settings']['load_balance']

    # Round-robin
    @current_key_index['groq'] ||= 0
    key = keys[@current_key_index['groq']]
    @current_key_index['groq'] = (@current_key_index['groq'] + 1) % keys.size
    key
  end

  # Determinar proveedor de fallback
  def fallback_provider(current)
    providers = ['groq', 'claude', 'openai'].reject { |p| p == current }
    providers.find { |p| provider_available?(p) }
  end

  # Verificar si proveedor está configurado
  def provider_available?(provider)
    case provider
    when 'groq'
      @config['groq']['api_keys'].any?
    when 'claude'
      @config['claude']['api_key'] != 'YOUR_CLAUDE_API_KEY_HERE'
    when 'openai'
      @config['openai']['api_key'] != 'YOUR_OPENAI_API_KEY_HERE'
    else
      false
    end
  end

  # Extraer tiempo de espera del mensaje de rate limit
  def extract_wait_time(error_msg)
    match = error_msg.match(/try again in ([\d.]+)s/)
    match ? match[1].to_f + 1 : 2
  end

  # Obtener info de configuración
  def self.load_config(file = 'config.yml')
    YAML.load_file(file)
  end

  # Stats de uso
  def stats
    {
      provider: @config['default_provider'],
      groq_keys: @config['groq']['api_keys'].size,
      claude_configured: provider_available?('claude'),
      load_balance: @config['settings']['load_balance']
    }
  end
end

# Test si se ejecuta directamente
if __FILE__ == $PROGRAM_NAME
  api = APIProvider.new

  puts "📊 Configuración de APIs:"
  puts JSON.pretty_generate(api.stats)

  puts "\n🧪 Probando Groq API..."
  response = api.call(
    "Eres un asistente útil.",
    "Di 'Hola' en una frase corta.",
    provider: 'groq'
  )

  puts response ? "✅ #{response}" : "❌ Error"
end
