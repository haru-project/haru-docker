#!/bin/bash
set -e

# Set GUI
export LIBGL_ALWAYS_INDIRECT=${LIBGL_ALWAYS_INDIRECT:-0}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-/dev/null}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-root}
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM:-1}

# Set CUDA
export NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
export NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}

echo "ENTRYPOINT SCRIPT EXECUTION FOR user change STARTED AT $(date)"

# Default USER_ID and GROUP_ID if not set
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
USERNAME="haru-eut" # Default username

# user_removed=false

# Check if user with USER_ID already exists
EXISTING_USERNAME=$(getent passwd "$USER_ID" | cut -d: -f1)

# If the user exists and the username is different, remove the existing user (we need to free the UID)
if [ -n "$EXISTING_USERNAME" ] && [ "$EXISTING_USERNAME" != "$USERNAME" ]; then
  echo "Removing user $EXISTING_USERNAME"
  deluser --remove-home $EXISTING_USERNAME
#   user_removed=true
fi

# Create group if it doesn't exist
if ! getent group "$USERNAME" >/dev/null && ! getent group "$GROUP_ID" >/dev/null; then
    groupadd --gid "$GROUP_ID" "$USERNAME"
elif ! getent group "$USERNAME" >/dev/null && getent group "$GROUP_ID" >/dev/null; then
    EXISTING_GROUP_NAME=$(getent group "$GROUP_ID" | cut -d: -f1)
    echo "Warning: Group with GID $GROUP_ID already exists with name $EXISTING_GROUP_NAME."
    if [ "$USERNAME" != "$EXISTING_GROUP_NAME" ]; then
        echo "Using existing group name $EXISTING_GROUP_NAME for user $USERNAME."
        # Decide if you want to force USERNAME to EXISTING_GROUP_NAME or handle differently
    fi
    # For simplicity, we'll assume the GID is the primary concern.
    # If USERNAME must be used, ensure groupadd doesn't conflict or handle renaming.
fi

# Create user if it doesn't exist
if ! id -u "$USERNAME" >/dev/null 2>&1 && ! getent passwd "$USER_ID" >/dev/null; then
    # Ensure the group for GID exists before creating user with it
    if ! getent group "$GROUP_ID" >/dev/null; then
        groupadd --gid "$GROUP_ID" "$USERNAME" # Or use a default group name if USERNAME is taken
    fi
    useradd --shell /bin/bash --uid "$USER_ID" --gid "$GROUP_ID" --create-home "$USERNAME"
elif ! id -u "$USERNAME" >/dev/null 2>&1 && getent passwd "$USER_ID" >/dev/null; then
    # This condition implies:
    # 1. The desired username "$USERNAME" (e.g., "haru-eut") is not registered.
    # 2. The desired UID "$USER_ID" is already in use by a different user.
    # This state should ideally be prevented by the initial cleanup logic.
    # If this branch is reached, it indicates an unexpected or conflict state.
    EXISTING_USER_NAME_WITH_UID=$(getent passwd "$USER_ID" | cut -d: -f1)
    echo "Error: UID $USER_ID is already in use by user '$EXISTING_USER_NAME_WITH_UID'," \
         "but the desired username '$USERNAME' does not exist." >&2
    echo "This represents an unresolvable conflict based on the script's logic." >&2
    echo "The script expects that if UID $USER_ID is taken by a user other than '$USERNAME'," \
         "that user should have been removed earlier." >&2
    exit 1
fi

# Add user to sudoers with NOPASSWD
echo "Adding user $USERNAME to sudoers with NOPASSWD..."
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"

# Change ownership of /ros2_ws
if [ -d "/ros2_ws" ]; then
    echo "Changing ownership of /ros2_ws to $USERNAME ($USER_ID:$GROUP_ID)..."
    chown -R "$USER_ID:$GROUP_ID" /ros2_ws
else
    echo "Warning: /ros2_ws directory not found. Skipping chown."
fi

