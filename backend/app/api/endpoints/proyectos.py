from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from sqlalchemy.orm import selectinload
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Proyecto, ProyectoMiembro, TransaccionGeneral, Cuenta, Venta, Gasto, Abono, Empaque
from app.schemas.domain import (
    ProyectoCreate, ProyectoResponse, ProyectoUpdate, ProyectoInvite, ProyectoMiembroUpdate,
    TransaccionGeneralCreate, TransaccionGeneralResponse, TransaccionGeneralUpdate,
    ProyectoReporteResponse, VentaReporteItem, GastoReporteItem, AbonoReporteItem,
    EmpaqueCreate, EmpaqueResponse
)

router = APIRouter()

@router.put("/{id}", response_model=ProyectoResponse)
async def update_proyecto(
    id: str,
    proyecto_in: ProyectoUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Proyecto).filter(Proyecto.id == id))
    proyecto = result.scalars().first()
    if not proyecto:
        raise HTTPException(status_code=404, detail="Proyecto no encontrado")

    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(stmt)).scalars().first()
    if not miembro or miembro.rol != "dueño":
        raise HTTPException(status_code=403, detail="No tienes permisos para editar el proyecto")

    if proyecto_in.nombre is not None:
        proyecto.nombre = proyecto_in.nombre
    if proyecto_in.descripcion is not None:
        proyecto.descripcion = proyecto_in.descripcion
    if proyecto_in.producto_default is not None:
        proyecto.producto_default = proyecto_in.producto_default
    if proyecto_in.tipo_unidad_default is not None:
        proyecto.tipo_unidad_default = proyecto_in.tipo_unidad_default
    if proyecto_in.unidad_medida_default is not None:
        proyecto.unidad_medida_default = proyecto_in.unidad_medida_default
    if proyecto_in.cantidad_por_unidad_default is not None:
        proyecto.cantidad_por_unidad_default = proyecto_in.cantidad_por_unidad_default

    await db.commit()
    await db.refresh(proyecto)
    return proyecto

@router.post("/", response_model=ProyectoResponse, status_code=status.HTTP_201_CREATED)
async def create_proyecto(
    proyecto_in: ProyectoCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    db_proyecto = Proyecto(
        nombre=proyecto_in.nombre,
        descripcion=proyecto_in.descripcion,
        moneda_simbolo=proyecto_in.moneda_simbolo,
        moneda_codigo=proyecto_in.moneda_codigo,
        producto_default=proyecto_in.producto_default,
        tipo_unidad_default=proyecto_in.tipo_unidad_default,
        unidad_medida_default=proyecto_in.unidad_medida_default,
        cantidad_por_unidad_default=proyecto_in.cantidad_por_unidad_default,
        creado_por=current_user.id
    )
    db.add(db_proyecto)
    await db.flush()

    db_miembro = ProyectoMiembro(
        proyecto_id=db_proyecto.id,
        usuario_id=current_user.id,
        rol="dueño"
    )
    db.add(db_miembro)
    await db.commit()
    await db.refresh(db_proyecto)
    return db_proyecto

@router.get("/", response_model=List[ProyectoResponse])
async def get_proyectos(
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Proyecto).join(ProyectoMiembro).filter(ProyectoMiembro.usuario_id == current_user.id)
    result = await db.execute(stmt)
    proyectos = result.scalars().all()
    return proyectos

@router.get("/{id}/miembros")
async def get_miembros(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro, Perfil).join(Perfil, ProyectoMiembro.usuario_id == Perfil.id).filter(ProyectoMiembro.proyecto_id == id)
    result = await db.execute(stmt)
    miembros = []
    for pm, perfil in result.all():
        miembros.append({
            "usuario_id": pm.usuario_id,
            "rol": pm.rol,
            "nombre": perfil.nombre,
            "email": perfil.email
        })
    return miembros

@router.post("/{id}/invitar")
async def invitar_miembro(
    id: str,
    invite_in: ProyectoInvite,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(stmt)).scalars().first()
    if not miembro or miembro.rol != "dueño":
        raise HTTPException(status_code=403, detail="No tienes permisos para invitar miembros")

    stmt = select(Perfil).filter(Perfil.email == invite_in.email)
    user_to_invite = (await db.execute(stmt)).scalars().first()
    if not user_to_invite:
        raise HTTPException(status_code=404, detail="Usuario no encontrado con ese correo electrónico")

    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == user_to_invite.id
    )
    existing_member = (await db.execute(stmt)).scalars().first()
    if existing_member:
        raise HTTPException(status_code=400, detail="El usuario ya es miembro de este proyecto")

    new_member = ProyectoMiembro(
        proyecto_id=id,
        usuario_id=user_to_invite.id,
        rol="vendedor"
    )
    db.add(new_member)
    await db.commit()
    return {"message": "Usuario invitado con éxito"}

