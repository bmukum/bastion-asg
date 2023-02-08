locals {
  tags = {
    environment       = var.environment
    application       = var.application
    business_vertical = var.business_vertical
    Name              = var.name
    service           = var.service
    purpose           = "airflow"
    division          = var.division
    managed_by        = "terraform"

  }
}