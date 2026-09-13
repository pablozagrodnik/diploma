resource "helm_release" "thesis_app" {
  chart            = "../../k8s/thesis-api"
  name             = "thesis-app"
  namespace        = "default"
  create_namespace = true

  set = [
    {
      name  = "postgres.host"
      value = data.terraform_remote_state.base.outputs.postgres_private_ip
    },
    {
      name  = "redis.host"
      value = data.terraform_remote_state.base.outputs.redis_private_ip
    }
  ]
}
