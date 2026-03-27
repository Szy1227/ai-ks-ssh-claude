#!/usr/bin/env bash
set -euo pipefail

# Terraform apply 脚本
# 用法:
#   存在 ssh.auto.tfvars 时:
#     ./tf_apply.sh [--clean]
#     （external_port、mounts 由 ssh.auto.tfvars 提供）
#   否则:
#     ./tf_apply.sh [--clean] [SSH_PORT]
#   --clean  先 terraform destroy 再 apply（仅需要彻底重装时用，会慢）

DESTROY_FIRST=0
if [[ "${1:-}" == "--clean" ]] || [[ "${1:-}" == "-c" ]]; then
  DESTROY_FIRST=1
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

USERNAME="${SSH_CLAUDE_USERNAME:-ks}"

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

read_external_port_from_tfvars() {
  local line
  line=$(grep -E '^external_port[[:space:]]*=' ssh.auto.tfvars | head -1) || true
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  # external_port = 22100 或 external_port=22100
  sed -E 's/^external_port[[:space:]]*=[[:space:]]*//' <<<"$line" | tr -d ' "'
}

VAR_FILE_ARGS=()
EXTRA_VAR_ARGS=()
SSH_PORT_DISPLAY=""

if [[ -f ssh.auto.tfvars ]]; then
  VAR_FILE_ARGS=( -var-file=ssh.auto.tfvars )
  SSH_PORT_DISPLAY="$(read_external_port_from_tfvars)"
  if [[ -z "$SSH_PORT_DISPLAY" ]]; then
    echo "错误: ssh.auto.tfvars 中缺少 external_port" >&2
    exit 1
  fi
else
  PORT="${1:-22001}"
  SSH_PORT_DISPLAY="$PORT"
  EXTRA_VAR_ARGS=( -var "external_port=${PORT}" -var 'mounts=[]' )
fi

tf_init() {
  # 插件目录优先级: 项目 ./plugins > 环境变量 TF_INIT_PLUGIN_DIR > workspace/plugins（与 node-<N> 同级）> ~/.terraform-plugins
  local plugin_dir=""
  if [ -d "./plugins" ]; then
    plugin_dir="./plugins"
  elif [ -n "${TF_INIT_PLUGIN_DIR:-}" ] && [ -d "${TF_INIT_PLUGIN_DIR}" ]; then
    plugin_dir="${TF_INIT_PLUGIN_DIR}"
  elif [ -d "${SCRIPT_DIR}/../../plugins" ]; then
    plugin_dir="$(cd "${SCRIPT_DIR}/../.." && pwd)/plugins"
  elif [ -d "${HOME}/.terraform-plugins" ]; then
    plugin_dir="${HOME}/.terraform-plugins"
  fi
  if [ -n "$plugin_dir" ]; then
    terraform init -plugin-dir="$plugin_dir"
  else
    terraform init
  fi
}

tf_apply() {
  terraform apply -auto-approve \
    "${VAR_FILE_ARGS[@]}" \
    "${EXTRA_VAR_ARGS[@]}" \
    -var "username=${USERNAME}" \
    -var "user_password=${PASSWD}"
}

if [[ "$DESTROY_FIRST" -eq 1 ]]; then
  if [[ ${#VAR_FILE_ARGS[@]} -gt 0 ]]; then
    terraform destroy -auto-approve \
      "${VAR_FILE_ARGS[@]}" \
      -var "username=${USERNAME}" \
      -var "user_password=${PASSWD}" || true
  else
    terraform destroy -auto-approve \
      -var "external_port=${SSH_PORT_DISPLAY}" \
      -var 'mounts=[]' \
      -var "username=${USERNAME}" \
      -var "user_password=${PASSWD}" || true
  fi
fi
tf_init
tf_apply

HOST_ADDR="$(hostname -I | awk '{print $1}')"

echo ""
echo "===== SSH Login Info ====="
echo "Host: ${HOST_ADDR}"
echo "Port: ${SSH_PORT_DISPLAY}"
echo "Username: ${USERNAME}"
echo "Password: ${PASSWD}"
echo "Command: ssh ${USERNAME}@${HOST_ADDR} -p ${SSH_PORT_DISPLAY}"
