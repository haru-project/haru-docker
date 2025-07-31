# Haru Docker containers
Docker containers for Haru projects.

## Install
Install the [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) and follow the [post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/).

For CUDA support, also install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-the-nvidia-container-toolkit).

## Setup
Allow Docker GUI access:
```
xhost +local:docker
```

## Images and Applications

### Haru-OS
```
docker build --rm -t haru/haru-os:ros1 -f haru-os/Dockerfile ./haru-os
```

Run:
```
docker run -it --rm --name haru-os --gpus all \
  --network host --gpus all \
  --env-file .env.example \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  haru/haru-os:ros1
```

Or compose: (recommended)
```
docker compose -f docker-compose-haru.yaml --env-file .env.example up
```

### Haru Simulator
```
docker build --rm --secret id=sshkey,src=$HOME/.ssh/id_ed25519 -t haru/haru-simulator:ros1 -f haru-simulator/Dockerfile ./haru-simulator
```

Run:
```
docker run -it --rm --name haru-simulator \
  --network host --gpus all \
  --env-file .env.example \
  --device /dev/snd \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  haru/haru-simulator:ros1
```

Or compose: (recommended)
```
docker compose -f docker-compose-simulator.yaml --env-file .env.example up
```

### Haru Virtual
```
docker compose -f docker-compose-virtual.yaml --env-file .env.example up
```
