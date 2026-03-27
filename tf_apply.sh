#!/usr/bin/env bash
set -euo pipefail

# Terraform apply 脚本
# 用法:
#   ./tf_apply.sh [SSH_PORT]

PORT="${1:-22001}"
USERNAME="ks"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

TF_VAR_EXTERNAL_PORT="external_port=${PORT}"
TF_VAR_USERNAME="username=${USERNAME}"

calc_password() {
  local passwd="$1"
  local i
  if [[ "$passwd" == "devops" ]]; then
    passwd="devops-${PORT}"
  fi
  if [[ ! "$passwd" =~ user ]]; then
    i=32
    while ((i > 0)); do
      passwd=$(echo -n "${passwd}ai" | md5sum)
      i=$((i - 1))
    done
    passwd="${passwd:0:8}"
  fi
  printf "%s" "$passwd"
}

tf_init() {
  if [ -d "./plugins" ]; then
    terraform init -plugin-dir=./plugins
  else
    terraform init
  fi
}

tf_apply() {
  terraform apply -auto-approve \
    -var "$TF_VAR_EXTERNAL_PORT" \
    -var "$TF_VAR_USERNAME"
}

tf_destroy() {
  terraform destroy -auto-approve
}

# 与现有模板保持一致：apply 前先尝试清理旧资源
tf_destroy || true
tf_init
tf_apply

HOST_ADDR="$(hostname -I | awk '{print $1}')"
PASSWD="$(calc_password "$USERNAME")"

echo ""
echo "===== SSH Login Info ====="
echo "Host: ${HOST_ADDR}"
echo "Port: ${PORT}"
echo "Username: ${USERNAME}"
echo "Password: ${PASSWD}"
echo "Command: ssh ${USERNAME}@${HOST_ADDR} -p ${PORT}"
