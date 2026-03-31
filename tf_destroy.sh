#!/usr/bin/env bash
set -euo pipefail

# Terraform destroy 脚本
# 用法:
#   ./tf_destroy.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

die() {
  echo "错误: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "缺少命令: ${cmd}。解决: 请先安装 ${cmd} 并加入 PATH。"
}

detect_current_user_identity() {
  require_cmd id
  local current_uid current_gid
  current_uid="$(id -u 2>/dev/null || true)"
  current_gid="$(id -g 2>/dev/null || true)"

  [[ "$current_uid" =~ ^[0-9]+$ ]] || die "无法获取当前 UID（id -u 结果异常: ${current_uid}）。"
  [[ "$current_gid" =~ ^[0-9]+$ ]] || die "无法获取当前 GID（id -g 结果异常: ${current_gid}）。"
  echo "${current_uid}:${current_gid}"
}

IDENTITY="$(detect_current_user_identity)"
CURRENT_UID="${IDENTITY%%:*}"
CURRENT_GID="${IDENTITY#*:}"

terraform destroy -auto-approve \
  -var "username=ai-ks" \
  -var "user_uid=${CURRENT_UID}" \
  -var "user_gid=${CURRENT_GID}"
