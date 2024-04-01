variable "project" {
  description = "riseworksstaging"
  type        = string
  default = "riseworksstaging"
}

variable "region" {
    default = "us-central1"
  description = "The GCP region"
  type        = string
}

variable "CREDS_KEY" {
  description = "CREDS"
  type        = string
}

variable "zone" {
    default = "us-central1-a"
  description = "The GCP region"
  type        = string
}