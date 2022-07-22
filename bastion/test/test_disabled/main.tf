module "bastion" {
  source = "../../"

  name              = ""
  environment       = ""
  project           = "rv-saas"
  service           = ""
  owner             = ""
  allowed_ssh_cidrs = []
  enable            = false
}
