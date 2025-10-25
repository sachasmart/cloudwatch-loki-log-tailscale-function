import os

import requests

api_key = os.environ["TAILSCALE_API_KEY"]
tailnet = os.environ["TAILSCALE_TAILNET"]
DEVICE_PREFIXES_TO_DELETE = ["cloudwatch-loki-shipper", ""]

response = requests.get(
    f"https://api.tailscale.com/api/v2/tailnet/{tailnet}/devices", auth=(api_key, "")
)

response.raise_for_status()
devices = response.json()["devices"]


devices_to_delete = [
    device
    for device in devices
    if device.get("name", "").startswith(tuple(DEVICE_PREFIXES_TO_DELETE))
]

for device in devices_to_delete:
    response = requests.delete(
        f"https://api.tailscale.com/api/v2/device/{device['id']}",
        auth=(api_key, ""),
    )

    response.raise_for_status()
    print(f"Deleted device: {device['name']} (ID: {device['id']})")
