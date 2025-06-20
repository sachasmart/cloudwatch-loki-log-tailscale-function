import base64
import gzip
import json
from pydantic import BaseModel, model_validator


class CloudWatchLogEvent(BaseModel):
    id: str
    timestamp: int
    message: str


class DecodedLogData(BaseModel):
    messageType: str
    owner: str
    logGroup: str
    logStream: str
    subscriptionFilters: list[str]
    logEvents: list[CloudWatchLogEvent]


class CloudWatchLogsData(BaseModel):
    logGroup: str
    logStream: str
    logEvents: list[CloudWatchLogEvent]


class CloudWatchLogsInput(BaseModel):
    awslogs: dict[str, str]
    data: CloudWatchLogsData = None

    @model_validator(mode="before")
    def decode_data_field(cls, values):
        encoded = values.get("awslogs", {}).get("data")
        if not encoded:
            raise ValueError("Missing 'data' in awslogs")

        try:
            compressed_payload = base64.b64decode(encoded)
            decompressed = gzip.decompress(compressed_payload)
            parsed = json.loads(decompressed)
            values["data"] = parsed
        except Exception as e:
            raise ValueError(f"Failed to decode awslogs['data']: {e}")

        return values

    def parsed_data(self) -> CloudWatchLogsData:
        return CloudWatchLogsData.model_validate(self.data)
