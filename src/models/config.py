import os
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator, root_validator
from typing import Optional
from pydantic_settings import SettingsConfigDict
from structlog import get_logger

logger = get_logger()


class TailscaleConfig(BaseModel):
    tailscale_auth_key: Optional[str] = Field(
        description="Tailscale auth key for authentication",
    )
    model_config = SettingsConfigDict(env_prefix="TAILSCALE_")


class Config(BaseModel):
    loki_endpoint: str = Field(
        description="Loki endpoint URL for pushing logs",
    )
    log_labels: List[str] = Field()
    log_template: str = Field(
        default="$message",
        description="Template for log messages, using Python string formatting syntax",
    )
    log_template_variables: List[str] = Field(
        default_factory=lambda: os.getenv("LOG_TEMPLATE_VARIABLES", "message").split(
            ","
        )
    )
    log_ignore_non_json: bool = os.getenv("LOG_IGNORE_NON_JSON", "false").lower() in [
        "true",
        "1",
        "yes",
    ]

    @model_validator(mode="before")
    def warn_on_template_without_labels(cls, values):
        if values.get("log_template") and not values.get("log_labels"):
            logger.warning(
                "Log template is set but no log labels are provided - "
                "This may lead to unexpected behavior"
            )

        return values
