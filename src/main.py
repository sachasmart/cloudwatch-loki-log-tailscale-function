import base64
import gzip
import json
from enum import Enum
from string import Template
from typing import Any, Dict, List, Optional

import httpx
from structlog import get_logger

from models.cloudwatch import CloudWatchLogsInput, DecodedLogData
from models.common import LogLevel
from models.config import Config

log = get_logger(__name__)


def _is_json(message: str) -> bool:
    return message.strip().startswith("{")


def _decode_log_data(event: CloudWatchLogsInput) -> DecodedLogData:
    compressed_payload = base64.b64decode(event.awslogs["data"])
    decompressed = gzip.decompress(compressed_payload)
    return DecodedLogData.model_validate_json(decompressed)


def _stream_labels(log_labels: List[str], nested_json: dict) -> Dict[str, Any]:
    stream_labels = {}
    for label in log_labels:
        value = nested_json.get(label)
        if value is None:
            log.warning("Stream label not found", label=label, nested_json=nested_json)
            continue
        stream_labels[label] = value
    return stream_labels


def _template_variables(
    log_template_variables: List[str], nested_json: dict
) -> Dict[str, Any]:
    template_variables = {}
    for var in log_template_variables:
        value = nested_json.get(var)
        if value is None:
            log.debug("Template variable not found", variable=var)
            continue
        template_variables[var] = value
    return template_variables


def _template_message(
    nested_json: dict, config: Config, stream_labels: dict
) -> tuple[str, dict]:
    variables = _template_variables(config.log_template_variables, nested_json)
    log.debug("Extracted template variables", variables=variables)
    message = Template(config.log_template).substitute(**variables)
    return message, stream_labels


def _json_message(nested_json: dict, config: Config, stream_labels: dict) -> str:
    if config.log_template:
        message, _ = _template_message(nested_json, config, stream_labels)
    else:
        message = str(nested_json)
    return message


def _loki_push(config: Config, stream_data: dict) -> None:
    log.info("Pushing logs to Loki", loki_endpoint=config.log_loki_endpoint)
    try:
        response = httpx.post(config.log_loki_endpoint, json=stream_data)
        if response.status_code != 204:
            log.error(
                "Failed to push logs to Loki",
                status_code=response.status_code,
                response_body=response.text,
            )
    except httpx.HTTPError as e:
        log.error("HTTP error while pushing logs to Loki", error=str(e))


def _streams(config: Config, cloudwatch_event: dict) -> dict:
    event_model = CloudWatchLogsInput.model_validate(cloudwatch_event)
    log_data = _decode_log_data(event_model)
    streams = {"streams": []}
    base_labels = {"logGroup": log_data.logGroup}

    for entry in log_data.logEvents:
        log.debug("Processing log entry", entry=entry)
        message = entry.message

        if _is_json(message):
            nested_json = json.loads(message)
            stream_labels = base_labels.copy()
            stream_labels.update(_stream_labels(config.log_labels, nested_json))
            log.info("Extracted stream labels", stream_labels=stream_labels)
            formatted_message = _json_message(nested_json, config, stream_labels)
        elif config.log_ignore_non_json:
            log.warning(
                "Non-JSON log entry ignored",
                message=message,
                log_group=log_data.logGroup,
            )
            continue
        else:
            stream_labels = base_labels.copy()
            formatted_message = message

        timestamp = str(entry.timestamp * 1000000)
        stream_value = [timestamp, formatted_message]
        stream = {"stream": stream_labels, "values": [stream_value]}
        streams["streams"].append(stream)
        log.info(
            "Processed log entry",
            stream_value=stream_value,
            stream_labels=stream_labels,
        )

    return streams


def lambda_handler(cloudwatch_event: dict, context: Optional[Any] = None) -> None:
    log.info("Lambda handler invoked", cloudwatch_event=cloudwatch_event)
    config = Config()
    streams = _streams(config, cloudwatch_event)
    _loki_push(config, streams)
    log.info("Lambda processing complete", cloudwatch_event=cloudwatch_event)
