FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive

# System basics
RUN apt-get update && apt-get install -y \
    curl wget nano vim lsb-release git openssh-client \
    iproute2 net-tools iputils-ping \
    alsa-utils \
    clang build-essential cmake \
    python3-pip python3-venv \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Ros basics
RUN apt update && apt install -y \
    python3-vcstool python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-rqt ros-${ROS_DISTRO}-rqt-common-plugins \
    && rm -rf /var/lib/apt/lists/*

# Haru basics
RUN wget -O /usr/share/keyrings/harurepo.gpg https://robotics.upo.es/repos/noble_apt/debian/conf/harurepo.gpg.key && \
    wget -P /etc/apt/sources.list.d/ https://robotics.upo.es/repos/noble_apt/debian/conf/harunoble.list

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]