#!/usr/bin/env bash
# postCreate for the noxinfra devcontainer. Idempotent; prints no secrets.
set -euo pipefail

ws="$(pwd)"
git config --global --add safe.directory "$ws" 2>/dev/null || true

mkdir -p "${TF_PLUGIN_CACHE_DIR:-/root/.terraform.d/plugin-cache}" /root/.ssh /root/.claude
chmod 700 /root/.ssh

echo "== toolchain =="
terraform version | sed -n 1p
tflint --version | sed -n 1p
gcloud --version | sed -n 1p
if gcloud resource-config --help >/dev/null 2>&1 && command -v config-connector >/dev/null 2>&1; then
  echo "config-connector: ok (gcloud resource-config bulk-export available)"
else
  echo "config-connector: not installed (bulk-export unavailable)"
fi
age --version
sops --version 2>/dev/null | sed -n 1p
yq --version
shellcheck --version | sed -n 2p

echo "== repo hygiene =="
if git -C "$ws" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ws" check-ignore -q "$ws/x.tfstate" || echo "WARN: *.tfstate is NOT gitignored"
else
  echo "not a git repo yet"
fi

echo "== gcloud auth =="
key="${GOOGLE_APPLICATION_CREDENTIALS:-/root/.config/gcloud/claude-agent.json}"
if [ -f "$key" ]; then
  echo "SA key (used by terraform): present"
else
  echo "SA key (used by terraform): missing, copy it to $key (see docs/README.md)"
fi
if gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | grep -q .; then
  echo "active account: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
elif [ -f "$key" ]; then
  gcloud auth activate-service-account --key-file="$key" >/dev/null 2>&1 \
    && echo "activated SA from $key" || echo "WARN: failed to activate SA from $key"
else
  echo "no gcloud account"
fi
# A user account on the shared volume would be readable by the agent: warn about it.
if gcloud auth list --format='value(account)' 2>/dev/null | grep -qv 'gserviceaccount\.com$'; then
  echo "WARN: a user account is logged in inside the container"
fi
if [ -f /root/.config/gcloud/application_default_credentials.json ]; then
  echo "WARN: user ADC present in /root/.config/gcloud (readable by the agent)"
fi
