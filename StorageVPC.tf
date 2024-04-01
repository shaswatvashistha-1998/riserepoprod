resource "google_compute_network" "vpc" {
  name                    = "storageterraform-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "storagevpc_subnet" {
  name          = "storage-vpc-subnet"
  ip_cidr_range = "10.63.1.0/24"
  network       = google_compute_network.vpc.name
  region        = var.region
}

resource "google_compute_firewall" "allow_ssh" {
  name        = "allow-ssh"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["ssh-enabled"]
}

resource "google_compute_firewall" "storage_allow_all_firewall" {
  name        = "storage-allow-all-firewall"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_global_address" "private_ip_block" {
  name         = "private-ip-block"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  prefix_length = 20
  network       = google_compute_network.vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering = google_service_networking_connection.private_vpc_connection.peering
  network = google_compute_network.vpc.name

  import_custom_routes = true
  export_custom_routes = true
}

resource "google_sql_database" "main" {
  name     = "main"
  instance = google_sql_database_instance.main_primary.name
}

resource "google_sql_database_instance" "main_primary" {
  name             = "rise-tf-primary"
  database_version = "MYSQL_8_0"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    //comment the availability type to move the sql to single az without HA
    disk_size         = 10  # 10 GB is the smallest disk size
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.self_link
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
      //change this value to true to enable public ip and false to disable public ip for sql
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


# Output the paths to download the client-cert, client-key, and server-ca files


resource "google_sql_user" "db_user" {
  name     = "admin"
  instance = google_sql_database_instance.main_primary.name
  password = "uaigcushc9u8"
}
//adding this comment for git


//adding this portion for redis vm machine
resource "google_compute_instance" "simple_instance" {
  name         = "simple-vm-instance"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["allow-ssh", "allow-health-check"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.storagevpc_subnet.id
    access_config {
      # Enable public IP
      
    }
  }

  metadata_startup_script = <<-EOF
    #! /bin/bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y redis-server

    # Configure Redis to bind to 0.0.0.0
    sed -i 's/^bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf

    # Restart Redis to apply changes
    systemctl restart redis-server
  EOF
}

