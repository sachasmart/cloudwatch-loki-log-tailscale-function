> [!note]
> Work in Progress

# Ship Cloudwatch Logs to Grafana Loki using Tailscale
![cloudwatch_shipper](https://github.com/user-attachments/assets/498816e4-9e83-4230-9fe7-53c4e1330a1b)


## Overview:
My goal was to use [Grafana Loki](https://grafana.com/oss/loki/) for aggregating logs across various distributed systems. I found CloudWatch challenging due to its limited query capabilities. Loki, with its powerful [LogQL](https://grafana.com/docs/loki/latest/query/), offers more advanced and flexible querying options, allowing for deeper insights into log data. I noticed a lack of well-maintained, readily available solutions that addressed these specific needs.

#### Project Components and Deployment
This project generates a container image artifact designed for deployment as a Lambda function. Before deployment, this image must be pushed to an Elastic Container Registry (ECR), as AWS Lambda doesn't support external container registries.

The project also provides all the necessary [Terraform](https://developer.hashicorp.com/terraform) configuration to deploy this Lambda function against an existing CloudWatch log group. If no log group is configured, it will automatically create an event-router, which the container will then use to push logs to your Loki instance.

#### Secure Data Transfer with Tailscale
[Tailscale](https://tailscale.com/) is a central component of this project, serving as the secure backbone for shipping log data. It enables secure ingress into or egress from your AWS environment, ensuring that your log data is transferred safely and reliably.

## Develop

### Prerequisites

- Poetry
- Python 3.12
- Docker
- [Terraform](https://developer.hashicorp.com/terraform)
- AWS Account
- [Tailscale](https://tailscale.com/) account

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

## Build Steps
! TODO !
In the meantime, take the [container image](https://github.com/sachasmart/cloudwatch-loki-log-tailscale-function/pkgs/container/cloudwatch-loki-log-tailscale-function) and push it to your AWS ECR. 

---

### Roadmap

- [x] Clean up cloudwatch logs
- [x] Add (and fix) test cases
- [ ] Continue to add more test cases
- [x] Add Terraform configuration
- [ ] Documentation
  - setting up Tailscale and K8s operator (include example of manifest)
  - setting up Grafana Loki
  - Building on x86_64 or ARM64
- [x] Figure out a better build system
- [ ] Write and link blog post
