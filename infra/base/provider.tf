terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.1.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.7.0"
    }
  }
  backend "gcs" {
    bucket = "tf-state-2026"
    prefix = "terraform/state/base"
  }
}

provider "google" {
  project = "analysis-infrastructure"
  region  = "europe-central2"
  zone    = "europe-central2-a"
}