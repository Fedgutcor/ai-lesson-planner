# Introducción a LangChain

## ¿Qué es LangChain?

LangChain es un framework para desarrollar aplicaciones impulsadas por modelos de lenguaje. Permite:

- **Conectar LLMs** con fuentes de datos externas
- **Crear cadenas** de prompts y acciones
- **Implementar agentes** que toman decisiones
- **Gestionar memoria** para conversaciones contextuales

## Componentes Principales

### 1. LLMs y Chat Models
Interfaces para interactuar con diferentes modelos de lenguaje.

### 2. Prompts
Templates reutilizables para generar prompts consistentes.

### 3. Chains
Secuencias de llamadas a LLMs y otras herramientas.

### 4. Agents
Sistemas que usan LLMs para decidir qué acciones tomar.

### 5. Memory
Sistemas para mantener el contexto entre interacciones.

## Ejemplo Básico

```python
from langchain import OpenAI, LLMChain, PromptTemplate

# Crear template
template = "Explica {concepto} de forma simple"
prompt = PromptTemplate(template=template, input_variables=["concepto"])

# Crear chain
llm = OpenAI(temperature=0.7)
chain = LLMChain(llm=llm, prompt=prompt)

# Ejecutar
resultado = chain.run(concepto="machine learning")
print(resultado)
```

## Casos de Uso

1. Chatbots con contexto
2. Sistemas de Q&A sobre documentos
3. Automatización de tareas con IA
4. Análisis de datos con lenguaje natural
