from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List
from datetime import datetime
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Cuenta, ProyectoMiembro, Venta, Abono, Gasto
from app.schemas.domain import CuentaCreate, CuentaResponse, CuentaUpdate, AbonoDetalleResponse

router = APIRouter()

async def _build_cuenta_response(db: AsyncSession, cuenta: Cuenta) -> dict:
    stmt_v = select(func.sum(Venta.cantidad_vendida), func.sum(Venta.total_venta)).filter(Venta.cuenta_id == cuenta.id)
    res_v = await db.execute(stmt_v)
    cantidad_vendida, ingresos_brutos = res_v.first()
    cantidad_vendida = cantidad_vendida or 0.0
    ingresos_brutos = ingresos_brutos or 0.0

    stmt_g = select(func.sum(Gasto.monto)).filter(Gasto.cuenta_id == cuenta.id)
    total_gastos = (await db.execute(stmt_g)).scalar() or 0.0

    stmt_a = select(func.sum(Abono.monto)).join(Venta).filter(Venta.cuenta_id == cuenta.id)
    total_cobrado = (await db.execute(stmt_a)).scalar() or 0.0

    c_dict = cuenta.__dict__.copy()
    c_dict['cantidad_vendida'] = cantidad_vendida
    c_dict['ingresos_brutos'] = ingresos_brutos
    c_dict['stock_restante'] = max(cuenta.stock_total - cantidad_vendida, 0)
    c_dict['total_gastos'] = total_gastos
    c_dict['total_cobrado'] = total_cobrado
    c_dict['ganancia_real'] = total_cobrado - cuenta.inversion_total - total_gastos
    return c_dict

@router.put("/{id}", response_model=CuentaResponse)
async def update_cuenta(
    id: str,
    cuenta_in: CuentaUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Cuenta).filter(Cuenta.id == id))
    cuenta = result.scalars().first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")

    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == cuenta.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro del proyecto")

    if cuenta_in.nombre is not None:
        cuenta.nombre = cuenta_in.nombre
    if cuenta_in.producto is not None:
        cuenta.producto = cuenta_in.producto
    if cuenta_in.tipo_unidad is not None:
        cuenta.tipo_unidad = cuenta_in.tipo_unidad
    if cuenta_in.unidad_medida is not None:
        cuenta.unidad_medida = cuenta_in.unidad_medida
    if cuenta_in.fecha_apertura is not None:
        cuenta.fecha_apertura = cuenta_in.fecha_apertura

    recalc_stock = False
    if cuenta_in.cantidad_unidades is not None:
        cuenta.cantidad_unidades = cuenta_in.cantidad_unidades
        recalc_stock = True
    if cuenta_in.cantidad_por_unidad is not None:
        cuenta.cantidad_por_unidad = cuenta_in.cantidad_por_unidad
        recalc_stock = True
    if recalc_stock:
        cuenta.stock_total = cuenta.cantidad_unidades * cuenta.cantidad_por_unidad

    if cuenta_in.inversion_total is not None:
        cuenta.inversion_total = cuenta_in.inversion_total
    if cuenta_in.precio_unitario is not None:
        cuenta.precio_unitario = cuenta_in.precio_unitario

    await db.commit()
    await db.refresh(cuenta)
    return await _build_cuenta_response(db, cuenta)

@router.post("/", response_model=CuentaResponse, status_code=status.HTTP_201_CREATED)
async def create_cuenta(
    cuenta_in: CuentaCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == cuenta_in.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    result = await db.execute(stmt)
    if not result.scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")

    stock_total = cuenta_in.cantidad_unidades * cuenta_in.cantidad_por_unidad

    db_cuenta = Cuenta(
        proyecto_id=cuenta_in.proyecto_id,
        nombre=cuenta_in.nombre,
        producto=cuenta_in.producto,
        tipo_unidad=cuenta_in.tipo_unidad,
        unidad_medida=cuenta_in.unidad_medida,
        cantidad_unidades=cuenta_in.cantidad_unidades,
        cantidad_por_unidad=cuenta_in.cantidad_por_unidad,
        stock_total=stock_total,
        inversion_total=cuenta_in.inversion_total,
        precio_unitario=cuenta_in.precio_unitario,
        fecha_apertura=cuenta_in.fecha_apertura,
        creado_por=current_user.id
    )
    db.add(db_cuenta)
    await db.commit()
    await db.refresh(db_cuenta)

    c_dict = db_cuenta.__dict__.copy()
    c_dict['cantidad_vendida'] = 0.0
    c_dict['ingresos_brutos'] = 0.0
    c_dict['stock_restante'] = stock_total
    c_dict['total_gastos'] = 0.0
    c_dict['total_cobrado'] = 0.0
    c_dict['ganancia_real'] = -db_cuenta.inversion_total
    return c_dict

@router.get("/proyecto/{proyecto_id}", response_model=List[CuentaResponse])
async def get_cuentas(
    proyecto_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    result = await db.execute(stmt)
    if not result.scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")

    stmt_cuentas = select(Cuenta).filter(Cuenta.proyecto_id == proyecto_id).order_by(Cuenta.fecha_apertura.desc())
    result_cuentas = await db.execute(stmt_cuentas)
    cuentas = result_cuentas.scalars().all()

    cuentas_response = []
    for c in cuentas:
        cuentas_response.append(await _build_cuenta_response(db, c))
    return cuentas_response

@router.get("/{cuenta_id}", response_model=CuentaResponse)
async def get_cuenta(
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
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")
    return await _build_cuenta_response(db, cuenta)

@router.put("/{cuenta_id}/cerrar")
async def cerrar_cuenta(
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

    cuenta.estado = "cerrada"
    cuenta.cerrado_por = current_user.id
    cuenta.fecha_cierre = datetime.utcnow().date()
    await db.commit()
    return {"message": "Cuenta cerrada"}

@router.put("/{cuenta_id}/reabrir")
async def reabrir_cuenta(
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

    cuenta.estado = "abierta"
    cuenta.cerrado_por = None
    cuenta.fecha_cierre = None
    await db.commit()
    return {"message": "Cuenta reabierta"}

@router.get("/{id}/abonos", response_model=List[AbonoDetalleResponse])
async def get_cuenta_abonos(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Cuenta).filter(Cuenta.id == id))
    cuenta = result.scalars().first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")

    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == cuenta.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")

    stmt_a = (
        select(Abono, Venta.cliente, Perfil.nombre.label("registrado_por_nombre"))
        .join(Venta, Abono.venta_id == Venta.id)
        .outerjoin(Perfil, Abono.registrado_por == Perfil.id)
        .filter(Venta.cuenta_id == id)
        .order_by(Abono.fecha_abono.asc(), Abono.created_at.asc())
    )
    res_a = await db.execute(stmt_a)

    abonos_detallados = []
    for abono, cliente, registrado_por_nombre in res_a.all():
        abono_dict = abono.__dict__.copy()
        abono_dict["cliente"] = cliente
        abono_dict["registrado_por_nombre"] = registrado_por_nombre
        abonos_detallados.append(abono_dict)
    return abonos_detallados
