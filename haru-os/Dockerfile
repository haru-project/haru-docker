FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive

# System basics
RUN apt-get update && apt-get install -y \
    curl wget nano vim lsb-release git \
    iproute2 net-tools iputils-ping \
    alsa-utils \
    clang build-essential cmake \
    python3-pip python3-venv python3-colcon-common-extensions \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# ROS basics
RUN apt update && apt install -y \
    ros-${ROS_DISTRO}-rqt ros-${ROS_DISTRO}-rqt-common-plugins \
    && rm -rf /var/lib/apt/lists/*

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

# ####################################################################################################
# User created during build - switch to non-root user
# ####################################################################################################
COPY create_default_user.sh /create_default_user.sh
RUN chmod +x /create_default_user.sh && /create_default_user.sh /bin/bash -c "echo 'User setup completed during build'"

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use the custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]

USER haru-eut

CMD ["/bin/bash"]