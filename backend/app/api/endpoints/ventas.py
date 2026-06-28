from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Cuenta, ProyectoMiembro, Venta, Abono
from app.schemas.domain import VentaCreate, VentaResponse, AbonoCreate, AbonoResponse

router = APIRouter()

@router.post("/", response_model=VentaResponse, status_code=status.HTTP_201_CREATED)
async def create_venta(
    venta_in: VentaCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Retrieve Cuenta to check project membership
    result = await db.execute(select(Cuenta).filter(Cuenta.id == venta_in.cuenta_id))
    cuenta = result.scalars().first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
        
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == cuenta.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro del proyecto")

    total_venta = venta_in.kilos_vendidos * venta_in.precio_por_kg

    db_venta = Venta(
        cuenta_id=venta_in.cuenta_id,
        registrado_por=current_user.id,
        cliente=venta_in.cliente,
        kilos_vendidos=venta_in.kilos_vendidos,
        precio_por_kg=venta_in.precio_por_kg,
        total_venta=total_venta,
        fecha_venta=venta_in.fecha_venta
    )
    db.add(db_venta)
    await db.flush() # Get venta ID
    
    # Process initial abono if provided
    monto_inicial = venta_in.monto_inicial_pagado or 0.0
    if monto_inicial > 0:
        abono = Abono(
            venta_id=db_venta.id,
            registrado_por=current_user.id,
            monto=monto_inicial,
            fecha_abono=venta_in.fecha_venta,
            nota="Abono inicial"
        )
        db.add(abono)
        
    await db.commit()
    await db.refresh(db_venta)
    
    # Return mapped data
    v_dict = db_venta.__dict__.copy()
    v_dict['registrado_por_nombre'] = current_user.nombre
    v_dict['total_abonado'] = monto_inicial
    v_dict['saldo_pendiente'] = max(total_venta - monto_inicial, 0)
    v_dict['estado_pago'] = "Pagado" if monto_inicial >= total_venta else ("Parcial" if monto_inicial > 0 else "Pendiente")
    
    return v_dict

@router.get("/cuenta/{cuenta_id}", response_model=List[VentaResponse])
async def get_ventas(
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

    # Fetch Ventas with user names and sum of abonos
    stmt_ventas = select(Venta, Perfil.nombre).join(Perfil).filter(Venta.cuenta_id == cuenta_id).order_by(Venta.fecha_venta.desc())
    result_ventas = await db.execute(stmt_ventas)
    ventas_data = result_ventas.all()
    
    response = []
    for v, p_nombre in ventas_data:
        # Get total abonos
        stmt_a = select(func.sum(Abono.monto)).filter(Abono.venta_id == v.id)
        res_a = await db.execute(stmt_a)
        total_abonado = res_a.scalar() or 0.0
        
        v_dict = v.__dict__.copy()
        v_dict['registrado_por_nombre'] = p_nombre
        v_dict['total_abonado'] = total_abonado
        v_dict['saldo_pendiente'] = max(v.total_venta - total_abonado, 0)
        v_dict['estado_pago'] = "Pagado" if total_abonado >= v.total_venta else ("Parcial" if total_abonado > 0 else "Pendiente")
        
        response.append(v_dict)
        
    return response

@router.post("/abonos", response_model=AbonoResponse, status_code=status.HTTP_201_CREATED)
async def create_abono(
    abono_in: AbonoCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verifications would go here (Check if sale exists and permissions)
    
    db_abono = Abono(
        venta_id=abono_in.venta_id,
        registrado_por=current_user.id,
        monto=abono_in.monto,
        fecha_abono=abono_in.fecha_abono,
        nota=abono_in.nota
    )
    db.add(db_abono)
    await db.commit()
    await db.refresh(db_abono)
    return db_abono
