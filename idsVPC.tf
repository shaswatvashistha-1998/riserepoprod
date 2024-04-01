resource "google_compute_network" "cloudids" {
    name = "cloudids-vpc"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cloudids_subnet" {
  name          = "cloudids-vpc-subnet"
  ip_cidr_range = "10.61.1.0/24"
  region        = var.region
  network       = google_compute_network.cloudids.id
}

resource "google_compute_global_address" "service_range" {
    name          = "address"
    purpose       = "VPC_PEERING"
    address_type  = "INTERNAL"
    prefix_length = 16
    network       = google_compute_network.cloudids.id
}
resource "google_service_networking_connection" "private_service_connection_ids" {
    network                 = google_compute_network.cloudids.id
    service                 = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [google_compute_global_address.service_range.name]
}

resource "google_compute_network_peering_routes_config" "peering_routes_ids" {
  peering = google_service_networking_connection.private_service_connection_ids.peering
  network = google_compute_network.cloudids.name

  import_custom_routes = true
  export_custom_routes = true
}
resource "google_cloud_ids_endpoint" "example-endpoint" {
    name     = "idsendpoint"
    location = "us-central1-f"
    network  = google_compute_network.cloudids.id
    severity = "INFORMATIONAL"
    depends_on = [google_service_networking_connection.private_service_connection_ids]
}

resource "google_compute_firewall" "ids_allow_all_firewall" {
  name        = "ids-allow-all-firewall"
  network     = google_compute_network.cloudids.name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}