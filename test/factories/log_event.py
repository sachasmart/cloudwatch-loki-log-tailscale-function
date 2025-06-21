import json
from datetime import datetime

from factory import Dict, Factory, List, SubFactory
from factory.fuzzy import FuzzyInteger, FuzzyText


class LogEventFactory(Factory):
    class Meta:
        model = dict

    id = FuzzyText(length=10)
    timestamp = FuzzyInteger(1609459200, int(datetime.now().timestamp()))
    message = json.dumps({"key1": "value1", "key2": "value2"})


class LogEventMessageFactory(Factory):
    class Meta:
        model = dict

    messageType = "DATA_MESSAGE"
    owner = FuzzyText(length=12)
    logGroup = FuzzyText(length=10)
    logStream = FuzzyText(length=10)
    subscriptionFilters = List(["filter-name"])
    logEvents = List([SubFactory(LogEventFactory)])
