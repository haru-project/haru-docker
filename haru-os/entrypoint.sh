#!/bin/bash
set -e

# Set GUI
export LIBGL_ALWAYS_INDIRECT=${LIBGL_ALWAYS_INDIRECT:=0}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:=/dev/null}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:=/tmp/runtime-$USER}
mkdir -p $XDG_RUNTIME_DIR
if [ "$(stat -c %u "$XDG_RUNTIME_DIR")" -eq "$(id -u)" ]; then
    chmod 700 "$XDG_RUNTIME_DIR"
fi
export QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM:=1}

# Set AUDIO
export AUDIO_CARD=${AUDIO_CARD:=0}
echo "[INFO] Using AUDIO_CARD (default ALSA card): $AUDIO_CARD"
cat > /etc/asound.conf <<EOF
defaults.pcm.card $AUDIO_CARD
defaults.ctl.card $AUDIO_CARD
EOF

# Set CUDA
export NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:=all}
export NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:=compute,utility}

# Set ROS
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:=0}
echo "[INFO] Using ROS_DOMAIN_ID: $ROS_DOMAIN_ID"

export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:=rmw_fastrtps_cpp}
echo "[INFO] Using RMW_IMPLEMENTATION: $RMW_IMPLEMENTATION"

# If using RMW Fast DDS, apply additional configuration
if [ "$RMW_IMPLEMENTATION" = "rmw_fastrtps_cpp" ]; then
    export FASTDDS_BUILTIN_TRANSPORTS=${FASTDDS_BUILTIN_TRANSPORTS:=UDPv4}
    echo "[INFO] Using FASTDDS_BUILTIN_TRANSPORTS: $FASTDDS_BUILTIN_TRANSPORTS"
fi

# If using RMW Cyclone DDS, apply additional configuration
if [ "$RMW_IMPLEMENTATION" = "rmw_cyclonedds_cpp" ]; then
    export CYCLONEDDS_URI=${CYCLONEDDS_URI:=file:///config/cyclonedds.xml}
    echo "[INFO] Using CYCLONEDDS_URI: $CYCLONEDDS_URI"
fi

# If using RMW Zenoh, apply additional configuration
if [ "$RMW_IMPLEMENTATION" = "rmw_zenoh_cpp" ]; then
    export ZENOH_ROUTER_CONFIG_URI=${ZENOH_ROUTER_CONFIG_URI:=/config/RMW_ZENOH_ROUTER_CONFIG.json5}
    export ZENOH_SESSION_CONFIG_URI=${ZENOH_SESSION_CONFIG_URI:=/config/RMW_ZENOH_SESSION_CONFIG.json5}
    echo "[INFO] Using ZENOH_ROUTER_CONFIG_URI: $ZENOH_ROUTER_CONFIG_URI"
    echo "[INFO] Using ZENOH_SESSION_CONFIG_URI: $ZENOH_SESSION_CONFIG_URI"
fi

# Source ROS 2 distro environment
source "/opt/ros/$ROS_DISTRO/setup.bash"

# Source workspace overlay, if exists
if [ -f "/ros2_ws/install/setup.bash" ]; then
    source "/ros2_ws/install/setup.bash"
fi

# Execute whatever command was passed to the container
exec "$@"
