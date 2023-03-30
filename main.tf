terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.90.0"
    }
  }
}


provider "google" {
  credentials = file("credentials.json")
  project = "playground-s-11-dae83aae"
  region  = "us-central1"
}

# Create a webserver

resource "google_compute_instance" "webserver" {
  name         = "webserver"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  attached_disk {
    source = google_compute_disk.webserver-disk.name
    device_name = "webserver-disk"         
  }
}

# Create a new snapshot schedule

resource "google_compute_resource_policy" "webserver-snapshot-policy" {
  name = "webserver-snapshot-policy"
  region = "us-central1"
  snapshot_schedule_policy {
   
    snapshot_properties {
      guest_flush = true
      labels = {
        env = "production"
      }
    }
    schedule {
#    daily_schedule {
#      days_in_cycle = 1
#      start_time = "00:00"
#    }
    hourly_schedule {
      hours_in_cycle = 1
      start_time = "17:00"
    }
  }
  retention_policy {
    max_retention_days    = 10
    on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
  }
 }
}


# Attach the snapshot policy to the disk

resource "google_compute_disk" "webserver-disk" {
  name = "webserver-disk"
  type = "pd-standard"
  image = "projects/debian-cloud/global/images/debian-11-bullseye-v20230306"
  size = "100"
  labels = {
    env = "production"
  }
  zone = "us-central1-a"
#  resource_policies = [
#    google_compute_disk_resource_policy.webserver-snapshot-policy.self_link,
#  ]
}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  name = google_compute_resource_policy.webserver-snapshot-policy.name
  disk = google_compute_disk.webserver-disk.name
  zone = "us-central1-a"
}

