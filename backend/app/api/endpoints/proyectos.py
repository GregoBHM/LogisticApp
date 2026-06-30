from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Proyecto, ProyectoMiembro, TransaccionGeneral
from app.schemas.domain import ProyectoCreate, ProyectoResponse, ProyectoUpdate, ProyectoInvite, TransaccionGeneralCreate, TransaccionGeneralResponse

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
        t_dict = t.__dict__.copy()
        t_dict["registrado_por_nombre"] = nombre
        transacciones.append(t_dict)
        
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
