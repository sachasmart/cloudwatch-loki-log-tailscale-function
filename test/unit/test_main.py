import gzip
import json
import base64
from unittest.mock import MagicMock, patch

from pytest import fixture

from src.models.config import Config
from src.models.cloudwatch import CloudWatchLogsInput
from src.main import (
    _is_json,
    _decode_log_data,
    _stream_labels,
    _template_variables,
    _template_message,
    _json_message,
    _loki_push,
    _streams,
    lambda_handler,
)


# TODO set this to autouse
@fixture
def config():
    config = Config(
        log_template="Yo ${key1}",
        log_template_variables=["key1"],
        loki_endpoint="http://localhost:3100",
        log_labels=[],
    )
    yield config


# TODO make a fixture
sample_log_event = {
    "logGroup": "test-group",
    "logStream": "test-stream",
    "logEvents": [
        {
            "id": "event-id",
            "timestamp": 1628190000,
            "message": json.dumps({"key1": "value1", "key2": "value2"}),
        }
    ],
}


def encode_event(event: dict) -> CloudWatchLogsInput:
    compressed = gzip.compress(json.dumps(event).encode())
    encoded = base64.b64encode(compressed).decode()
    return CloudWatchLogsInput(awslogs={"data": encoded})


def test_is_json():
    assert _is_json('{"valid": "json"}') is True
    assert _is_json("not json") is False


def test_decode_log_data():
    encoded_input = encode_event(sample_log_event)
    decoded = _decode_log_data(encoded_input)
    assert decoded.logGroup == "test-group"
    assert len(decoded.logEvents) == 1
    assert "message" in decoded.logEvents[0]


def test_stream_labels():
    labels = _stream_labels(["key1", "missing"], {"key1": "val1"})
    assert labels == {"key1": "val1"}


def test_template_variables():
    variables = _template_variables(["key1", "key3"], {"key1": "value1", "key2": "x"})
    assert variables == {"key1": "value1"}


def test_template_message(config):
    nested_json = {"key1": "value1"}
    message, labels = _template_message(nested_json, config, {})
    assert message == "Yo value1"


def test_json_message_with_template(config: Config):
    msg = _json_message({"key1": "World"}, config, {})
    assert msg == "Yo World"


def test_json_message_without_template(config: Config):
    msg = _json_message({"k": "v"}, config, {})
    assert msg == "{'k': 'v'}" or msg == '{"k": "v"}'


@patch("src.main.httpx.post")
def test_loki_push_success(mock_post: MagicMock, config: Config):
    mock_post.return_value.status_code = 204
    _loki_push(config, {"streams": []})
    mock_post.assert_called_once()


@patch("src.main.httpx.post")
def test_loki_push_failure(mock_post: MagicMock, config: Config):
    mock_post.return_value.status_code = 400
    mock_post.return_value.text = "Bad Request"
    _loki_push(config, {"streams": []})
    mock_post.assert_called_once()


def test_streams_json_event(config: Config):
    encoded_input = encode_event(sample_log_event)
    output = _streams(config, encoded_input)
    assert "streams" in output
    assert isinstance(output["streams"], list)
    assert len(output["streams"]) == 1


def test_streams_non_json_ignored(config: Config):
    non_json_event = {
        "logGroup": "test-group",
        "logStream": "test-stream",
        "logEvents": [{"id": "1", "timestamp": 123456, "message": "Just text"}],
    }
    encoded_input = encode_event(non_json_event)
    output = _streams(config, encoded_input)
    assert output["streams"] == []


@patch("src.main._loki_push")
def test_lambda_handler(mock_push: MagicMock):
    encoded_input = encode_event(sample_log_event)
    lambda_handler(encoded_input)
    mock_push.assert_called_once()
