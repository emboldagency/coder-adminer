# coder-adminer

Terraform module to provision Adminer as a standalone module for Coder templates.

This module creates:

- A Docker container running the official `adminer:latest` image
- A `coder_app` entry so Adminer is exposed in the Coder UI
- A `coder_script` that runs a small `socat` reverse-proxy in the main workspace container to expose Adminer to the host

This module is intended to be included by workspace templates that want to provide Adminer (a lightweight DB GUI) as a dev service.

## Requirements

- The workspace agent image must include `socat` (the proxy script runs in the agent container)
- Docker and the Terraform Docker provider must be available on the host where the template applies

## Example usage

```hcl
module "adminer" {
  source              = "git::https://github.com/emboldagency/coder-adminer.git?ref=v1.0.0"
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = "coder-${data.coder_workspace.me.id}"
  proxy_mappings      = ["18080:adminer:8080"]
}
```

## Variables

- `agent_id` (string) - Coder agent id to attach the proxy script and app to
- `docker_network_name` (string) - Docker network for the container
- `resource_name_base` (string) - Unique name prefix for docker resources
- `container_memory_limit` (number) - Memory limit per container (MB). Default: 512
- `container_user_id` (string|null) - Optional UID to run containers as
- `proxy_mappings` (list(string)) - Optional list of mappings `local_port:remote_host:remote_port`. Default: `['18080:adminer:8080']`

## Notes

- If your agent image doesn't have `socat`, install it or use a different reverse-proxy approach (nginx, or configure coder reverse proxy).
- The module pulls `adminer:latest`. If you need a pinned version, modify `main.tf` to reference a specific tag.
