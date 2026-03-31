terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.9.0"
    }
  }
}

# 下载慢时可使用本地插件目录初始化:
# terraform init -plugin-dir=./plugins
provider "docker" {}

variable "external_port" {
  type        = number
  default     = 2222
  description = "宿主机映射 SSH 端口"
}

variable "username" {
  type        = string
  default     = "ai-ks"
  description = "SSH 登录用户名"
}

variable "user_uid" {
  type        = number
  description = "容器内用户 UID"
}

variable "user_gid" {
  type        = number
  description = "容器内用户 GID"
}

variable "user_password" {
  type        = string
  default     = "ks"
  description = "SSH 登录密码"
}

variable "stack_suffix" {
  type        = string
  default     = ""
  description = "容器名后缀，多节点时传如 -node-100，避免 Docker 名称冲突"
}

variable "mounts" {
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = optional(bool, false)
  }))
  default     = []
  description = "宿主机目录挂载列表；host_path 以 / 开头为绝对路径，否则相对本模块目录（path.module）"
}

locals {
  resolved_mounts = [
    for m in var.mounts : {
      host_path      = startswith(m.host_path, "/") ? abspath(m.host_path) : abspath("${path.module}/${m.host_path}")
      container_path = m.container_path
      read_only      = m.read_only
    }
  ]
}

resource "docker_image" "ssh_claude_image" {
  name         = "ai-ks-ssh-claude:latest"
  keep_locally = true

  build {
    context    = path.module
    dockerfile = "Dockerfile"
    build_args = {
      USERNAME = var.username
      USERUID  = tostring(var.user_uid)
      USERGID  = tostring(var.user_gid)
    }
  }
}

resource "docker_container" "ssh_claude" {
  name       = "ai-ks-ssh-claude${var.stack_suffix}"
  image      = docker_image.ssh_claude_image.image_id
  restart    = "unless-stopped"
  must_run   = true
  privileged = false

  ports {
    internal = 22
    external = var.external_port
  }

  env = ["USERPASSWD=${var.user_password}"]

  # 挂载 Claude 配置到容器用户家目录
  volumes {
    host_path      = abspath("${path.module}/.claude.json")
    container_path = "/home/${var.username}/.claude.json"
    read_only      = false
  }

  dynamic "volumes" {
    for_each = local.resolved_mounts
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }
}
