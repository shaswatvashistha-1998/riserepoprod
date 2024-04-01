# Create a ingress-api-vpc
resource "google_compute_network" "ingress-api-vpc" {
  name                    = "ingress-api-vpc"
  auto_create_subnetworks = "false"

}

# Create a Subnet
resource "google_compute_subnetwork" "ingress-api-vpc-my-custom-subnet" {
  name          = "ingress-api-vpc-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.ingress-api-vpc.name
  region        = var.region
}

resource "google_compute_subnetwork" "vpc-access-connector-subnet-ingress-api-vpc" {
  name          = "vpc-access-connector-subnet-ingress-api"
  ip_cidr_range = "10.12.0.0/28"
  network       = google_compute_network.ingress-api-vpc.name
  region        = var.region
}

## Create Cloud Router

resource "google_compute_router" "router_ingress_api" {
  project = var.project
  name    = "nat-router-ingress-api-vpc"
  network = google_compute_network.ingress-api-vpc.name
  region  = var.region
  bgp {
    asn = 64514
  }

}

resource "google_compute_address" "address_ingress_api" {
  count  = 1
  name   = "nat-manual-ip-ingress-api-${count.index}"
  region = var.region
}
## Create Nat Gateway

resource "google_compute_router_nat" "ingress_api_nat" {
  name                               = "nat-ingress-api"
  router                             = google_compute_router.router_ingress_api.name
  region                             = var.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.address_ingress_api.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.ingress-api-vpc-my-custom-subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  subnetwork {
    name                    = google_compute_subnetwork.vpc-access-connector-subnet-ingress-api-vpc.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

}

resource "google_vpc_access_connector" "ingress_api_connector" {
  name          = "vpc-con-ingress-api-vpc"
  subnet {
    name = google_compute_subnetwork.vpc-access-connector-subnet-ingress-api-vpc.name
  }
  machine_type = "f1-micro"
}

resource "google_compute_firewall" "ingress_allow_all_firewall" {
  name        = "ingress-allow-all-firewall"
  network     = google_compute_network.ingress-api-vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["3000-3100"]
  }
  source_ranges = ["0.0.0.0/0"]
}