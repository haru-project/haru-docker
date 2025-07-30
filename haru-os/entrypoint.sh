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

# Set CUDA
export NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:=all}
export NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:=compute,utility}

# Set ROS
export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:=rmw_cyclonedds_cpp}     # default to rmw_cyclonedds_cpp and not rmw_fastrtps_cpp (i.e., disable shared memory transport to allow communication between different users, including root)
echo "[INFO] Using RMW_IMPLEMENTATION: $RMW_IMPLEMENTATION"

export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:=0}
echo "[INFO] Using ROS_DOMAIN_ID: $ROS_DOMAIN_ID"

# Source ROS 2 distro environment
source "/opt/ros/$ROS_DISTRO/setup.bash"

# Source workspace overlay, if exists
if [ -f "/ros2_ws/install/setup.bash" ]; then
    source "/ros2_ws/install/setup.bash"
fi

# Execute whatever command was passed to the container
exec "$@"
