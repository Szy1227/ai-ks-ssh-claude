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
  default     = "ks"
  description = "SSH 登录用户名"
}

variable "user_uid" {
  type        = number
  default     = 1000
  description = "容器内用户 UID"
}

variable "user_password" {
  type        = string
  default     = "ks"
  description = "SSH 登录密码"
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
    }
  }
}

resource "docker_container" "ssh_claude" {
  name       = "ai-ks-ssh-claude-${var.external_port}"
  image      = docker_image.ssh_claude_image.image_id
  restart    = "unless-stopped"
  must_run   = true
  privileged = false

  ports {
    internal = 22
    external = var.external_port
  }

  env = ["USERPASSWD=${var.user_password}"]
}
