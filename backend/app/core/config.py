from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "StackMovi API"
    # Postgres database URL
    DATABASE_URL: str = "postgresql+asyncpg://stackmovi:stackmovi_password@db:5432/stackmovi_db"
    
    # Secret key for JWT
    SECRET_KEY: str = "supersecretkey_change_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days

    class Config:
        env_file = ".env"

settings = Settings()
