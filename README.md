# ai-ks-ssh-claude

基于 **Ubuntu 22.04** 的轻量 SSH 容器镜像，由 **Terraform** 管理：映射宿主机端口、可选挂载工作目录，用于远程/容器内开发（例如挂载前后端 `code`）。

## 前置条件

- Terraform、Docker
- Provider：`kreuzwerker/docker` 3.9.0
- 首次 `apply` 会 **build** 本目录 `Dockerfile` 生成镜像 `ai-ks-ssh-claude:latest`

## 快速开始

### 与 ai-ks-design 编排（推荐）

由 [ai-ks-design](https://github.com/Szy1227/ai-ks-design) 的 `provision.sh` 生成 `ssh.auto.tfvars`（含 `external_port`、`mounts`），在本目录执行：

```bash
chmod +x tf_apply.sh tf_destroy.sh
./tf_apply.sh
```

### 单独使用（无 tfvars）

```bash
./tf_apply.sh 22001    # 仅 SSH 端口；无额外挂载（mounts=[]）
```

`--clean` / `-c`：先 `destroy` 再 `apply`。

### 登录信息

`tf_apply.sh` 结束时会打印 **Host / Port / Username / Password**。默认用户名为 `ks`，也可设置环境变量 `SSH_CLAUDE_USERNAME`；密码由脚本根据用户名派生（见脚本内 `calc_password`）。

### 插件目录

支持 `TF_INIT_PLUGIN_DIR`，或自动检测 `../../ai-ks-tools/terraform/plugins`（相对 `workspace/node-<N>/本仓库`）。

## Terraform 变量（摘要）

| 变量 | 说明 |
|------|------|
| `external_port` | 宿主机 SSH 端口 |
| `username` / `user_uid` / `user_password` | 容器内用户（密码常由 `tf_apply.sh` 注入） |
| `mounts` | 宿主机路径 → 容器路径列表；相对路径相对模块目录 |

`ssh.auto.tfvars` 已列入 `.gitignore`，勿提交密钥或环境相关配置。

## 项目结构

```
.
├── main.tf              # build 镜像 + docker_container
├── Dockerfile           # openssh-server + 非 root 用户
├── container_start.sh   # 入口：chpasswd + sshd -D
├── tf_apply.sh
└── tf_destroy.sh
```

## 相关仓库

- [ai-ks-design](https://github.com/Szy1227/ai-ks-design)
- [ai-ks-vue](https://github.com/Szy1227/ai-ks-vue)
- [ai-ks-fastapi](https://github.com/Szy1227/ai-ks-fastapi)
