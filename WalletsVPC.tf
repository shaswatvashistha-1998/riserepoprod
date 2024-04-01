resource "google_compute_network" "gatewayvpc_vpc" {
  name                    = "gatewayvpc-walletgateway-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "gatewayvpc_subnet" {
  name          = "gateway-vpc-subnet"
  ip_cidr_range = "10.36.1.0/24"
  network       = google_compute_network.gatewayvpc_vpc.name
  region        = var.region
}

resource "google_compute_subnetwork" "gateway_access_subnet" {
  name          = "gateway-vpcconnector-subnet"
  ip_cidr_range = "10.37.1.0/28"
  network       = google_compute_network.gatewayvpc_vpc.name
  region        = var.region
}
resource "google_compute_firewall" "gatewayvpc_allow_ssh" {
  name        = "gatewayvpc-allow-ssh-walletgateway"
  network     = google_compute_network.gatewayvpc_vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["ssh-enabled"]
}

resource "google_compute_firewall" "gateway_allow_all_firewall" {
  name        = "gateway-allow-all-firewall"
  network     = google_compute_network.gatewayvpc_vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_global_address" "gatewayvpc_private_ip_block" {
  name         = "gatewayvpc-private-ip-block"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  prefix_length = 20
  network       = google_compute_network.gatewayvpc_vpc.self_link
}

resource "google_service_networking_connection" "gatewayvpc_private_vpc_connection" {
  network                 = google_compute_network.gatewayvpc_vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gatewayvpc_private_ip_block.name]
}

resource "google_compute_network_peering_routes_config" "gatewayvpc_peering_routes" {
  peering = google_service_networking_connection.gatewayvpc_private_vpc_connection.peering
  network = google_compute_network.gatewayvpc_vpc.name

  import_custom_routes = true
  export_custom_routes = true
}

resource "google_sql_database" "gatewayvpc_main" {
  name     = "gatewayvpc-main"
  instance = google_sql_database_instance.gatewayvpc_main_primary.name
}

resource "google_sql_database_instance" "gatewayvpc_main_primary" {
  name             = "gatewayvpc-wallets-vpc-sql"
  database_version = "MYSQL_8_0"
  depends_on       = [google_service_networking_connection.gatewayvpc_private_vpc_connection]
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    //comment the availability type and the location preference to move the sql to single az without HA
    disk_size         = 10  # 10 GB is the smallest disk size
    ip_configuration {
      ipv4_enabled    = true
      //change this value to true to enable public ip and false to disable public ip for sql
      private_network = google_compute_network.gatewayvpc_vpc.self_link
      authorized_networks {
        name = "retool1"
        value = "35.90.103.132/30"
      }
      authorized_networks {
        name = "Data studio2"
        value = "74.125.0.0/16"
      }
      authorized_networks {
        name = "Data studio1"
        value = "142.251.74.0/23"
      }
      authorized_networks {
        name = "retool2"
        value = "44.208.168.68/30"
      }
      authorized_networks {
        name = "Andrew Fiber"
        value = "12.174.69.107"
      }
      authorized_networks {
        name = "Andrew Spectrum"
        value = "107.143.107.145/32"
      }
      authorized_networks {
        name = "wallet-nat-manual-ip-0"
        value = "34.42.25.177"
      }
      authorized_networks {
        name = "internal-nat-manual-ip-0"
        value = "104.197.222.98"
      }
      authorized_networks {
        name = "ingress-nat-manual-ip-0"
        value = "34.42.143.0"
      }
      authorized_networks {
        name = "andrew-new-ip"
        value = "107.143.107.145"
      }
      authorized_networks {
        name = "thinksys-ip"
        value = "115.112.99.50"
      }
      //plese remember to change these values once the nat gateways are created.as the values can changed and must be also changed here

    }
    location_preference {
      zone = var.zone  # Preferred zone for primary instance
    }
    maintenance_window {
      day  = 1  # Sunday
      hour = 4  # 4 AM UTC
      update_track = "stable"  # Update track for maintenance updates
    }
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "03:00"  # Backup start time (in UTC)
      location           = "us"     # Backup locationd
    }
  }
}

resource "google_sql_user" "gatewayvpc_db_user" {
  name     = "admin"
  instance = google_sql_database_instance.gatewayvpc_main_primary.name
  password = "uaigcushc9u8"
}


## Create Cloud Router

resource "google_compute_router" "gatewayrouter" {
  project = var.project
  name    = "wallet-api-nat-router"
  network = google_compute_network.gatewayvpc_vpc.name
  region  = var.region
  bgp {
    asn = 64514
  }

}

## Create Nat Gateway
resource "google_compute_address" "gatewayaddress" {
  count  = 1
  name   = "wallet-nat-manual-ip-${count.index}"
  region = var.region
}

resource "google_compute_router_nat" "walletnat" {
  name                               = "wallet-api-nat"
  router                             = google_compute_router.gatewayrouter.name
  region                             = var.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.gatewayaddress.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.gatewayvpc_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  subnetwork {
    name                    = google_compute_subnetwork.gateway_access_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_vpc_access_connector" "gateway_api_connector" {
  name          = "walletapivpcconnector"
  subnet {
    name = google_compute_subnetwork.gateway_access_subnet.name
  }
  machine_type = "f1-micro"
}

