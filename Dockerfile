FROM public.ecr.aws/lambda/provided:al2 AS builder
WORKDIR /app
COPY bootstrap ./

FROM public.ecr.aws/lambda/provided:al2
COPY --from=builder /app/bootstrap /var/runtime/bootstrap

COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /var/runtime/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /var/runtime/tailscale
RUN mkdir -p /var/run && ln -s /tmp/tailscale /var/run/tailscale && \
    mkdir -p /var/cache && ln -s /tmp/tailscale /var/cache/tailscale && \
    mkdir -p /var/lib && ln -s /tmp/tailscale /var/lib/tailscale && \
    mkdir -p /var/task && ln -s /tmp/tailscale /var/task/tailscale

# Install the aws-lambda-ric package for custom runtime
RUN pip install awslambdaric

COPY publish/ /var/task/
RUN chmod +x /var/runtime/bootstrap

ENTRYPOINT ["/var/runtime/bootstrap"]
