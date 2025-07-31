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

# Install dependencies
WORKDIR /root/catkin_ws
RUN --mount=type=secret,id=sshkey \
    mkdir -p $HOME/.ssh && cp /run/secrets/sshkey $HOME/.ssh/github && \
    echo "Host github.com" > $HOME/.ssh/config && \
    echo "    IdentityFile $HOME/.ssh/github" >> $HOME/.ssh/config && \
    echo "    StrictHostKeyChecking no" >> $HOME/.ssh/config && \
    git clone -b haru2 git@github.com:haru-project/idmind-tabletop-ros-woz.git /root/catkin_ws/src

RUN apt-get update && apt-get install -y \
    google-asr-cpp && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && rosdep install --ignore-src --from-path src --rosdistro ${ROS_DISTRO} -y --skip-keys='google-asr-cpp'" && \
    rm -rf /var/lib/apt/lists/*

# Build workspace
RUN ["/bin/bash", "-c", "source /opt/ros/${ROS_DISTRO}/setup.bash && catkin_make"]

CMD ["/bin/bash"]