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
if gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | grep -q .; then
  echo "active account: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
else
  echo "no gcloud account: run 'gcloud auth login --update-adc'"
fi
if [ -f /root/.config/gcloud/application_default_credentials.json ]; then
  echo "ADC (used by terraform): present"
else
  echo "ADC (used by terraform): missing, run 'gcloud auth application-default login'"
fi
