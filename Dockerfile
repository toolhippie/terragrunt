FROM webhippie/golang:1.17 as build

# renovate: datasource=github-releases depName=gruntwork-io/terragrunt
ENV TERRAGRUNT_VERSION=0.36.6

# renovate: datasource=github-releases depName=hashicorp/terraform
ENV TERRAFORM_VERSION=1.1.7

ARG TARGETARCH

RUN apk add -U unzip && \
  case "${TARGETARCH}" in \
    'amd64') \
      curl -sSLo- /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip; \
      ;; \
    'arm64') \
      curl -sSLo- /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm64.zip; \
      ;; \
    'arm') \
      curl -sSLo- /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm.zip; \
      ;; \
    *) echo >&2 "error: unsupported architecture '${TARGETARCH}'"; exit 1 ;; \
  esac && \
  cd /tmp && \
  unzip terraform.zip

RUN git clone -b v${TERRAGRUNT_VERSION} https://github.com/gruntwork-io/terragrunt.git /srv/app/src && \
  cd /srv/app/src && \
  GO111MODULE=on go install -ldflags "-X main.version=$(git describe --tags --abbrev=12)" .

FROM webhippie/alpine:latest
ENTRYPOINT [""]

RUN apk update && \
  apk upgrade && \
  apk add gnupg && \
  rm -rf /var/cache/apk/*

COPY --from=build /srv/app/bin/terragrunt /usr/bin/
COPY --from=build /tmp/terraform /usr/bin/