data "terraform_remote_state" "base" {
  backend = "gcs"
  config = {
    bucket = "tf-state-2026"
    prefix = "terraform/state/base"
  }
}
