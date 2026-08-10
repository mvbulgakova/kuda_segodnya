"""LLM-мост между Godot-клиентом и Anthropic API.

Godot ходит сюда HTTP-запросами. Мы уже дальше — к Claude.
API-ключ живёт только тут (на сервере), клиент его никогда не видит.

Запуск локально:
    export ANTHROPIC_API_KEY=sk-ant-...
    uvicorn main:app --reload --port 8000

В проде — за прокси/nginx/https.
"""
from __future__ import annotations

import json
import os
from typing import Any

from anthropic import Anthropic
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

MODEL = os.getenv("CLAUDE_MODEL", "claude-haiku-4-5-20251001")

app = FastAPI(title="Ночь перед КР — LLM bridge")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # локально ок; в проде сузить
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Anthropic()  # ключ читается из ANTHROPIC_API_KEY


# --- /explain: педагогическая мини-игра «объясни школьнику» -----------------

class ExplainIn(BaseModel):
    topic: str
    explanation: str


class ExplainOut(BaseModel):
    understood: bool
    comment: str


SCHOOL_SYSTEM = """Ты — Митя, семиклассник 13 лет. Тебе задали дом.задание по математике,
и старший брат/сестра пытается объяснить тебе тему.

Отвечай КАК подросток: коротко, живо, с эмоцией. Если реально понял —
скажи что понял и переспроси одну деталь. Если не понял — честно скажи,
где именно затерялся, и попроси уточнить.

Твоя задача — ЧЕСТНАЯ реакция. Не подыгрывай. Если объяснение
использует термины, которые ты не проходил в 7 классе — не поймёшь.
Если объясняют без примеров — попроси пример. Если объяснение
меньше 15 слов — это слишком мало.

Отвечай СТРОГО валидным JSON:
{"understood": true/false, "comment": "твоя реплика 1-3 предложения"}
Никакого текста вне JSON.
"""


@app.post("/explain", response_model=ExplainOut)
def explain(inp: ExplainIn) -> ExplainOut:
    user_msg = (
        f"Тема, которую тебе объясняют: {inp.topic}\n\n"
        f"Объяснение старшего:\n{inp.explanation}\n\n"
        f"Ответь JSON: {{\"understood\": ..., \"comment\": \"...\"}}"
    )
    resp = client.messages.create(
        model=MODEL,
        max_tokens=400,
        system=SCHOOL_SYSTEM,
        messages=[{"role": "user", "content": user_msg}],
    )
    raw = _extract_text(resp)
    data = _parse_json_lenient(raw)
    if not isinstance(data, dict):
        return ExplainOut(understood=False, comment="…не понял, что ты сказал.")
    return ExplainOut(
        understood=bool(data.get("understood", False)),
        comment=str(data.get("comment", "")),
    )


# --- /npc: свободный диалог со старшекурсником ------------------------------

class NpcIn(BaseModel):
    character: str  # "senior_artem", "vahtyor_lyuba" и т.п.
    question: str


class NpcOut(BaseModel):
    text: str


CHARACTERS = {
    "senior_artem": (
        "Ты — Артём, четверокурсник ИМИ МПГУ на Гаврикова 7-9. "
        "Своим первокурсникам помогаешь как старший товарищ. "
        "Говоришь коротко, по-дружески, чуть с иронией. Знаешь, где "
        "деканат, где столовая, у какого препода что просить, как готовиться к "
        "первой внутрисеместровой. Не пересыпай терминами: собеседник — новичок. "
        "Если чего-то реально не знаешь — скажи, а не выдумывай."
    ),
    "vahtyor_lyuba": (
        "Ты — тётя Люба, вахтёр в корпусе Гаврикова 7-9. Работаешь тут 15 лет, "
        "всех знаешь в лицо. Говоришь чуть строго, но по-доброму. Замечаешь всё. "
        "Отвечаешь короткими фразами."
    ),
    "curator_valeria": (
        "Ты — Валерия, куратор группы первокурсников ИМИ МПГУ. По образованию "
        "методист. Отвечаешь спокойно, чётко, с педагогической точностью. "
        "Умеешь объяснить, куда с каким заявлением идти. Не сюсюкаешь."
    ),
}

NPC_SYSTEM_SUFFIX = (
    "\n\nОтвечай СТРОГО валидным JSON: {\"text\": \"твоя реплика\"}. "
    "Никакого текста вне JSON. Реплика — 1-3 предложения."
)


@app.post("/npc", response_model=NpcOut)
def npc(inp: NpcIn) -> NpcOut:
    system_prompt = CHARACTERS.get(inp.character)
    if not system_prompt:
        raise HTTPException(status_code=404, detail=f"Unknown character: {inp.character}")
    resp = client.messages.create(
        model=MODEL,
        max_tokens=300,
        system=system_prompt + NPC_SYSTEM_SUFFIX,
        messages=[{"role": "user", "content": inp.question}],
    )
    raw = _extract_text(resp)
    data = _parse_json_lenient(raw)
    if not isinstance(data, dict):
        return NpcOut(text=raw.strip()[:500])
    return NpcOut(text=str(data.get("text", "")).strip()[:500])


# --- health -----------------------------------------------------------------

@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "model": MODEL}


# --- utils ------------------------------------------------------------------

def _extract_text(resp: Any) -> str:
    parts = []
    for block in resp.content:
        if getattr(block, "type", None) == "text":
            parts.append(block.text)
    return "\n".join(parts)


def _parse_json_lenient(raw: str) -> Any:
    """Модели иногда оборачивают JSON в ```json ... ``` или добавляют
    объясняющий хвост. Достаём первый {...} блок и парсим."""
    raw = raw.strip()
    if raw.startswith("```"):
        raw = raw.strip("`")
        if raw.startswith("json"):
            raw = raw[4:]
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None
    try:
        return json.loads(raw[start:end + 1])
    except json.JSONDecodeError:
        return None
