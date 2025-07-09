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
RUN wget -O - http://robotics.upo.es/repos/focal_apt/debian/conf/harurepo.gpg.key | apt-key add -
RUN wget -nc -P /etc/apt/sources.list.d/ http://robotics.upo.es/repos/focal_apt/debian/conf/harufocal.list
RUN echo "yaml https://raw.githubusercontent.com/robotics-upo/rosdistro/master/rosdep.yaml" | sudo tee /etc/ros/rosdep/sources.list.d/50-haru.list

RUN rm -f /etc/ros/rosdep/sources.list.d/20-default.list && \
    apt-get update && apt-get install -y \
    python3-rosdep && \
    rosdep init && \
    rosdep update --include-eol-distros && \
    rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use the custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]