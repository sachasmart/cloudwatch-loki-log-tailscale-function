import base64
import gzip
import json
from test.factories.log_event import LogEventFactory, LogEventMessageFactory
from unittest.mock import MagicMock, patch

from pytest import fixture

from src import main
from src.main import (
    _decode_log_data,
    _is_json,
    _json_message,
    _loki_push,
    _stream_labels,
    _streams,
    _template_message,
    _template_variables,
    lambda_handler,
)
from src.models.cloudwatch import CloudWatchLogsInput
from src.models.config import Config


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


def encode_event(event: dict) -> CloudWatchLogsInput:
    compressed = gzip.compress(json.dumps(event).encode())
    encoded = base64.b64encode(compressed).decode()
    return CloudWatchLogsInput(awslogs={"data": encoded})


def test_is_json():
    assert _is_json('{"valid": "json"}') is True
    assert _is_json("not json") is False


def test_decode_log_data():
    log = LogEventMessageFactory.create()
    encoded_input = encode_event(log)
    decoded = _decode_log_data(encoded_input)
    assert decoded.logGroup == log["logGroup"]
    assert len(decoded.logEvents) == 1

    assert hasattr(decoded.logEvents[0], "message")
    assert decoded.logEvents[0].message == log["logEvents"][0]["message"]


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
    log_event = LogEventMessageFactory()
    encoded_input = encode_event(log_event)

    output = _streams(config, encoded_input)
    assert "streams" in output
    assert isinstance(output["streams"], list)
    assert len(output["streams"]) == 1


@patch("src.main._loki_push")
@patch.object(main, "Config")
def test_lambda_handler(mock_config_cls, mock_push: MagicMock, config: Config):
    mock_config_cls.return_value = config
    log = LogEventMessageFactory.create()
    encoded_input = encode_event(log)
    lambda_handler(encoded_input)
    mock_push.assert_called_once()
