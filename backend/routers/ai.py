import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services import ai_service

router = APIRouter(prefix='/ai', tags=['ai'])


@router.get('/debug')
def debug():
    """Diagnóstico: verifica chave e testa chamada real ao Groq."""
    key = os.environ.get('GROQ_API_KEY', '')
    module_key = ai_service.GROQ_KEY
    info = {
        'env_key_set': bool(key),
        'env_key_preview': key[:8] + '...' if key else '(vazio)',
        'module_key_set': bool(module_key),
        'module_key_preview': module_key[:8] + '...' if module_key else '(vazio)',
        'groq_test': None,
        'groq_error': None,
    }
    try:
        reply = ai_service.get_initial_response('Say: OK', 'Reply with just the word OK.')
        info['groq_test'] = reply[:100]
    except Exception as e:
        info['groq_error'] = str(e)
    return info


class ChatRequest(BaseModel):
    context: str
    system: str
    history: list[dict] = []   # [{role: str, content: str}]
    is_initial: bool = False


class WeatherRequest(BaseModel):
    area: str


@router.post('/chat')
def chat(req: ChatRequest):
    if not ai_service.GROQ_KEY:
        raise HTTPException(
            status_code=503,
            detail='GROQ_API_KEY não configurada no servidor',
        )
    try:
        if req.is_initial:
            reply = ai_service.get_initial_response(req.context, req.system)
        else:
            # Contexto como primeira mensagem de usuário + histórico completo
            # Groq usa roles OpenAI: 'user' e 'assistant' (não 'model')
            messages = [
                {'role': 'user', 'content': req.context},
                *[
                    {'role': m['role'], 'content': m['content']}
                    for m in req.history
                ],
            ]
            reply = ai_service.get_chat_reply(req.system, messages)
        return {'reply': reply}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post('/weather')
def weather(req: WeatherRequest):
    if not ai_service.GROQ_KEY:
        raise HTTPException(
            status_code=503,
            detail='GROQ_API_KEY não configurada no servidor',
        )
    try:
        return ai_service.get_weather(req.area)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
