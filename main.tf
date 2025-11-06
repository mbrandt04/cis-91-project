terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
    project = var.project
    region  = var.region
    zone    = var.zone
}

resource "google_service_account" "default" {
  account_id   = "vm-service-account"
  display_name = "VM Service Account"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"

}

resource "google_compute_firewall" "allow_web_ssh" {
  name    = "terraform-firewall-allow-web-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_disk" "persistent_disk" {
  name = "test-disk-balanced"
  type = "pd-balanced"
  zone = var.zone
  size = 10
}
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-small"
  tags         = ["web", "dev"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  attached_disk {
    source = google_compute_disk.persistent_disk.id
    device_name = "test-disk-balanced"
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

output "external_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}