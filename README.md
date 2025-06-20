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

---

### Roadmap

- [ ] Clean up cloudwatch logs
- [ ] Add test cases
- [ ] Add Terraform configuration
