"""Validated backend-only SQL configuration."""
from pathlib import Path
import os
from typing import Literal, Self

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

ENV_FILE = Path(os.environ.get("PPE_ENV_FILE", str(Path(__file__).resolve().parents[2] / ".env")))


class SqlSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="SQL_",
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="forbid",
        hide_input_in_errors=True,
        frozen=True,
    )

    server: str = Field(min_length=1)
    database: str = Field(min_length=1, max_length=128)
    auth_mode: Literal["windows", "sql"] = "windows"
    driver: str = "ODBC Driver 18 for SQL Server"
    username: str = Field(default="", repr=False)
    password: SecretStr = Field(default=SecretStr(""), repr=False)
    encrypt: bool = True
    trust_server_certificate: bool = False
    login_timeout: int = Field(default=5, ge=1, le=60)
    query_timeout: int = Field(default=10, ge=1, le=300)

    @field_validator("server", "database", "driver")
    @classmethod
    def validate_names(cls, value: str) -> str:
        if not value.strip() or "\x00" in value:
            raise ValueError("Debe ser un nombre no vacio y sin caracteres nulos.")
        return value

    @model_validator(mode="after")
    def validate_authentication(self) -> Self:
        password = self.password.get_secret_value()
        if "\x00" in self.username or "\x00" in password:
            raise ValueError("Las credenciales no pueden contener caracteres nulos.")
        if self.auth_mode == "sql" and (not self.username.strip() or not password):
            raise ValueError("La autenticacion SQL requiere usuario y contrasena.")
        if self.auth_mode == "windows" and (self.username or password):
            raise ValueError("Con autenticacion Windows, deje usuario y contrasena vacios.")
        return self
