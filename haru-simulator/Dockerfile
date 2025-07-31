FROM haru/haru-os:ros1

# Install X11/OpenGL Dependencies
RUN apt update && apt install -y \
    libgl1 libglx0 libegl1 libxext6 libx11-6 libxrandr2 libxss1 libxcursor1 \
    libxcomposite1 libasound2 libxi6 libxtst6 libpulse0 libnss3 libxinerama1 \
    x11-xserver-utils mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# Install ROS dependencies
RUN apt-get update && apt-get install -y \
    ros-noetic-xacro \
    ros-noetic-idmind-tabletop-msgs \
    ros-noetic-haru-unity ros-noetic-haru-utils \
    && rm -rf /var/lib/apt/lists/*

# Update resources
RUN ["/bin/bash", "-c", "source /opt/ros/${ROS_DISTRO}/setup.bash && roslaunch haru_utils update_resources.launch"]

CMD ["/bin/bash"]