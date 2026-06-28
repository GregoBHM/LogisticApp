from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.api import api
from app.core.database import engine, Base
from app.models.domain import * # Import to register models

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Inicializar tablas si no existen
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(
    title="StackMovi API",
    description="Backend API para gestión de inventarios y proyectos.",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(api.router, prefix="/movil")

@app.get("/movil/health")
def read_root():
    return {"message": "StackMovi API is running"}
