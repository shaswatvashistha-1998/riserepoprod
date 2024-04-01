provider "google" {
    credentials = var.CREDS_KEY
    project     = var.project
    region      = var.region
}

provider "google-beta" {
    credentials = var.CREDS_KEY
    project     = var.project
    region      = var.region
}