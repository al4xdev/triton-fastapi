from fastapi import APIRouter, Query
import numpy
from tritonclient.grpc import InferenceServerClient, InferInput, InferRequestedOutput
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
async def infer_triton(
    model_name: str = Query(..., description="Nome do modelo no Triton"),
    input_data: list[float] = Query(..., description="Dados de entrada para inferência")
):
    # Conectar no Triton via gRPC na porta 8001
    triton_client = InferenceServerClient(url="localhost:8001", verbose=False)

    # Criar objeto InferInput - aqui assumo que o modelo espera uma entrada shape [1, N]
    input_tensor = InferInput("input__0", [1, len(input_data)], "FP32")
    input_tensor.set_data_from_numpy(np.array([input_data], dtype=np.float32))

    # Definir a saída que queremos
    output = InferRequestedOutput("output__0")

    # Fazer a inferência
    response = triton_client.infer(model_name=model_name, inputs=[input_tensor], outputs=[output])

    # Pegar o resultado
    output_data = response.as_numpy("output__0")

    return {"result": output_data.tolist()}


