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

class ProyectoInvite(BaseModel):
    email: EmailStr

class ProyectoResponse(BaseModel):
    id: str
    nombre: str
    descripcion: Optional[str] = None
    moneda_simbolo: str
    moneda_codigo: str
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
    cantidad_unidades: float
    kg_por_unidad: float
    inversion_total: float
    precio_venta_kg: float
    fecha_apertura: date

class CuentaResponse(BaseModel):
    id: str
    proyecto_id: str
    nombre: str
    producto: str
    tipo_unidad: str
    cantidad_unidades: float
    kg_por_unidad: float
    kilos_totales: float
    inversion_total: float
    precio_venta_kg: float
    estado: str
    creado_por: str
    cerrado_por: Optional[str] = None
    fecha_apertura: date
    fecha_cierre: Optional[date] = None
    created_at: datetime
    updated_at: datetime
    
    # Campos calculados a retornar
    ingresos_brutos: float = 0.0
    kilos_vendidos: float = 0.0
    kilos_restantes: float = 0.0
    total_cobrado: float = 0.0
    total_gastos: float = 0.0
    ganancia_real: float = 0.0

    class Config:
        from_attributes = True

class VentaCreate(BaseModel):
    cuenta_id: str
    cliente: str
    kilos_vendidos: float
    precio_por_kg: float
    fecha_venta: date
    monto_inicial_pagado: Optional[float] = None
    total_venta: Optional[float] = None

class VentaResponse(BaseModel):
    id: str
    cuenta_id: str
    registrado_por: str
    registrado_por_nombre: Optional[str] = None
    cliente: str
    kilos_vendidos: float
    precio_por_kg: float
    total_venta: float
    fecha_venta: date
    created_at: datetime
    
    # Calculados
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
    monto: float
    fecha_gasto: date

class GastoResponse(BaseModel):
    id: str
    cuenta_id: str
    registrado_por: str
    registrado_por_nombre: Optional[str] = None
    descripcion: str
    monto: float
    fecha_gasto: date
    created_at: datetime

    class Config:
        from_attributes = True

class TransaccionGeneralCreate(BaseModel):
    proyecto_id: str
    tipo: str # 'ingreso' or 'gasto'
    descripcion: str
    monto: float
    fecha_transaccion: date

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

# --- UPDATE SCHEMAS ---

class ProyectoUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None

class CuentaUpdate(BaseModel):
    nombre: Optional[str] = None
    producto: Optional[str] = None
    tipo_unidad: Optional[str] = None
    cantidad_unidades: Optional[float] = None
    kg_por_unidad: Optional[float] = None
    inversion_total: Optional[float] = None
    precio_venta_kg: Optional[float] = None
    fecha_apertura: Optional[date] = None

class VentaUpdate(BaseModel):
    cliente: Optional[str] = None
    kilos_vendidos: Optional[float] = None
    precio_por_kg: Optional[float] = None
    fecha_venta: Optional[date] = None

class AbonoUpdate(BaseModel):
    monto: Optional[float] = None
    nota: Optional[str] = None
    fecha_abono: Optional[date] = None

class GastoUpdate(BaseModel):
    descripcion: Optional[str] = None
    monto: Optional[float] = None
    fecha_gasto: Optional[date] = None

# --- REPORTE SCHEMAS ---

class VentaReporteItem(VentaResponse):
    cuenta_nombre: str

class GastoReporteItem(GastoResponse):
    cuenta_nombre: str

class AbonoReporteItem(AbonoResponse):
    cuenta_nombre: str
    cliente: Optional[str] = None

class ProyectoReporteResponse(BaseModel):
    proyecto_id: str
    proyecto_nombre: str
    inversion_total: float
    ingresos_brutos: float
    total_cobrado: float
    total_gastos: float
    ganancia_real: float
    kilos_totales: float
    kilos_vendidos: float
    kilos_restantes: float
    ventas: List[VentaReporteItem]
    gastos: List[GastoReporteItem]
    abonos: List[AbonoReporteItem]
