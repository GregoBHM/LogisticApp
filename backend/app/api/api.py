from fastapi import APIRouter
from app.api.endpoints import reports, auth, proyectos, cuentas, ventas

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(proyectos.router, prefix="/proyectos", tags=["proyectos"])
router.include_router(cuentas.router, prefix="/cuentas", tags=["cuentas"])
router.include_router(ventas.router, prefix="/ventas", tags=["ventas"])
router.include_router(reports.router, prefix="/reports", tags=["reports"])
