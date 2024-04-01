resource "google_compute_network_peering" "peering1" {
  name         = "enode-to-storage"
  network      = google_compute_network.ilb_network.id
  peer_network = google_compute_network.vpc.self_link
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering2" {
  name         = "storage-to-enode"
  network      = google_compute_network.vpc.self_link
  peer_network = google_compute_network.ilb_network.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering3" {
  name         = "internal-to-storage"
  network      = google_compute_network.internal-api-vpc.self_link
  peer_network = google_compute_network.vpc.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering4" {
  name         = "storage-to-internal"
  network      = google_compute_network.vpc.self_link
  peer_network = google_compute_network.internal-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}


resource "google_compute_network_peering" "peering5" {
  name         = "internal-to-enode"
  network      = google_compute_network.internal-api-vpc.self_link
  peer_network = google_compute_network.ilb_network.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering6" {
  name         = "enode-to-internal"
  network      = google_compute_network.ilb_network.self_link
  peer_network = google_compute_network.internal-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}


resource "google_compute_network_peering" "peering7" {
  name         = "ingress-to-internal"
  network      = google_compute_network.ingress-api-vpc.self_link
  peer_network = google_compute_network.internal-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering8" {
  name         = "ingress-to-enode"
  network      = google_compute_network.ingress-api-vpc.self_link
  peer_network = google_compute_network.ilb_network.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering9" {
  name         = "ingress-to-storage"
  network      = google_compute_network.ingress-api-vpc.self_link
  peer_network = google_compute_network.vpc.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering10" {
  name         = "storage-to-ingress"
  network      = google_compute_network.vpc.self_link
  peer_network = google_compute_network.ingress-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}
resource "google_compute_network_peering" "peering11" {
  name         = "enode-to-ingress"
  network      = google_compute_network.ilb_network.self_link
  peer_network = google_compute_network.ingress-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}
resource "google_compute_network_peering" "peering12" {
  name         = "internal-to-ingress"
  network      = google_compute_network.internal-api-vpc.self_link
  peer_network = google_compute_network.ingress-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering13" {
  name         = "ids-to-ingress"
  network      = google_compute_network.cloudids.self_link
  peer_network = google_compute_network.ingress-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering14" {
  name         = "ingress-to-ids"
  network      = google_compute_network.ingress-api-vpc.self_link
  peer_network = google_compute_network.cloudids.id
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "peering15" {
  name         = "ids-to-storage"
  network      = google_compute_network.cloudids.self_link
  peer_network = google_compute_network.vpc.id
  import_custom_routes = true
  export_custom_routes = true
}
resource "google_compute_network_peering" "peering16" {
  name         = "storage-to-ids"
  network      = google_compute_network.vpc.self_link
  peer_network = google_compute_network.cloudids.id
  import_custom_routes = true
  export_custom_routes = true
}


resource "google_compute_network_peering" "peering17" {
  name         = "ids-to-internal"
  network      = google_compute_network.cloudids.self_link
  peer_network = google_compute_network.internal-api-vpc.id
  import_custom_routes = true
  export_custom_routes = true
}
resource "google_compute_network_peering" "peering18" {
  name         = "internal-to-ids"
  network      = google_compute_network.internal-api-vpc.self_link
  peer_network = google_compute_network.cloudids.id
  import_custom_routes = true
  export_custom_routes = true
}