from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def get_reports_info():
    return {"message": "Endpoint para exportar reportes (Excel/PDF) estará disponible aquí."}
