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
