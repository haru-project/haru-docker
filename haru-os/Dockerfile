FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive

# System basics
RUN apt-get update && apt-get install -y \
    curl wget unzip nano vim lsb-release \
    git openssh-client \
    iproute2 net-tools iputils-ping \
    alsa-utils pulseaudio-utils ffmpeg \
    clang build-essential cmake \
    python3-pip python3-venv \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Ros basics
RUN apt update && apt install -y \
    python3-vcstool python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-rqt ros-${ROS_DISTRO}-rqt-common-plugins \
    ros-${ROS_DISTRO}-rviz2 ros-${ROS_DISTRO}-robot-state-publisher \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

COPY cyclonedds.xml /config/cyclonedds.xml

COPY custom_rosdep.yaml /etc/ros/rosdep/custom_rosdep.yaml
RUN echo "yaml file:///etc/ros/rosdep/custom_rosdep.yaml" >> /etc/ros/rosdep/sources.list.d/20-custom.list && \
    rosdep update

# Haru basics
RUN wget -O /usr/share/keyrings/harurepo.gpg https://robotics.upo.es/repos/noble_apt/debian/conf/harurepo.gpg.key && \
    wget -P /etc/apt/sources.list.d/ https://robotics.upo.es/repos/noble_apt/debian/conf/harunoble.list && \
    echo "yaml https://raw.githubusercontent.com/robotics-upo/rosdistro/master/rosdep.yaml" >> /etc/ros/rosdep/sources.list.d/20-haru.list && \
    rosdep update

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]