# Ensure home directory permissions
USER_HOME="/home/$USERNAME"
if [ -d "$USER_HOME" ]; then
    chown -R "$USER_ID:$GROUP_ID" "$USER_HOME"
    # Ensure .bashrc exists and has correct permissions
    BASHRC_FILE="$USER_HOME/.bashrc"
    if [ ! -f "$BASHRC_FILE" ]; then
        touch "$BASHRC_FILE"
        chown "$USER_ID:$GROUP_ID" "$BASHRC_FILE"
    fi

    echo "Updating $BASHRC_FILE for user $USERNAME..."

    # Lines to add to .bashrc
    # Using grep -qxF to add line only if it doesn't exist
    LINE_ROS_IP='export ROS_IP=$(ip route get 8.8.8.8 | awk -F'"'"'src '"'"' '"'"'NR==1{split($2,a," ");print a[1]}'"'"')'
    grep -qxF "$LINE_ROS_IP" "$BASHRC_FILE" || echo "$LINE_ROS_IP" >> "$BASHRC_FILE"

    # ROS_DISTRO should be available as an environment variable in the container
    # We write it as ${ROS_DISTRO} so it's evaluated when .bashrc is sourced
    LINE_ROS_SETUP="source /opt/ros/\${ROS_DISTRO}/setup.bash"
    grep -qxF "$LINE_ROS_SETUP" "$BASHRC_FILE" || echo "$LINE_ROS_SETUP" >> "$BASHRC_FILE"

    LINE_HARU_WS_SETUP="source /ros2_ws/install/setup.bash"
    grep -qxF "$LINE_HARU_WS_SETUP" "$BASHRC_FILE" || echo "$LINE_HARU_WS_SETUP" >> "$BASHRC_FILE"

    LINE_COLCON_ARGCOMPLETE="source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash"
    grep -qxF "$LINE_COLCON_ARGCOMPLETE" "$BASHRC_FILE" || echo "$LINE_COLCON_ARGCOMPLETE" >> "$BASHRC_FILE"

else
    echo "Warning: Home directory $USER_HOME not found for user $USERNAME."
fi

# Optionally, recompile the workspace as USERNAME
# if [ -d "/ros2_ws/src" ]; then # Check if src directory exists, indicating a workspace to build
#     echo "Recompiling workspace /ros2_ws as user $USERNAME..."
#     # Ensure ROS_DISTRO is available. It should be an environment variable in the container.
#     if [ -z "$ROS_DISTRO" ]; then
#         echo "Error: ROS_DISTRO environment variable is not set. Cannot determine ROS setup path for recompilation."
#         # Decide if you want to exit or attempt a default
#         exit 1 
#     fi

#     # Construct the command to run.
#     # 1. Source the main ROS distribution's setup file.
#     # 2. Source the user's .bashrc (which might add ROS_IP or source the local workspace).
#     # 3. Change to the workspace directory.
#     # 4. Execute colcon build.
#     # Using \${ROS_DISTRO} ensures it's expanded by the shell invoked by gosu, using the container's ENV.
#     COMMAND_TO_RUN="source /opt/ros/\${ROS_DISTRO}/setup.bash && \
#                     source \"/home/$USERNAME/.bashrc\" && \
#                     cd /ros2_ws && source ./install/setup.bash && \
#                     echo 'Attempting to build workspace /ros2_ws as user $USERNAME' && \
#                     echo 'Python3 path: '$(which python3) && \
#                     echo 'PYTHONPATH: '\${PYTHONPATH} && \
#                     colcon build --event-handlers console_direct+ --symlink-install"
    
#     echo "Executing recompilation command as $USERNAME: $COMMAND_TO_RUN" # For debugging

#     if gosu "$USERNAME" bash -c "$COMMAND_TO_RUN"; then
#         echo "Workspace recompiled successfully."
#     else
#         echo "Warning: Workspace recompilation failed. The container will continue with the existing build (if any)."
#         # Depending on requirements, you might want to exit here if build is critical:
#         # exit 1
#     fi
# elif [ -d "/ros2_ws" ]; then
#     echo "Info: /ros2_ws directory exists but /ros2_ws/src not found. Skipping recompilation."
# else
#     echo "Info: /ros2_ws directory not found. Skipping recompilation."
# fi

# Set ROS
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
echo "[INFO] Using ROS_DOMAIN_ID: $ROS_DOMAIN_ID"

# Source ROS 2 distro environment
source "/opt/ros/$ROS_DISTRO/setup.bash"

# Source workspace overlay, if exists
if [ -f "/ros2_ws/install/setup.bash" ]; then
    source "/ros2_ws/install/setup.bash"
fi

# Execute the command passed to the entrypoint (e.g., from CMD in Dockerfile or command in docker-compose)
# using gosu to drop privileges
echo "Executing command as user $USERNAME ($USER_ID:$GROUP_ID): $@"
exec gosu "$USERNAME" "$@"

# # Execute whatever command was passed to the container
# exec "$@"
