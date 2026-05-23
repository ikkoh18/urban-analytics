"""
AI service — proxy para Groq (llama-3.1-8b-instant) com cache em memória.

Cache da resposta inicial por hash(contexto + system_prompt):
  - TTL: 1 hora
  - Evita chamar a API a cada clique no mesmo bairro+horário

API Groq: compatível com OpenAI, gratuita, sem restrição regional.
  Docs: https://console.groq.com/docs/openai
"""

import json
import os
import time
import urllib.error
import urllib.request

GROQ_KEY   = os.environ.get('GROQ_API_KEY', '')
_MODEL     = 'llama-3.1-8b-instant'
_GROQ_URL  = 'https://api.groq.com/openai/v1/chat/completions'

# cache: hash -> (timestamp, resposta)
_CACHE: dict[int, tuple[float, str]] = {}
_CACHE_TTL = 3600  # 1 hora


def _call(system: str, messages: list[dict], max_tokens: int = 400) -> str:
    """
    messages: lista de {role: 'user'|'assistant', content: str}
    A API Groq usa roles OpenAI ('assistant', não 'model').
    """
    if not GROQ_KEY:
        raise RuntimeError('GROQ_API_KEY não configurada no servidor')

    payload = {
        'model': _MODEL,
        'messages': [{'role': 'system', 'content': system}, *messages],
        'max_tokens': max_tokens,
        'temperature': 0.7,
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        _GROQ_URL,
        data=data,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {GROQ_KEY}',
            'User-Agent': 'UrbanAnalytics/1.0 (Python/3.11)',
            'Accept': 'application/json',
        },
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            result = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors='replace')
        raise RuntimeError(f'Groq HTTP {e.code}: {body}') from e

    return result['choices'][0]['message']['content']


def get_initial_response(context: str, system: str) -> str:
    """Primeira resposta da IA ao selecionar um bairro. Cacheada por 1 hora."""
    cache_key = hash(context + system)
    now = time.time()
    if cache_key in _CACHE:
        ts, val = _CACHE[cache_key]
        if now - ts < _CACHE_TTL:
            print(f'[ai_service] cache hit hash={cache_key}')
            return val

    result = _call(system, [{'role': 'user', 'content': context}])
    _CACHE[cache_key] = (now, result)
    return result


def get_chat_reply(system: str, messages: list[dict]) -> str:
    """Resposta de chat livre. messages: [{role: 'user'|'assistant', content: str}]"""
    return _call(system, messages)


def get_weather(area: str) -> dict:
    """Clima atual de uma área. Retorna {temp_c, condition, humidity}."""
    prompt = (
        f'What is the current weather in {area}, Los Angeles right now? '
        'Reply in JSON only, no markdown: '
        '{"temp_c": 22, "condition": "Sunny", "humidity": 65}'
    )
    system = 'You are a weather assistant. Reply only with the requested JSON.'
    raw = _call(system, [{'role': 'user', 'content': prompt}], max_tokens=80)
    cleaned = raw.replace('```json', '').replace('```', '').strip()
    return json.loads(cleaned)
