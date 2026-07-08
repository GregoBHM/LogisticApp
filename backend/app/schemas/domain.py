from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime, date

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    nombre: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class PerfilResponse(BaseModel):
    id: str
    nombre: str
    email: str
    created_at: datetime

    class Config:
        from_attributes = True

class ProyectoCreate(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    moneda_simbolo: str
    moneda_codigo: str
    producto_default: Optional[str] = None
    tipo_unidad_default: Optional[str] = None
    unidad_medida_default: Optional[str] = None
    cantidad_por_unidad_default: Optional[float] = None

class ProyectoInvite(BaseModel):
    email: EmailStr

class ProyectoMiembroUpdate(BaseModel):
    rol: str

class EmpaqueCreate(BaseModel):
    nombre: str
    unidad_medida: str
    cantidad_por_unidad: float

class EmpaqueResponse(BaseModel):
    id: str
    proyecto_id: str
    nombre: str
    unidad_medida: str
    cantidad_por_unidad: float
    created_at: datetime

    class Config:
        from_attributes = True

class ProyectoResponse(BaseModel):
    id: str
    nombre: str
    descripcion: Optional[str] = None
    moneda_simbolo: str
    moneda_codigo: str
    producto_default: Optional[str] = None
    tipo_unidad_default: Optional[str] = None
    unidad_medida_default: Optional[str] = None
    cantidad_por_unidad_default: Optional[float] = None
    creado_por: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class CuentaCreate(BaseModel):
    proyecto_id: str
    nombre: str
    producto: str
    tipo_unidad: str
    unidad_medida: str = "und"
    cantidad_unidades: float
    cantidad_por_unidad: float = 1.0
    inversion_total: float
    precio_unitario: float
    fecha_apertura: date

class CuentaResponse(BaseModel):
    id: str
    proyecto_id: str
    nombre: str
    producto: str
    tipo_unidad: str
    unidad_medida: str
    cantidad_unidades: float
    cantidad_por_unidad: float
    stock_total: float
    inversion_total: float
    precio_unitario: float
    estado: str
    creado_por: str
    cerrado_por: Optional[str] = None
    fecha_apertura: date
    fecha_cierre: Optional[date] = None
    created_at: datetime
    updated_at: datetime

    cantidad_vendida: float = 0.0
    stock_restante: float = 0.0
    ingresos_brutos: float = 0.0
    total_cobrado: float = 0.0
    total_gastos: float = 0.0
    ganancia_real: float = 0.0

    class Config:
        from_attributes = True

class VentaCreate(BaseModel):
    cuenta_id: str
    cliente: str
    precio_unitario: float
    fecha_venta: date
    cantidad_vendida: Optional[float] = None
    monto_inicial_pagado: Optional[float] = None
    total_venta: Optional[float] = None

class VentaResponse(BaseModel):
    id: str
    cuenta_id: str
    registrado_por: str
    registrado_por_nombre: Optional[str] = None
    cliente: str
    cantidad_vendida: float
    precio_unitario: float
    total_venta: float
    fecha_venta: date
    created_at: datetime

    total_abonado: float = 0.0
    saldo_pendiente: float = 0.0
    estado_pago: str = "Pendiente"

    class Config:
        from_attributes = True

class AbonoCreate(BaseModel):
    venta_id: str
    monto: float
    fecha_abono: date
    nota: Optional[str] = None

class AbonoResponse(BaseModel):
    id: str
    venta_id: str
    registrado_por: str
    monto: float
    fecha_abono: date
    nota: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AbonoDetalleResponse(AbonoResponse):
    cliente: str
    registrado_por_nombre: Optional[str] = None

class GastoCreate(BaseModel):
    cuenta_id: str
    descripcion: str
    categoria: Optional[str] = None
    monto: float
    fecha_gasto: date

class GastoResponse(BaseModel):
    id: str
    cuenta_id: str
    registrado_por: str
    registrado_por_nombre: Optional[str] = None
    descripcion: str
    categoria: Optional[str] = None
    monto: float
    fecha_gasto: date
    created_at: datetime

    class Config:
        from_attributes = True

class TransaccionGeneralCreate(BaseModel):
    proyecto_id: str
    tipo: str
    descripcion: str
    monto: float
    fecha_transaccion: date

class TransaccionGeneralUpdate(BaseModel):
    tipo: Optional[str] = None
    descripcion: Optional[str] = None
    monto: Optional[float] = None
    fecha_transaccion: Optional[date] = None

class TransaccionGeneralResponse(BaseModel):
    id: str
    proyecto_id: str
    registrado_por: str
    registrado_por_nombre: Optional[str] = None
    tipo: str
    descripcion: str
    monto: float
    fecha_transaccion: date
    created_at: datetime

    class Config:
        from_attributes = True

class ProyectoUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    producto_default: Optional[str] = None
    tipo_unidad_default: Optional[str] = None
    unidad_medida_default: Optional[str] = None
    cantidad_por_unidad_default: Optional[float] = None

class CuentaUpdate(BaseModel):
    nombre: Optional[str] = None
    producto: Optional[str] = None
    tipo_unidad: Optional[str] = None
    unidad_medida: Optional[str] = None
    cantidad_unidades: Optional[float] = None
    cantidad_por_unidad: Optional[float] = None
    inversion_total: Optional[float] = None
    precio_unitario: Optional[float] = None
    fecha_apertura: Optional[date] = None

class VentaUpdate(BaseModel):
    cliente: Optional[str] = None
    cantidad_vendida: Optional[float] = None
    precio_unitario: Optional[float] = None
    total_venta: Optional[float] = None
    fecha_venta: Optional[date] = None

class AbonoUpdate(BaseModel):
    monto: Optional[float] = None
    nota: Optional[str] = None
    fecha_abono: Optional[date] = None

class GastoUpdate(BaseModel):
    descripcion: Optional[str] = None
    categoria: Optional[str] = None
    monto: Optional[float] = None
    fecha_gasto: Optional[date] = None

class VentaReporteItem(VentaResponse):
    cuenta_nombre: str

class GastoReporteItem(GastoResponse):
    cuenta_nombre: str

class AbonoReporteItem(AbonoResponse):
    cuenta_nombre: str
    cliente: Optional[str] = None
    registrado_por_nombre: Optional[str] = None

class ProyectoReporteResponse(BaseModel):
    proyecto_id: str
    proyecto_nombre: str
    inversion_total: float
    ingresos_brutos: float
    total_cobrado: float
    total_gastos: float
    ganancia_real: float
    stock_total: float
    cantidad_vendida: float
    stock_restante: float
    ventas: List[VentaReporteItem]
    gastos: List[GastoReporteItem]
    abonos: List[AbonoReporteItem]
