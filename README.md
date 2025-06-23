> [!note]
> Work in Progress

# Ship Cloudwatch Logs to Grafana Loki using Tailscale

## Goal:

- Idea is to have a Lambda function that processes AWS Cloudwatch logs and writes them to Grafana Loki, leveraging Tailscale for secure communication.
- Better type safety and error handling with Pydantic.

## About

Process AWS Cloudwatch logs using a Lambda function and write the logs to the Grafana Loki log aggregation system.

- [Variant of Cloudwatch Loki Shipper](https://github.com/roobert/cloudwatch-loki-shipper)

## Installation

### Prerequisites

- Poetry
- Python 3.12

### Install dependencies

```bash
poetry install
```

### Configure environment variables

Create a `.env` file in the root directory of the project with the following variables:

```env
make setup
make install
```

### Sample Request

Check that the tailscale operator can receive requests:

```bash
curl -vk -X POST "https://<k8 operator on tailnet>ts.net/loki/api/v1/push"   -H "Content-Type: application/json"   -d '{
    "streams": [
      {
        "stream": {
          "label": "test"
        },
        "values": [
          [ "'"$(date +%s%N)"'", "Test log from Tailscale Ingress" ]
        ]
      }
    ]
  }'
```

<img width="1661" alt="Screen Shot 2025-06-21 at 11 06 59 PM" src="https://github.com/user-attachments/assets/4d223b28-7c50-47c5-bca2-92b0c56d8e47" />

---

### Roadmap

- [x] Clean up cloudwatch logs
- [ ] Add (and fix) test cases
- [x] Add Terraform configuration
- [ ] Documentation
  - setting up Tailscale and K8s operator (include example of manifest)
  - setting up Grafana Loki
  - Building on x86_64 or ARM64
- [ ] Figure out a better build system
- [ ] Write and link blog post
