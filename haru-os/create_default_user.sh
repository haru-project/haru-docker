echo "CREATE DEFAULT USER SCRIPT EXECUTION FOR user change STARTED AT $(date)"

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

# Add user to relevant groups for sound and hardware access
echo "Adding user $USERNAME to audio, pulse, and pulse-access groups..."
if getent group audio >/dev/null; then
    usermod -aG audio "$USERNAME"
else
    echo "Warning: group audio not found. Creating audio group."
    groupadd audio
    usermod -aG audio "$USERNAME"
fi
if getent group pulse >/dev/null; then
    usermod -aG pulse "$USERNAME"
else
    echo "Warning: group pulse not found. Sound might be affected."
fi
if getent group pulse-access >/dev/null; then
    usermod -aG pulse-access "$USERNAME"
else
    echo "Warning: group pulse-access not found. Sound might be affected."
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