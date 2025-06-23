# factories.py
import base64
import gzip
import json
from datetime import datetime
from typing import Any

from factory import Dict, Factory, LazyFunction, List, SubFactory
from factory.fuzzy import FuzzyInteger, FuzzyText


class LogEventFactory(Factory):
    id = FuzzyText(length=10)
    timestamp = FuzzyInteger(1609459200, int(datetime.now().timestamp()))
    message = LazyFunction(lambda: json.dumps({"key1": "value1", "key2": "value2"}))

    class Meta:
        model = dict


class LogEventMessageFactory(Factory):
    messageType = "DATA_MESSAGE"
    owner = FuzzyText(length=12)
    logGroup = FuzzyText(length=10)
    logStream = FuzzyText(length=10)
    subscriptionFilters = List(["filter-name"])
    logEvents = List([SubFactory(LogEventFactory)])

    class Meta:
        model = dict
