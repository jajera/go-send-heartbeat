FROM docker.io/golang:1.22.4-bullseye

RUN apt-get update -y \
  && export DEBIAN_FRONTEND=noninteractive

ENV GO111MODULE=on

RUN go install golang.org/x/tools/gopls@v0.12.3 \
  && go install golang.org/x/telemetry/cmd/gotelemetry@v0.0.0-20240614130327-d92499019833
