terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.20.3"
    }
  }
}

#set provider
#provider "docker" {
#  host = "unix:///var/run/docker.sock"
#}

provider "docker" {
  host    = "npipe:////.//pipe//docker_engine"
}

#build tha images
resource "docker_image" "vote" {
  name = "vote"
  build {
    path = "./vote"
    tag  = ["vote:develop"]
  }
}

resource "docker_image" "worker" {
  name = "worker"
  build {
    path = "./worker"
    tag  = ["worker:develop"]
  }
}

resource "docker_image" "result" {
  name = "result"
  build {
    path = "./result"
    tag  = ["result:develop"]
  }
}

# Download existing images
resource "docker_image" "redis" {
  name = "redis:alpine"
  keep_locally = true
}

resource "docker_image" "db" {
  name = "postgres:9.4"
  keep_locally = true
}

# Create networks
resource "docker_network" "front-tier" {
  name = "front-tier"
}

resource "docker_network" "back-tier" {
  name = "back-tier"
}


# Create the containers
resource "docker_container" "redis" {
  image = docker_image.redis.name
  name  = "redis"
  
  ports {
    internal = "6379"
    external = "6379"
  }

  networks_advanced {
    name    = docker_network.back-tier.name
    aliases = ["back-tier"]
  }
}

resource "docker_container" "db" {
  image = docker_image.db.name
  name  = "db"
  env = ["POSTGRES_USER=postgres", "POSTGRES_PASSWORD=postgres"]  

  networks_advanced {
    name    = docker_network.back-tier.name
    aliases = ["back-tier"]
  }  
}

resource "docker_container" "vote" {
  image = docker_image.vote.name
  name  = "vote"
  
  volumes {
    container_path  = "/app"
    read_only = false
    host_path = "H:/sourcecontrol/terraform-docker-example/vote"
  }
  ports {
    internal = 80
    external = 5000
  }

  networks_advanced {
    name    = docker_network.front-tier.name
    aliases = ["front-tier"]
  }

  networks_advanced {
    name    = docker_network.back-tier.name
    aliases = ["back-tier"]
  }

}

resource "docker_container" "worker" {
  image = docker_image.worker.name
  name  = "worker"

  networks_advanced {
    name    = docker_network.back-tier.name
    aliases = ["back-tier"]
  }
}

resource "docker_container" "result" {
  image = docker_image.result.name
  name  = "result"
  
  volumes {
    container_path  = "/app"
    read_only = false
    host_path = "H:/sourcecontrol/terraform-docker-example/result"
  }
  ports {
    internal = 80
    external = 5001
  }
  ports {
    internal = 5858
    external = 5858
  }

  networks_advanced {
    name    = docker_network.front-tier.name
    aliases = ["front-tier"]
  }

  networks_advanced {
    name    = docker_network.back-tier.name
    aliases = ["back-tier"]
  }
}