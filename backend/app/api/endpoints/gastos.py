from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Cuenta, ProyectoMiembro, Gasto
from app.schemas.domain import GastoCreate, GastoResponse, GastoUpdate

router = APIRouter()

@router.put("/{id}", response_model=GastoResponse)
async def update_gasto(
    id: str,
    gasto_in: GastoUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Gasto).filter(Gasto.id == id))
    gasto = result.scalars().first()
    if not gasto:
        raise HTTPException(status_code=404, detail="Gasto no encontrado")
        
    if gasto_in.descripcion is not None:
        gasto.descripcion = gasto_in.descripcion
    if gasto_in.monto is not None:
        gasto.monto = gasto_in.monto
    if gasto_in.fecha_gasto is not None:
        gasto.fecha_gasto = gasto_in.fecha_gasto
        
    await db.commit()
    await db.refresh(gasto)
    
    g_dict = gasto.__dict__.copy()
    g_dict['registrado_por_nombre'] = ""
    return g_dict

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_gasto(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Gasto).filter(Gasto.id == id))
    gasto = result.scalars().first()
    if not gasto:
        raise HTTPException(status_code=404, detail="Gasto no encontrado")
        
    await db.delete(gasto)
    await db.commit()
    return None

@router.post("/", response_model=GastoResponse, status_code=status.HTTP_201_CREATED)
async def create_gasto(
    gasto_in: GastoCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify account & permissions
    result = await db.execute(select(Cuenta).filter(Cuenta.id == gasto_in.cuenta_id))
    cuenta = result.scalars().first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
        
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == cuenta.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro")

    db_gasto = Gasto(
        cuenta_id=gasto_in.cuenta_id,
        registrado_por=current_user.id,
        descripcion=gasto_in.descripcion,
        monto=gasto_in.monto,
        fecha_gasto=gasto_in.fecha_gasto
    )
    db.add(db_gasto)
    await db.commit()
    await db.refresh(db_gasto)
    
    g_dict = db_gasto.__dict__.copy()
    g_dict['registrado_por_nombre'] = current_user.nombre
    return g_dict

@router.get("/cuenta/{cuenta_id}", response_model=List[GastoResponse])
async def get_gastos(
    cuenta_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify account & permissions
    result = await db.execute(select(Cuenta).filter(Cuenta.id == cuenta_id))
    cuenta = result.scalars().first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
        
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == cuenta.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro")

    # Fetch Gastos with user names
    stmt_gastos = select(Gasto, Perfil.nombre).join(Perfil).filter(Gasto.cuenta_id == cuenta_id).order_by(Gasto.fecha_gasto.desc())
    result_gastos = await db.execute(stmt_gastos)
    gastos_data = result_gastos.all()
    
    response = []
    for g, p_nombre in gastos_data:
        g_dict = g.__dict__.copy()
        g_dict['registrado_por_nombre'] = p_nombre
        response.append(g_dict)
        
    return response
