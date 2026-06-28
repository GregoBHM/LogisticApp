import asyncio
from app.core.database import engine, Base
from app.models.domain import *  # Import all models to ensure they are registered with Base

async def init_models():
    async with engine.begin() as conn:
        # await conn.run_sync(Base.metadata.drop_all) # Only for dev
        await conn.run_sync(Base.metadata.create_all)

if __name__ == "__main__":
    asyncio.run(init_models())
