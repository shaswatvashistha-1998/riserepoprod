# Create a internal-api-vpc
resource "google_compute_network" "internal-api-vpc" {
  name                    = "internal-api-vpc"
  auto_create_subnetworks = "false"

}

# Create a Subnet
resource "google_compute_subnetwork" "my-custom-subnet" {
  name          = "internal-api-vpc-subnet"
  ip_cidr_range = "10.13.0.0/24"
  network       = google_compute_network.internal-api-vpc.name
  region        = var.region
}

resource "google_compute_subnetwork" "vpc-access-connector-subnet" {
  name          = "vpc-access-connector-subnet"
  ip_cidr_range = "10.14.0.0/28"
  network       = google_compute_network.internal-api-vpc.name
  region        = var.region
}

## Create Cloud Router

resource "google_compute_router" "router" {
  project = var.project
  name    = "internal-api-nat-router"
  network = google_compute_network.internal-api-vpc.name
  region  = var.region
  bgp {
    asn = 64514
  }

}

## Create Nat Gateway
resource "google_compute_address" "address" {
  count  = 1
  name   = "nat-manual-ip-${count.index}"
  region = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "internal-api-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.address.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.my-custom-subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  subnetwork {
    name                    = google_compute_subnetwork.vpc-access-connector-subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_vpc_access_connector" "internal_api_connector" {
  name          = "internal-apivpcconnector"
  subnet {
    name = google_compute_subnetwork.vpc-access-connector-subnet.name
  }
  machine_type = "f1-micro"
}

resource "google_compute_firewall" "internal_allow_all_firewall" {
  name        = "internal-allow-all-firewall"
  network     = google_compute_network.internal-api-vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}

//this part is for creating the psc adress and the psc endpointa along with private DNS.This will be different for every terraform

# resource "google_compute_address" "cloudsqlredisnewvpc" {
#   name         = "cloudsqlredisnewvpc"
#   address_type = "INTERNAL"
#   subnetwork   = google_compute_subnetwork.my-custom-subnet.self_link
#   address      = "10.13.0.9"
# }