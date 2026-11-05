# Operator workstation for noxinfra: Terraform description of all personal cloud resources.
# Everything needed (Terraform, tflint, gcloud + bulk-export, sops/age, linters) is pinned
# here so the result is the same on any machine.
FROM debian:bookworm-slim

ARG TARGETARCH
ARG TERRAFORM_VERSION=1.17.1
ARG TFLINT_VERSION=0.65.0
ARG AGE_VERSION=1.3.2
ARG SOPS_VERSION=3.13.3
ARG YQ_VERSION=4.54.1

ENV DEBIAN_FRONTEND=noninteractive

# Base OS tooling + Google Cloud CLI apt repo.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git make jq unzip less vim-tiny bash-completion \
      openssh-client shellcheck dnsutils procps python3; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-cloud-cli; \
    rm -rf /var/lib/apt/lists/*

# Config Connector CLI: powers `gcloud resource-config bulk-export --resource-format=terraform`,
# handy for generating a first draft of HCL for existing resources. Not built for every
# arch, so a missing package is a warning, not a build failure.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-cloud-cli-config-connector \
      || echo "WARN: google-cloud-cli-config-connector not available for ${TARGETARCH}"; \
    rm -rf /var/lib/apt/lists/*

# Terraform (checksum-verified against HashiCorp SHA256SUMS).
RUN set -eux; cd /tmp; \
    f="terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${f}"; \
    curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"; \
    grep " ${f}\$" "terraform_${TERRAFORM_VERSION}_SHA256SUMS" | sha256sum -c -; \
    unzip -o "$f" terraform -d /usr/local/bin; rm -f /tmp/terraform_*

# tflint (checksum-verified).
RUN set -eux; cd /tmp; \
    f="tflint_linux_${TARGETARCH}.zip"; base="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}"; \
    curl -fsSLO "${base}/${f}"; curl -fsSLO "${base}/checksums.txt"; \
    grep " ${f}\$" checksums.txt | sha256sum -c -; \
    unzip -o "$f" tflint -d /usr/local/bin; rm -f /tmp/tflint_* /tmp/checksums.txt

# sops (checksum-verified) + age: for any secrets that end up next to the Terraform code.
RUN set -eux; cd /tmp; \
    f="sops-v${SOPS_VERSION}.linux.${TARGETARCH}"; base="https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}"; \
    curl -fsSLO "${base}/${f}"; curl -fsSLO "${base}/sops-v${SOPS_VERSION}.checksums.txt"; \
    grep " ${f}\$" "sops-v${SOPS_VERSION}.checksums.txt" | sha256sum -c -; \
    install -m 0755 "$f" /usr/local/bin/sops; rm -f /tmp/sops-*

RUN set -eux; cd /tmp; \
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz; \
    install -m 0755 age/age age/age-keygen /usr/local/bin/; rm -rf /tmp/age

# yq.
RUN set -eux; \
    curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}"; \
    chmod 0755 /usr/local/bin/yq

# Shell niceties (land in /root and get copied into the fresh home volume on first start).
RUN set -eux; \
    terraform -install-autocomplete || true; \
    echo 'source /usr/share/google-cloud-sdk/completion.bash.inc 2>/dev/null || true' >> /root/.bashrc; \
    echo 'alias tf=terraform' >> /root/.bashrc

WORKDIR /workspace
CMD ["sleep", "infinity"]
