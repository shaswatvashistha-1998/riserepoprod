
resource "google_compute_network" "ilb_network" {
  name                    = "enode-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ilb_subnet" {
  name          = "enode-vpc-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.ilb_network.id
}

resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  name                  = "enode-vpc-forwarding-rule"
  backend_service       = google_compute_region_backend_service.default.id
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  allow_global_access   = true
  network               = google_compute_network.ilb_network.id
  subnetwork            = google_compute_subnetwork.ilb_subnet.id
}

resource "google_compute_region_backend_service" "default" {
  name                  = "enode-vpc-backend-subnet"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.default.id]
  backend {
    group          = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_instance_template" "instance_template" {
  name         = "enode-vpc-mig-template"
  machine_type = "e2-small"
  tags         = ["allow-ssh", "allow-health-check"]

  network_interface {
    network    = google_compute_network.ilb_network.id
    subnetwork = google_compute_subnetwork.ilb_subnet.id
    access_config {
      # add external ip to fetch packages
    }
  }
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
  }

  # install nginx and serve a simple web page
  metadata = {
    startup-script = <<-EOF1
      #! /bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y nginx-light jq

      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
      METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')

      cat <<EOF > /var/www/html/index.html
      <pre>
      Name: $NAME
      IP: $IP
      Metadata: $METADATA
      </pre>
      EOF
    EOF1
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_health_check" "default" {
  name   = "enode-vpc-hc"
  region = var.region
  http_health_check {
    port = "80"
  }
}

resource "google_compute_region_instance_group_manager" "mig" {
  name   = "enode-vpc-mig1"
  region = var.region
  version {
    instance_template = google_compute_instance_template.instance_template.id
    name              = "primary"
  }
  base_instance_name = "vm"
  target_size        = 1
}

# allow all access from health check ranges
resource "google_compute_firewall" "fw_hc" {
  name          = "enode-vpc-fw-allow-hc"
  direction     = "INGRESS"
  network       = google_compute_network.ilb_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}

# allow communication within the subnet
resource "google_compute_firewall" "fw_ilb_to_backends" {
  name          = "enode-vpc-fw-allow-ilb-to-backends"
  direction     = "INGRESS"
  network       = google_compute_network.ilb_network.id
  source_ranges = ["10.0.1.0/24"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

# allow SSH
resource "google_compute_firewall" "fw_ilb_ssh" {
  name      = "enode-vpc-fw-ssh"
  direction = "INGRESS"
  network   = google_compute_network.ilb_network.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["allow-ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "enode_allow_all_firewall" {
  name        = "enode-allow-all-firewall"
  network     = google_compute_network.ilb_network.name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}