@router.put("/{id}/miembros/{usuario_id}")
async def update_miembro_rol(
    id: str,
    usuario_id: str,
    rol_update: ProyectoMiembroUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    requester = (await db.execute(stmt)).scalars().first()
    if not requester or requester.rol != "dueño":
        raise HTTPException(status_code=403, detail="Solo el dueño puede cambiar roles")

    stmt_target = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == usuario_id
    )
    target_member = (await db.execute(stmt_target)).scalars().first()
    if not target_member:
        raise HTTPException(status_code=404, detail="Miembro no encontrado en el proyecto")
    if target_member.rol == "dueño":
        raise HTTPException(status_code=403, detail="No puedes cambiar el rol del dueño")

    target_member.rol = rol_update.rol
    await db.commit()
    return {"message": "Rol actualizado con éxito"}

@router.delete("/{id}/miembros/{usuario_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_miembro(
    id: str,
    usuario_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    requester = (await db.execute(stmt)).scalars().first()
    if not requester or requester.rol != "dueño":
        raise HTTPException(status_code=403, detail="Solo el dueño puede expulsar miembros")

    stmt_target = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == usuario_id
    )
    target_member = (await db.execute(stmt_target)).scalars().first()
    if not target_member:
        raise HTTPException(status_code=404, detail="Miembro no encontrado en el proyecto")
    if target_member.rol == "dueño":
        raise HTTPException(status_code=403, detail="No puedes expulsar al dueño del proyecto")

    await db.delete(target_member)
    await db.commit()
    return None

