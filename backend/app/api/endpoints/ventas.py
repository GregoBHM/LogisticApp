from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Cuenta, ProyectoMiembro, Venta, Abono
from app.schemas.domain import VentaCreate, VentaResponse, AbonoCreate, AbonoResponse, VentaUpdate, AbonoUpdate

router = APIRouter()

async def _build_venta_response(db: AsyncSession, venta: Venta, nombre_perfil: str = "") -> dict:
    stmt_a = select(func.sum(Abono.monto)).filter(Abono.venta_id == venta.id)
    total_abonado = (await db.execute(stmt_a)).scalar() or 0.0
    saldo_pendiente = round(max(venta.total_venta - total_abonado, 0), 2)
    if round(total_abonado, 2) >= round(venta.total_venta, 2):
        estado_pago = "Cancelado"
    elif round(total_abonado, 2) > 0:
        estado_pago = "Parcial"
    else:
        estado_pago = "Pendiente"
    v_dict = venta.__dict__.copy()
    v_dict['registrado_por_nombre'] = nombre_perfil
    v_dict['total_abonado'] = total_abonado
    v_dict['saldo_pendiente'] = saldo_pendiente
    v_dict['estado_pago'] = estado_pago
    return v_dict

@router.put("/{id}", response_model=VentaResponse)
async def update_venta(
    id: str,
    venta_in: VentaUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Venta).filter(Venta.id == id))
    venta = result.scalars().first()
    if not venta:
        raise HTTPException(status_code=404, detail="Venta no encontrada")

    if venta_in.cliente is not None:
        venta.cliente = venta_in.cliente
    if venta_in.cantidad_vendida is not None:
        venta.cantidad_vendida = venta_in.cantidad_vendida
    if venta_in.precio_unitario is not None:
        venta.precio_unitario = venta_in.precio_unitario
    if venta_in.total_venta is not None:
        venta.total_venta = venta_in.total_venta
    elif venta_in.cantidad_vendida is not None or venta_in.precio_unitario is not None:
        venta.total_venta = round(venta.cantidad_vendida * venta.precio_unitario, 2)
    if venta_in.fecha_venta is not None:
        venta.fecha_venta = venta_in.fecha_venta

    await db.commit()
    await db.refresh(venta)
    return await _build_venta_response(db, venta, current_user.nombre)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_venta(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Venta).filter(Venta.id == id))
    venta = result.scalars().first()
    if not venta:
        raise HTTPException(status_code=404, detail="Venta no encontrada")
    await db.delete(venta)
    await db.commit()
    return None

@router.put("/abonos/{id}", response_model=AbonoResponse)
async def update_abono(
    id: str,
    abono_in: AbonoUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Abono).filter(Abono.id == id))
    abono = result.scalars().first()
    if not abono:
        raise HTTPException(status_code=404, detail="Abono no encontrado")
    if abono_in.monto is not None:
        abono.monto = abono_in.monto
    if abono_in.nota is not None:
        abono.nota = abono_in.nota
    if abono_in.fecha_abono is not None:
        abono.fecha_abono = abono_in.fecha_abono
    await db.commit()
    await db.refresh(abono)
    return abono

@router.delete("/abonos/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_abono(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Abono).filter(Abono.id == id))
    abono = result.scalars().first()
    if not abono:
        raise HTTPException(status_code=404, detail="Abono no encontrado")
    await db.delete(abono)
    await db.commit()
    return None

@router.get("/{id}/abonos", response_model=List[AbonoResponse])
async def get_abonos(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Abono).filter(Abono.venta_id == id).order_by(Abono.fecha_abono.asc())
    result = await db.execute(stmt)
    return result.scalars().all()

@router.post("/", response_model=VentaResponse, status_code=status.HTTP_201_CREATED)
async def create_venta(
    venta_in: VentaCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
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

    if venta_in.cantidad_vendida is None and venta_in.total_venta is not None:
        cantidad_calculada = round(venta_in.total_venta / venta_in.precio_unitario, 4)
        total_calculado = venta_in.total_venta
    elif venta_in.total_venta is None and venta_in.cantidad_vendida is not None:
        cantidad_calculada = venta_in.cantidad_vendida
        total_calculado = round(venta_in.cantidad_vendida * venta_in.precio_unitario, 2)
    else:
        cantidad_calculada = venta_in.cantidad_vendida or 0.0
        total_calculado = venta_in.total_venta or 0.0

    stmt_vendido = select(func.sum(Venta.cantidad_vendida)).filter(Venta.cuenta_id == cuenta.id)
    ya_vendido = (await db.execute(stmt_vendido)).scalar() or 0.0
    stock_disponible = cuenta.stock_total - ya_vendido

    if venta_in.cantidad_vendida is not None and cantidad_calculada > stock_disponible + 0.001:
        raise HTTPException(
            status_code=400,
            detail=f"Stock insuficiente. Disponible: {round(stock_disponible, 4)} {cuenta.unidad_medida}"
        )

    db_venta = Venta(
        cuenta_id=venta_in.cuenta_id,
        registrado_por=current_user.id,
        cliente=venta_in.cliente,
        cantidad_vendida=cantidad_calculada,
        precio_unitario=venta_in.precio_unitario,
        total_venta=total_calculado,
        fecha_venta=venta_in.fecha_venta
    )
    db.add(db_venta)
    await db.flush()

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

    v_dict = db_venta.__dict__.copy()
    v_dict['registrado_por_nombre'] = current_user.nombre
    v_dict['total_abonado'] = monto_inicial
    v_dict['saldo_pendiente'] = round(max(total_calculado - monto_inicial, 0), 2)
    if round(monto_inicial, 2) >= round(total_calculado, 2):
        v_dict['estado_pago'] = "Cancelado"
    elif round(monto_inicial, 2) > 0:
        v_dict['estado_pago'] = "Parcial"
    else:
        v_dict['estado_pago'] = "Pendiente"
    return v_dict

@router.get("/cuenta/{cuenta_id}", response_model=List[VentaResponse])
async def get_ventas(
    cuenta_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
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

    stmt_ventas = select(Venta, Perfil.nombre).join(Perfil).filter(Venta.cuenta_id == cuenta_id).order_by(Venta.fecha_venta.desc())
    result_ventas = await db.execute(stmt_ventas)
    ventas_data = result_ventas.all()

    response = []
    for v, p_nombre in ventas_data:
        response.append(await _build_venta_response(db, v, p_nombre))
    return response

@router.post("/abonos", response_model=AbonoResponse, status_code=status.HTTP_201_CREATED)
async def create_abono(
    abono_in: AbonoCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
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
