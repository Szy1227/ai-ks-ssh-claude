#!/usr/bin/env bash
set -euo pipefail

# Terraform apply 脚本
# 用法:
#   ./tf_apply.sh [--clean] [SSH_PORT]
#   --clean  先 terraform destroy 再 apply（仅需要彻底重装时用，会慢）

DESTROY_FIRST=0
if [[ "${1:-}" == "--clean" ]] || [[ "${1:-}" == "-c" ]]; then
  DESTROY_FIRST=1
  shift
fi

PORT="${1:-22001}"
USERNAME="ks"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

TF_VAR_EXTERNAL_PORT="external_port=${PORT}"
TF_VAR_USERNAME="username=${USERNAME}"

calc_password() {
  local passwd="$1"
  local i
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

PASSWD="$(calc_password "$USERNAME")"
TF_VAR_USER_PASSWORD="user_password=${PASSWD}"

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
    -var "$TF_VAR_USERNAME" \
    -var "$TF_VAR_USER_PASSWORD"
}

tf_destroy() {
  terraform destroy -auto-approve
}

if [[ "$DESTROY_FIRST" -eq 1 ]]; then
  tf_destroy || true
fi
tf_init
tf_apply

HOST_ADDR="$(hostname -I | awk '{print $1}')"

echo ""
echo "===== SSH Login Info ====="
echo "Host: ${HOST_ADDR}"
echo "Port: ${PORT}"
echo "Username: ${USERNAME}"
echo "Password: ${PASSWD}"
echo "Command: ssh ${USERNAME}@${HOST_ADDR} -p ${PORT}"