@router.post("/{id}/transacciones/", response_model=TransaccionGeneralResponse, status_code=status.HTTP_201_CREATED)
async def create_transaccion(
    id: str,
    transaccion_in: TransaccionGeneralCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")

    db_trans = TransaccionGeneral(
        proyecto_id=id,
        registrado_por=current_user.id,
        tipo=transaccion_in.tipo,
        descripcion=transaccion_in.descripcion,
        monto=transaccion_in.monto,
        fecha_transaccion=transaccion_in.fecha_transaccion
    )
    db.add(db_trans)
    await db.commit()
    await db.refresh(db_trans)

    response = TransaccionGeneralResponse.from_orm(db_trans)
    response.registrado_por_nombre = current_user.nombre
    return response

@router.put("/transacciones/{transaccion_id}", response_model=TransaccionGeneralResponse)
async def update_transaccion(
    transaccion_id: str,
    trans_in: TransaccionGeneralUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(TransaccionGeneral).filter(TransaccionGeneral.id == transaccion_id)
    trans = (await db.execute(stmt)).scalars().first()
    if not trans:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")

    stmt_p = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == trans.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(stmt_p)).scalars().first()
    if not miembro or (miembro.rol != "dueño" and trans.registrado_por != current_user.id):
        raise HTTPException(status_code=403, detail="No tienes permisos para editar esta transacción")

    if trans_in.tipo is not None:
        trans.tipo = trans_in.tipo
    if trans_in.descripcion is not None:
        trans.descripcion = trans_in.descripcion
    if trans_in.monto is not None:
        trans.monto = trans_in.monto
    if trans_in.fecha_transaccion is not None:
        trans.fecha_transaccion = trans_in.fecha_transaccion

    await db.commit()
    await db.refresh(trans)

    response = TransaccionGeneralResponse.from_orm(trans)
    response.registrado_por_nombre = current_user.nombre
    return response

@router.get("/{id}/transacciones/", response_model=List[TransaccionGeneralResponse])
async def get_transacciones(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")

    stmt_t = (
        select(TransaccionGeneral, Perfil.nombre.label("registrado_por_nombre"))
        .join(Perfil, TransaccionGeneral.registrado_por == Perfil.id)
        .filter(TransaccionGeneral.proyecto_id == id)
        .order_by(TransaccionGeneral.fecha_transaccion.desc(), TransaccionGeneral.created_at.desc())
    )
    result = await db.execute(stmt_t)

    transacciones = []
    for t, nombre in result.all():
        t_resp = TransaccionGeneralResponse.from_orm(t)
        t_resp.registrado_por_nombre = nombre
        transacciones.append(t_resp)
    return transacciones

@router.delete("/transacciones/{transaccion_id}")
async def delete_transaccion(
    transaccion_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(TransaccionGeneral).filter(TransaccionGeneral.id == transaccion_id)
    trans = (await db.execute(stmt)).scalars().first()
    if not trans:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")

    stmt_p = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == trans.proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(stmt_p)).scalars().first()
    if not miembro or (miembro.rol != "dueño" and trans.registrado_por != current_user.id):
        raise HTTPException(status_code=403, detail="No tienes permisos para eliminar esta transacción")

    await db.delete(trans)
    await db.commit()
    return None

@router.get("/{id}/reporte_datos", response_model=ProyectoReporteResponse)
async def get_proyecto_reporte_datos(
    id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Proyecto).filter(Proyecto.id == id)
    proyecto = (await db.execute(stmt)).scalars().first()
    if not proyecto:
        raise HTTPException(status_code=404, detail="Proyecto no encontrado")

    stmt_m = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    if not (await db.execute(stmt_m)).scalars().first():
        raise HTTPException(status_code=403, detail="No eres miembro de este proyecto")

    stmt_c = select(Cuenta).filter(Cuenta.proyecto_id == id)
    cuentas = (await db.execute(stmt_c)).scalars().all()

    if not cuentas:
        return ProyectoReporteResponse(
            proyecto_id=str(proyecto.id),
            proyecto_nombre=proyecto.nombre,
            inversion_total=0.0,
            ingresos_brutos=0.0,
            total_cobrado=0.0,
            total_gastos=0.0,
            ganancia_real=0.0,
            stock_total=0.0,
            cantidad_vendida=0.0,
            stock_restante=0.0,
            ventas=[],
            gastos=[],
            abonos=[]
        )

    inversion_total = sum(c.inversion_total for c in cuentas)
    stock_total = sum(c.stock_total for c in cuentas)
    cuenta_ids = [c.id for c in cuentas]
    cuenta_nombres = {c.id: c.nombre for c in cuentas}

    cantidad_vendida = 0.0
    ingresos_brutos = 0.0
    total_cobrado = 0.0
    total_gastos = 0.0
    ventas_list = []
    gastos_list = []
    abonos_list = []

    stmt_gastos = select(Gasto, Perfil.nombre).join(Perfil).filter(Gasto.cuenta_id.in_(cuenta_ids)).order_by(Gasto.fecha_gasto.desc())
    gastos_data = (await db.execute(stmt_gastos)).all()
    for g, p_nombre in gastos_data:
        setattr(g, 'cuenta_nombre', cuenta_nombres.get(g.cuenta_id, "Desconocida"))
        setattr(g, 'registrado_por_nombre', p_nombre)
        gastos_list.append(GastoReporteItem.from_orm(g))
        total_gastos += g.monto

    stmt_ventas = select(Venta, Perfil.nombre).join(Perfil).filter(Venta.cuenta_id.in_(cuenta_ids)).order_by(Venta.fecha_venta.desc())
    ventas_data = (await db.execute(stmt_ventas)).all()

    venta_ids = [v.id for v, _ in ventas_data]
    abono_sums = {}
    if venta_ids:
        stmt_abs = select(Abono.venta_id, func.sum(Abono.monto)).filter(Abono.venta_id.in_(venta_ids)).group_by(Abono.venta_id)
        for venta_id, total in (await db.execute(stmt_abs)).all():
            abono_sums[venta_id] = total or 0.0

    for v, p_nombre in ventas_data:
        total_abonado_venta = abono_sums.get(v.id, 0.0)
        saldo = round(max(v.total_venta - total_abonado_venta, 0), 2)
        if round(total_abonado_venta, 2) >= round(v.total_venta, 2):
            ep = "Cancelado"
        elif round(total_abonado_venta, 2) > 0:
            ep = "Parcial"
        else:
            ep = "Pendiente"
        setattr(v, 'cuenta_nombre', cuenta_nombres.get(v.cuenta_id, "Desconocida"))
        setattr(v, 'registrado_por_nombre', p_nombre)
        setattr(v, 'total_abonado', total_abonado_venta)
        setattr(v, 'saldo_pendiente', saldo)
        setattr(v, 'estado_pago', ep)
        ventas_list.append(VentaReporteItem.from_orm(v))
        cantidad_vendida += v.cantidad_vendida
        ingresos_brutos += v.total_venta

    stmt_all_abonos = (
        select(Abono, Venta, Perfil.nombre)
        .join(Venta, Abono.venta_id == Venta.id)
        .join(Perfil, Abono.registrado_por == Perfil.id)
        .filter(Venta.cuenta_id.in_(cuenta_ids))
        .order_by(Abono.fecha_abono.desc())
    )
    all_abonos_data = (await db.execute(stmt_all_abonos)).all()
    for ab, v, p_nombre in all_abonos_data:
        setattr(ab, 'cuenta_nombre', cuenta_nombres.get(v.cuenta_id, "Desconocida"))
        setattr(ab, 'cliente', v.cliente)
        setattr(ab, 'registrado_por_nombre', p_nombre)
        abonos_list.append(AbonoReporteItem.from_orm(ab))
        total_cobrado += ab.monto

    stock_restante = stock_total - cantidad_vendida
    ganancia_real = total_cobrado - inversion_total - total_gastos

    return ProyectoReporteResponse(
        proyecto_id=str(proyecto.id),
        proyecto_nombre=proyecto.nombre,
        inversion_total=inversion_total,
        ingresos_brutos=ingresos_brutos,
        total_cobrado=total_cobrado,
        total_gastos=total_gastos,
        ganancia_real=ganancia_real,
        stock_total=stock_total,
        cantidad_vendida=cantidad_vendida,
        stock_restante=stock_restante,
        ventas=ventas_list,
        gastos=gastos_list,
        abonos=abonos_list
    )

# ─── EMPAQUES ───────────────────────────────────────────────────────────────────

@router.get("/{proyecto_id}/empaques", response_model=List[EmpaqueResponse])
async def get_empaques(
    proyecto_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify membership
    miembro_stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(miembro_stmt)).scalars().first()
    if not miembro:
        raise HTTPException(status_code=403, detail="No tienes acceso a este proyecto")

    result = await db.execute(
        select(Empaque).filter(Empaque.proyecto_id == proyecto_id).order_by(Empaque.created_at)
    )
    return result.scalars().all()


@router.post("/{proyecto_id}/empaques", response_model=EmpaqueResponse, status_code=201)
async def create_empaque(
    proyecto_id: str,
    empaque_in: EmpaqueCreate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify membership and owner role
    miembro_stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(miembro_stmt)).scalars().first()
    if not miembro or miembro.rol != "dueno":
        raise HTTPException(status_code=403, detail="Solo el dueño puede configurar empaques")

    empaque = Empaque(
        proyecto_id=proyecto_id,
        nombre=empaque_in.nombre,
        unidad_medida=empaque_in.unidad_medida,
        cantidad_por_unidad=empaque_in.cantidad_por_unidad,
        descripcion=empaque_in.descripcion,
    )
    db.add(empaque)
    await db.commit()
    await db.refresh(empaque)
    return empaque


@router.delete("/{proyecto_id}/empaques/{empaque_id}", status_code=204)
async def delete_empaque(
    proyecto_id: str,
    empaque_id: str,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    miembro_stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == proyecto_id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(miembro_stmt)).scalars().first()
    if not miembro or miembro.rol != "dueno":
        raise HTTPException(status_code=403, detail="Solo el dueño puede eliminar empaques")

    result = await db.execute(
        select(Empaque).filter(Empaque.id == empaque_id, Empaque.proyecto_id == proyecto_id)
    )
    empaque = result.scalars().first()
    if not empaque:
        raise HTTPException(status_code=404, detail="Empaque no encontrado")

    await db.delete(empaque)
    await db.commit()
