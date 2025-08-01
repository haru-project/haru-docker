ARG BASE_IMAGE=haru/haru-os:ros2
FROM ${BASE_IMAGE} AS base

# Install X11/OpenGL Dependencies
RUN apt update && apt install -y \
    libgl1 libglx0 libegl1 libxext6 libx11-6 libxrandr2 libxss1 libxcursor1 \
    libxcomposite1 libasound2t64 libxi6 libxtst6 libpulse0 libnss3 libxinerama1 \
    libsdl2-dev libjpeg-dev \
    x11-xserver-utils mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# Clone ROS dependencies
WORKDIR /ros2_ws/src

ARG CLONE_METHOD=ssh
ENV CLONE_METHOD=${CLONE_METHOD}

RUN --mount=type=secret,id=sshkey,required=false \
    --mount=type=secret,id=github_token,required=false \
    if [ "$CLONE_METHOD" = "https" ]; then \
        TOKEN=$(cat /run/secrets/github_token) && \
        git clone -b develop_ros2 https://x-access-token:${TOKEN}@github.com/haru-project/haru-unity.git && \
        git clone -b jazzy_debian https://x-access-token:${TOKEN}@github.com/haru-project/ROS-TCP-Endpoint.git && \
        git clone -b ros2 https://x-access-token:${TOKEN}@github.com/haru-project/strawberry-ros-msgs.git && \
        git clone -b fix_tuple_error https://x-access-token:${TOKEN}@github.com/haru-project/idmind-tabletop-ros-pkg.git; \
    else \
        mkdir -p $HOME/.ssh && cp /run/secrets/sshkey $HOME/.ssh/github && \
        echo "Host github.com" > $HOME/.ssh/config && \
        echo "    IdentityFile $HOME/.ssh/github" >> $HOME/.ssh/config && \
        echo "    StrictHostKeyChecking no" >> $HOME/.ssh/config && \
        git clone -b develop_ros2 git@github.com:haru-project/haru-unity.git && \
        git clone -b jazzy_debian git@github.com:haru-project/ROS-TCP-Endpoint.git && \
        git clone -b ros2 git@github.com:haru-project/strawberry-ros-msgs.git && \
        git clone -b fix_tuple_error git@github.com:haru-project/idmind-tabletop-ros-pkg.git; \
    fi

# Download Unity App
RUN curl -L -o /ros2_ws/src/haru-unity/HVE_jazzy_linux.zip "https://www.dropbox.com/scl/fi/8jwe4mnp76h1l4elpfvqu/HVE_jazzy_linux.zip?rlkey=sg8zshsrndyxcic8v68gw6fxo&e=1&st=6mnx9pxf&dl=1" && \
    unzip /ros2_ws/src/haru-unity/HVE_jazzy_linux.zip -d /ros2_ws/src/haru-unity/scripts/unity_ve && \
    rm /ros2_ws/src/haru-unity/HVE_jazzy_linux.zip

# Download robot resources
RUN cd /ros2_ws/src/idmind-tabletop-ros-pkg && \
    /bin/bash -c "bash scripts/download_resources.sh"

# Build workspace
WORKDIR /ros2_ws

RUN apt-get update && \
    /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && rosdep install --ignore-src --from-path src --rosdistro ${ROS_DISTRO} -y" && \
    rm -rf /var/lib/apt/lists/*

RUN ["/bin/bash", "-c", "source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build --symlink-install"]

# Install Web Server
WORKDIR /app

RUN apt update && apt install -y \
    python3-noble-pyharu \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=secret,id=sshkey,required=false \
    --mount=type=secret,id=github_token,required=false \
    if [ "$CLONE_METHOD" = "https" ]; then \
        TOKEN=$(cat /run/secrets/github_token) && \
        git clone -b develop https://x-access-token:${TOKEN}@github.com/haru-project/haru2_web.git; \
    else \
        mkdir -p $HOME/.ssh && cp /run/secrets/sshkey $HOME/.ssh/github && \
        echo "Host github.com" > $HOME/.ssh/config && \
        echo "    IdentityFile $HOME/.ssh/github" >> $HOME/.ssh/config && \
        echo "    StrictHostKeyChecking no" >> $HOME/.ssh/config && \
        git clone -b develop git@github.com:haru-project/haru2_web.git; \
    fi

WORKDIR /app/haru2_web

RUN python3 -m venv --system-site-packages .venv && \
    .venv/bin/pip install --upgrade pip setuptools wheel && \
    .venv/bin/pip install .

WORKDIR /ros2_ws

CMD ["/bin/bash"]