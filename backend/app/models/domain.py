import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, ForeignKey, DateTime, Date, Boolean, Integer, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class Perfil(Base):
    __tablename__ = "perfiles"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    nombre = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    proyectos_creados = relationship("Proyecto", back_populates="creador")
    miembros = relationship("ProyectoMiembro", back_populates="usuario")

class Proyecto(Base):
    __tablename__ = "proyectos"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    nombre = Column(String, nullable=False)
    descripcion = Column(String, nullable=True)
    moneda_simbolo = Column(String, default="S/", nullable=False)
    moneda_codigo = Column(String, default="PEN", nullable=False)
    creado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    creador = relationship("Perfil", back_populates="proyectos_creados")
    miembros = relationship("ProyectoMiembro", back_populates="proyecto", cascade="all, delete-orphan")
    cuentas = relationship("Cuenta", back_populates="proyecto", cascade="all, delete-orphan")
    transacciones = relationship("TransaccionGeneral", back_populates="proyecto", cascade="all, delete-orphan")

class ProyectoMiembro(Base):
    __tablename__ = "proyecto_miembros"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    proyecto_id = Column(UUID(as_uuid=False), ForeignKey("proyectos.id", ondelete="CASCADE"), nullable=False)
    usuario_id = Column(UUID(as_uuid=False), ForeignKey("perfiles.id", ondelete="CASCADE"), nullable=False)
    rol = Column(String, default="vendedor", nullable=False)
    invited_at = Column(DateTime, default=datetime.utcnow)

    proyecto = relationship("Proyecto", back_populates="miembros")
    usuario = relationship("Perfil", back_populates="miembros")

class Cuenta(Base):
    __tablename__ = "cuentas"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    proyecto_id = Column(UUID(as_uuid=False), ForeignKey("proyectos.id", ondelete="CASCADE"), nullable=False)
    nombre = Column(String, nullable=False)
    producto = Column(String, nullable=False)
    tipo_unidad = Column(String, nullable=False)
    unidad_medida = Column(String, default="und", nullable=False)
    cantidad_unidades = Column(Float, nullable=False)
    cantidad_por_unidad = Column(Float, nullable=False, default=1.0)
    stock_total = Column(Float, nullable=False)
    inversion_total = Column(Float, nullable=False)
    precio_unitario = Column(Float, nullable=False)
    estado = Column(String, default="abierta", nullable=False)
    creado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=False)
    cerrado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=True)
    fecha_apertura = Column(Date, default=datetime.utcnow)
    fecha_cierre = Column(Date, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    proyecto = relationship("Proyecto", back_populates="cuentas")
    ventas = relationship("Venta", back_populates="cuenta", cascade="all, delete-orphan")
    gastos = relationship("Gasto", back_populates="cuenta", cascade="all, delete-orphan")

class Venta(Base):
    __tablename__ = "ventas"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    cuenta_id = Column(UUID(as_uuid=False), ForeignKey("cuentas.id", ondelete="CASCADE"), nullable=False)
    registrado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=False)
    cliente = Column(String, nullable=False)
    cantidad_vendida = Column(Float, nullable=False)
    precio_unitario = Column(Float, nullable=False)
    total_venta = Column(Float, nullable=False)
    fecha_venta = Column(Date, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    cuenta = relationship("Cuenta", back_populates="ventas")
    perfil = relationship("Perfil")
    abonos = relationship("Abono", back_populates="venta", cascade="all, delete-orphan")

class Abono(Base):
    __tablename__ = "abonos"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    venta_id = Column(UUID(as_uuid=False), ForeignKey("ventas.id", ondelete="CASCADE"), nullable=False)
    registrado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=False)
    monto = Column(Float, nullable=False)
    fecha_abono = Column(Date, default=datetime.utcnow)
    nota = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    venta = relationship("Venta", back_populates="abonos")

class Gasto(Base):
    __tablename__ = "gastos"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    cuenta_id = Column(UUID(as_uuid=False), ForeignKey("cuentas.id", ondelete="CASCADE"), nullable=False)
    registrado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=False)
    descripcion = Column(String, nullable=False)
    categoria = Column(String, nullable=True)
    monto = Column(Float, nullable=False)
    fecha_gasto = Column(Date, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    cuenta = relationship("Cuenta", back_populates="gastos")
    perfil = relationship("Perfil")

class TransaccionGeneral(Base):
    __tablename__ = "transacciones_generales"

    id = Column(UUID(as_uuid=False), primary_key=True, default=generate_uuid)
    proyecto_id = Column(UUID(as_uuid=False), ForeignKey("proyectos.id", ondelete="CASCADE"), nullable=False)
    registrado_por = Column(UUID(as_uuid=False), ForeignKey("perfiles.id"), nullable=False)
    tipo = Column(String, nullable=False)
    descripcion = Column(String, nullable=False)
    monto = Column(Float, nullable=False)
    fecha_transaccion = Column(Date, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    proyecto = relationship("Proyecto", back_populates="transacciones")
    perfil = relationship("Perfil")
