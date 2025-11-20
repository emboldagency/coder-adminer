terraform {
  required_version = ">= 1.0"
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0"
    }
  }
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  user_id        = try(data.coder_workspace_owner.me.id, "unknown")
  user_username  = try(data.coder_workspace_owner.me.name, "unknown")
  workspace_id   = try(data.coder_workspace_owner.me.id, "unknown")
  workspace_name = try(data.coder_workspace.me.name, "unknown")
}

resource "docker_image" "adminer" {
  name          = data.docker_registry_image.adminer.name
  pull_triggers = [data.docker_registry_image.adminer.sha256_digest]
  keep_locally  = true
}

resource "docker_container" "adminer" {
  count        = data.coder_workspace.me.start_count
  name         = "${var.resource_name_base}-adminer"
  image        = docker_image.adminer.name
  hostname     = "adminer"
  network_mode = var.docker_network_name

  labels {
    label = "coder.owner"
    value = local.user_username
  }

  labels {
    label = "coder.owner_id"
    value = local.user_id
  }

  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
}

data "docker_registry_image" "adminer" {
  name = "adminer:latest"
}

resource "coder_app" "adminer" {
  count        = data.coder_workspace.me.start_count
  agent_id     = var.agent_id
  slug         = "adminer"
  display_name = "Adminer"
  url          = "http://localhost:18080"
  share        = "authenticated"
  subdomain    = true
  icon         = "https://www.adminer.org/favicon.ico"
  order        = 3

  healthcheck {
    url       = "http://localhost:18080"
    interval  = 5
    threshold = 6
  }
}

resource "coder_script" "adminer_reverse_proxy" {
  agent_id           = var.agent_id
  script             = templatefile("${path.module}/run.sh", { PROXY_LINE = join(" ", var.proxy_mappings) })
  display_name       = "Reverse Proxy"
  icon               = "https://www.kali.org/tools/socat/images/socat-logo.svg"
  run_on_start       = true
  start_blocks_login = true
}
