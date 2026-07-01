import asyncio
from datetime import datetime, timedelta
import random
import uuid
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.domain import Cuenta, Venta, Perfil, Abono

async def seed_ventas():
    async with AsyncSessionLocal() as db:
        # Get the first cuenta
        result = await db.execute(select(Cuenta).limit(1))
        cuenta = result.scalar_one_or_none()
        
        if not cuenta:
            print('No hay cuentas creadas en la base de datos.')
            return

        perfil_id = cuenta.creado_por
        
        print(f'Usando cuenta: {cuenta.nombre}')
        
        ventas_a_insertar = []
        abonos_a_insertar = []
        nombres = ['Juan', 'Maria', 'Carlos', 'Ana', 'Pedro', 'Lucia', 'Jorge', 'Marta', 'Luis', 'Elena', 'Jugueria', 'Bodega']
        
        # 60 días atrás (2 meses)
        fecha_inicio = datetime.utcnow() - timedelta(days=60)
        
        for i in range(40): # 40 ventas
            dias_sumar = random.randint(0, 60)
            fecha_venta = fecha_inicio + timedelta(days=dias_sumar)
            
            kilos = round(random.uniform(10.0, 100.0), 2)
            precio = round(random.uniform(3.5, 5.0), 2)
            total = round(kilos * precio, 2)
            
            venta_id = str(uuid.uuid4())
            venta = Venta(
                id=venta_id,
                cuenta_id=cuenta.id,
                registrado_por=perfil_id,
                cliente=random.choice(nombres),
                kilos_vendidos=kilos,
                precio_por_kg=precio,
                total_venta=total,
                fecha_venta=fecha_venta.date(),
                created_at=fecha_venta,
                updated_at=fecha_venta
            )
            ventas_a_insertar.append(venta)

            # Para que la venta aparezca como cancelada, agregamos un abono por el total
            abono = Abono(
                venta_id=venta_id,
                registrado_por=perfil_id,
                monto=total,
                fecha_abono=fecha_venta.date(),
                created_at=fecha_venta
            )
            abonos_a_insertar.append(abono)
            
        db.add_all(ventas_a_insertar)
        db.add_all(abonos_a_insertar)
        
        # Descontar kilos y sumar inversión a la cuenta
        cuenta.kilos_totales -= sum(v.kilos_vendidos for v in ventas_a_insertar)
        await db.commit()
        
        print(f'¡Se han insertado {len(ventas_a_insertar)} ventas aleatorias (y abonos) desde hace 2 meses exitosamente!')

if __name__ == '__main__':
    asyncio.run(seed_ventas())
