FROM ros:noetic-ros-base

ENV DEBIAN_FRONTEND=noninteractive

# System basics
RUN apt-get update && apt-get install -y \
    curl wget nano vim lsb-release git \
    iproute2 net-tools iputils-ping \
    alsa-utils \
    clang build-essential cmake \
    python3-pip python3-venv python3-yaml && \
    rm -rf /var/lib/apt/lists/*

# ROS basics
RUN apt-get update && apt-get install -y \
    ros-noetic-rqt ros-noetic-rqt-common-plugins ros-noetic-rqt-robot-plugins && \
    rm -rf /var/lib/apt/lists/*

# Haru basics
RUN wget -O - https://robotics.upo.es/repos/focal_apt/debian/conf/harurepo.gpg.key | apt-key add - && \
    wget -P /etc/apt/sources.list.d/ https://robotics.upo.es/repos/focal_apt/debian/conf/harufocal.list && \
    apt-get update && \
    rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use the custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]