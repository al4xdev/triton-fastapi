from fastapi import APIRouter, Query
import numpy
import httpx # For making HTTP requests to vLLM
import logging # For logging
from typing import List # For type hinting

logger = logging.getLogger(__name__)

from .schemas import ErrorsResponse, UsageResponse
from .database import async_get_last_error_logs, async_query_usage_month

router = APIRouter()

@router.get("/errors", response_model=ErrorsResponse)
async def get_errors(
    n: int = Query(10, gt=0, description="Número de registros a retornar"),
    project_id: str|None = Query(None, description="Filtro opcional por project_id")
):
    await_result = await async_get_last_error_logs(n, project_id)
    return {"errors": await_result}


@router.get("/usage", response_model=UsageResponse)
async def get_usage(
    project_id: str|None = Query(None, description="Filtro opcional por project_id"),
    year: int = Query(..., ge=2000, le=2100, description="Ano para consulta"),
    month: int = Query(..., ge=1, le=12, description="Mês para consulta")
):
    result = await async_query_usage_month(project_id, year, month)
    return {"usage": result}


@router.post("/infer")
async def infer(
    prompt: str = Query(..., description="Input prompt for the vLLM model"),
    model: str = Query("phi-4", description="Name of the vLLM model to use") # Assuming a default vLLM model name
):
    vllm_url = "http://localhost:8000/v1/completions" # Default vLLM OpenAI-compatible API endpoint

    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "model": model,
        "prompt": prompt,
        "max_tokens": 100, # Example parameter
        "temperature": 0.7 # Example parameter
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(vllm_url, headers=headers, json=payload, timeout=60.0)
            response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)
            result = response.json()
            logger.info(f"vLLM inference successful: {result}")
            return {"result": result}
        except httpx.RequestError as exc:
            logger.error(f"An error occurred while requesting {exc.request.url!r}: {exc}")
            return {"error": f"Failed to connect to vLLM server: {exc}"}, 500
        except httpx.HTTPStatusError as exc:
            logger.error(f"Error response {exc.response.status_code} while requesting {exc.request.url!r}: {exc}")
            return {"error": f"vLLM server returned an error: {exc.response.text}"}, exc.response.status_code
        except Exception as e:
            logger.error(f"An unexpected error occurred: {e}")
            return {"error": f"An unexpected error occurred: {e}"}, 500


