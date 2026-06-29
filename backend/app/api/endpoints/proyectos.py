from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.domain import Perfil, Proyecto, ProyectoMiembro
from app.schemas.domain import ProyectoCreate, ProyectoResponse, ProyectoUpdate

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
