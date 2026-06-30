from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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

# Aplicación interna (sin prefijos manuales)
api_app = FastAPI(
    title="StackMovi API",
    description="Backend API para gestión de inventarios y proyectos.",
    version="1.0.0",
)

# Configurar CORS para permitir que Flutter Web se conecte
api_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_app.include_router(api.router)

@api_app.get("/health")
def read_root():
    return {"message": "StackMovi API is running"}

# Aplicación principal que enruta todo bajo /movil
app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/movil", api_app)

