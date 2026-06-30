from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Proyecto, ProyectoMiembro, TransaccionGeneral, Cuenta, Venta, Gasto, Abono
from app.schemas.domain import ProyectoCreate, ProyectoResponse, ProyectoUpdate, ProyectoInvite, TransaccionGeneralCreate, TransaccionGeneralResponse, ProyectoReporteResponse, VentaReporteItem, GastoReporteItem, AbonoReporteItem

router = APIRouter()

@router.put("/{id}", response_model=ProyectoResponse)
async def update_proyecto(
    id: str,
    proyecto_in: ProyectoUpdate,
    current_user: Perfil = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify project exists and user is owner
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
        creado_por=current_user.id
    )
    db.add(db_proyecto)
    await db.flush() # Para obtener el ID del proyecto
    
    # Añadir al creador como dueño
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
    # Proyectos donde el usuario es miembro
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
    # TODO: Verify current_user is a member of the project
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
    # Verify current_user is dueño of the project
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == current_user.id
    )
    miembro = (await db.execute(stmt)).scalars().first()
    if not miembro or miembro.rol != "dueño":
        raise HTTPException(status_code=403, detail="No tienes permisos para invitar miembros")
        
    # Find user by email
    stmt = select(Perfil).filter(Perfil.email == invite_in.email)
    user_to_invite = (await db.execute(stmt)).scalars().first()
    if not user_to_invite:
        raise HTTPException(status_code=404, detail="Usuario no encontrado con ese correo electrónico")
        
    # Check if user is already a member
    stmt = select(ProyectoMiembro).filter(
        ProyectoMiembro.proyecto_id == id,
        ProyectoMiembro.usuario_id == user_to_invite.id
    )
    existing_member = (await db.execute(stmt)).scalars().first()
    if existing_member:
        raise HTTPException(status_code=400, detail="El usuario ya es miembro de este proyecto")
        
    # Add new member
    new_member = ProyectoMiembro(
        proyecto_id=id,
        usuario_id=user_to_invite.id,
        rol="vendedor"
    )
    db.add(new_member)
    await db.commit()
    return {"message": "Usuario invitado con éxito"}

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
    from sqlalchemy import func
    
    # Verificar proyecto y permisos
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

    # Fetch todas las cuentas del proyecto
    stmt_c = select(Cuenta).filter(Cuenta.proyecto_id == id)
    cuentas = (await db.execute(stmt_c)).scalars().all()
    
    inversion_total = sum(c.inversion_total for c in cuentas)
    kilos_totales = sum(c.cantidad_unidades * c.kg_por_unidad for c in cuentas)
    kilos_vendidos = 0.0
    ingresos_brutos = 0.0
    total_cobrado = 0.0
    total_gastos = 0.0

    ventas_list = []
    gastos_list = []
    abonos_list = []
    
    if not cuentas:
        return ProyectoReporteResponse(
            proyecto_id=str(proyecto.id),
            proyecto_nombre=proyecto.nombre,
            inversion_total=0.0,
            ingresos_brutos=0.0,
            total_cobrado=0.0,
            total_gastos=0.0,
            ganancia_real=0.0,
            kilos_totales=0.0,
            kilos_vendidos=0.0,
            kilos_restantes=0.0,
            ventas=[],
            gastos=[],
            abonos=[]
        )
        
    cuenta_ids = [c.id for c in cuentas]
    cuenta_nombres = {c.id: c.nombre for c in cuentas}
    
    # Gastos
    stmt_gastos = select(Gasto, Perfil.nombre).join(Perfil).filter(Gasto.cuenta_id.in_(cuenta_ids)).order_by(Gasto.fecha_gasto.desc())
    gastos_data = (await db.execute(stmt_gastos)).all()
    
    for g, p_nombre in gastos_data:
        g_resp = GastoReporteItem.from_orm(g)
        g_resp.registrado_por_nombre = p_nombre
        g_resp.cuenta_nombre = cuenta_nombres.get(g.cuenta_id, "Desconocida")
        gastos_list.append(g_resp)
        total_gastos += g.monto
        
    # Ventas y Abonos
    stmt_ventas = select(Venta, Perfil.nombre).join(Perfil).filter(Venta.cuenta_id.in_(cuenta_ids)).order_by(Venta.fecha_venta.desc())
    ventas_data = (await db.execute(stmt_ventas)).all()
    
    for v, p_nombre in ventas_data:
        stmt_a = select(func.sum(Abono.monto)).filter(Abono.venta_id == v.id)
        total_abonado_venta = (await db.execute(stmt_a)).scalar() or 0.0
        
        v_resp = VentaReporteItem.from_orm(v)
        v_resp.registrado_por_nombre = p_nombre
        v_resp.cuenta_nombre = cuenta_nombres.get(v.cuenta_id, "Desconocida")
        v_resp.total_abonado = total_abonado_venta
        v_resp.saldo_pendiente = round(max(v.total_venta - total_abonado_venta, 0), 2)
        v_resp.estado_pago = "Cancelado" if round(total_abonado_venta, 2) >= round(v.total_venta, 2) else ("Parcial" if round(total_abonado_venta, 2) > 0 else "Pendiente")
        ventas_list.append(v_resp)
        
        kilos_vendidos += v.kilos_vendidos
        ingresos_brutos += v.total_venta
        
    # Todos los Abonos detallados
    stmt_all_abonos = select(Abono, Venta, Perfil.nombre).join(Venta, Abono.venta_id == Venta.id).join(Perfil, Abono.registrado_por == Perfil.id).filter(Venta.cuenta_id.in_(cuenta_ids)).order_by(Abono.fecha_abono.desc())
    all_abonos_data = (await db.execute(stmt_all_abonos)).all()
    
    for ab, v, p_nombre in all_abonos_data:
        ab_resp = AbonoReporteItem.from_orm(ab)
        ab_resp.registrado_por_nombre = p_nombre
        ab_resp.cuenta_nombre = cuenta_nombres.get(v.cuenta_id, "Desconocida")
        ab_resp.cliente = v.cliente
        abonos_list.append(ab_resp)
        total_cobrado += ab.monto
        
    kilos_restantes = kilos_totales - kilos_vendidos
    ganancia_real = total_cobrado - inversion_total - total_gastos
    
    return ProyectoReporteResponse(
        proyecto_id=str(proyecto.id),
        proyecto_nombre=proyecto.nombre,
        inversion_total=inversion_total,
        ingresos_brutos=ingresos_brutos,
        total_cobrado=total_cobrado,
        total_gastos=total_gastos,
        ganancia_real=ganancia_real,
        kilos_totales=kilos_totales,
        kilos_vendidos=kilos_vendidos,
        kilos_restantes=kilos_restantes,
        ventas=ventas_list,
        gastos=gastos_list,
        abonos=abonos_list
    )
