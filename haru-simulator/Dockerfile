ARG BASE_IMAGE=haru/haru-os:local
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

COPY .repos .repos

ARG CLONE_METHOD=ssh
ENV CLONE_METHOD=${CLONE_METHOD}

RUN --mount=type=ssh,required=false \
    --mount=type=secret,id=github_token,required=false \
    if [ "$CLONE_METHOD" = "https" ]; then \
        TOKEN=$(cat /run/secrets/github_token) && \
        cp .repos .repos.https && \
        sed -i "s|git@github.com:|https://x-access-token:${TOKEN}@github.com/|g" .repos.https && \
        vcs import . < .repos.https && \
        rm -f .repos.https; \
    else \
        ssh-keyscan github.com >> ~/.ssh/known_hosts && \
        vcs import . < .repos; \
    fi

# Download Unity App
WORKDIR /ros2_ws/src/haru-unity
RUN ["/bin/bash", "-c", "bash scripts/download_unity_app.sh"]

# Build workspace
WORKDIR /ros2_ws

RUN apt-get update && \
    /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && rosdep install --ignore-src --from-path src --rosdistro ${ROS_DISTRO} -y" && \
    rm -rf /var/lib/apt/lists/*

RUN ["/bin/bash", "-c", "source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build --symlink-install"]

# Install Web Server
WORKDIR /app

RUN --mount=type=ssh,required=false \
    --mount=type=secret,id=github_token,required=false \
    if [ "$CLONE_METHOD" = "https" ]; then \
    TOKEN=$(cat /run/secrets/github_token) && \
    git clone -b master https://x-access-token:${TOKEN}@github.com/haru-project/haru2_web.git; \
    else \
    ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    git clone -b master git@github.com:haru-project/haru2_web.git; \
    fi

WORKDIR /app/haru2_web
RUN ["/bin/bash", "-c", "pip install --break-system-packages ."]

CMD ["/bin/bash"]