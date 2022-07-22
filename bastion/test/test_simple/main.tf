resource "random_string" "random" {
  length  = 10
  special = false
}

module "bastion" {
  source = "../../"

  name        = "bastion-${random_string.random.result}"
  environment = "terratest"
  project     = "sandbox"
  service     = "terratest"
  owner       = "platform-tools@redventures.com"

  allowed_ssh_cidrs = ["209.251.238.0/23"]
}
