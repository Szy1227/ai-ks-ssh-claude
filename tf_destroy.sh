#!/usr/bin/env bash
set -euo pipefail

# Terraform destroy 脚本
# 用法:
#   ./tf_destroy.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

terraform destroy -auto-approve
