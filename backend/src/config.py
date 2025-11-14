"""Application configuration management."""

import os
from enum import StrEnum
from functools import lru_cache
from typing import ClassVar

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class FlaskEnv(StrEnum):
    """Enum for Flask environment setting."""

    PRODUCTION = "PRODUCTION"
    DEVELOPMENT = "DEVELOPMENT"


class DBSettings(BaseSettings):
    """Base settings class.

    PARAMETERS:
        DB_HOST (str): `localhost`.
        DB_NAME (str): The database name.
        DB_USER (str): The database username.
        DB_PASSWORD (str): The database password.
        FLASK_ENV (FlaskEnv[Enum]): The Flask environment type.
    """

    _registry: ClassVar[dict[FlaskEnv, type["DBSettings"]]] = {}
    model_config = SettingsConfigDict(env_parse_enums=True)

    DB_HOST: str = Field(default="localhost", validation_alias="DB_HOST")
    DB_NAME: str = Field(default=...)
    DB_USER: str = Field(default=...)
    DB_PASSWORD: str = Field(default=...)
    FLASK_ENV: FlaskEnv = Field(
        default=FlaskEnv.PRODUCTION, validation_alias="FLASK_ENV"
    )

    def __init_subclass__(cls, **kwargs) -> None:
        """Register subclasses based on FLASK_ENV value."""
        super().__init_subclass__(**kwargs)
        DBSettings._registry[cls.FLASK_ENV] = cls


class DevDBSettings(DBSettings):
    """Settings for development."""

    model_config = SettingsConfigDict(env_prefix="LOCAL_")
    FLASK_ENV: FlaskEnv = FlaskEnv.DEVELOPMENT


class ProductionDBSettings(DBSettings):
    """Settings for production."""

    model_config = SettingsConfigDict(env_prefix="CPANEL_")
    FLASK_ENV: FlaskEnv = FlaskEnv.PRODUCTION


@lru_cache
def get_db_settings() -> DBSettings:
    """Factory function for initializing Settings subclass."""
    try:
        env = FlaskEnv[os.environ["FLASK_ENV"]]
        settings_class = DBSettings._registry[env]
        return settings_class()
    except KeyError:
        return ProductionDBSettings()
