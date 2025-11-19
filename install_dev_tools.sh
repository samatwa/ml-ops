#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Configuration ---
LOG_FILE="install.log"
PYTHON_MIN_VERSION="3.9"
REQUIREMENTS=("torch" "torchvision" "pillow" "Django")

# --- Logging ---
# Redirect all output to both terminal and log file
exec &> >(tee -a "$LOG_FILE")

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1"
}

log "--- Starting DevOps & ML Environment Setup ---"

# --- Helper Functions ---

# Run apt-get update only once to avoid unnecessary repeated updates
APT_UPDATED=false
apt_update_once() {
  if [ "$APT_UPDATED" = false ]; then
    log "Running apt-get update..."
    sudo apt-get update
    APT_UPDATED=true
  fi
}

# Compare version numbers (e.g. 3.11.1 >= 3.9)
version_ge() {
  test "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" == "$2"
}

# --- Docker Installation ---
log "Checking for Docker..."
if ! command -v docker &> /dev/null; then
  log "Docker not found. Installing Docker..."

  apt_update_once
  sudo apt-get install -y ca-certificates curl

  # Create keyring directory if missing
  sudo install -m 0755 -d /etc/apt/keyrings

  # Install Docker GPG key if missing
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  # Add Docker repository (idempotent)
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Must update after adding a new repository
  log "Updating package lists after adding Docker repo..."
  sudo apt-get update

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

  log "Adding user to 'docker' group..."
  sudo usermod -aG docker "${USER}" || true
  log "Docker installed. Re-login may be required."
else
  log "Docker is already installed."
fi

log "Docker version:"
docker --version || log "Docker command may not work until re-login."

# --- Docker Compose Installation ---
log "Checking for Docker Compose..."

if command -v docker-compose &> /dev/null; then
  log "Docker Compose v1 is already installed."
  docker-compose --version

elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
  log "Docker Compose v2 plugin is already available."
  docker compose version | head -n 1

else
  log "Docker Compose not found. Installing docker-compose v1..."

  # Ensure curl exists
  if ! command -v curl &> /dev/null; then
    log "curl not found. Installing curl..."
    apt_update_once
    sudo apt-get install -y curl
  fi

  COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

  sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

  sudo chmod +x /usr/local/bin/docker-compose

  log "Docker Compose installed."
  docker-compose --version
fi

# --- Python Installation ---
log "Checking for Python installation..."

PYTHON_CMD="python3"

# Install Python if missing
if ! command -v "$PYTHON_CMD" &> /dev/null; then
  log "python3 not found. Installing Python $PYTHON_MIN_VERSION..."
  apt_update_once
  sudo apt-get install -y "python${PYTHON_MIN_VERSION}" python3-pip
fi

# Detect best Python interpreter (>= MIN_VERSION)
log "Detecting Python interpreter >= $PYTHON_MIN_VERSION ..."
CANDIDATES=()

# Add python3 if exists
if command -v python3 &> /dev/null; then
  CANDIDATES+=("python3")
fi

# Add pythonX.Y if matches minimum version
if command -v "python${PYTHON_MIN_VERSION}" &> /dev/null; then
  CANDIDATES+=("python${PYTHON_MIN_VERSION}")
fi

# Check common modern Python versions
for v in 3.12 3.11 3.10 3.9; do
  if command -v "python${v}" &> /dev/null; then
    CANDIDATES+=("python${v}")
  fi
done

BEST_PY=""

# Select the first interpreter that meets minimum version
for cmd in "${CANDIDATES[@]}"; do
  ver="$("$cmd" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')"
  if version_ge "$ver" "$PYTHON_MIN_VERSION"; then
    BEST_PY="$cmd"
    break
  fi
done

# Fallback
if [ -z "$BEST_PY" ]; then
  log "WARNING: No Python >= $PYTHON_MIN_VERSION found. Using python3 anyway."
  PYTHON_CMD="python3"
else
  PYTHON_CMD="$BEST_PY"
fi

log "Using Python interpreter: $PYTHON_CMD"
"$PYTHON_CMD" --version

# --- Pip Installation ---
log "Checking pip for $PYTHON_CMD..."

if ! "$PYTHON_CMD" -m pip --version &> /dev/null; then
  log "pip not found. Installing python3-pip..."
  apt_update_once
  sudo apt-get install -y python3-pip
fi

log "pip version:"
"$PYTHON_CMD" -m pip --version

# --- Python Libraries Installation ---
log "Installing required Python packages..."

for lib in "${REQUIREMENTS[@]}"; do
  if "$PYTHON_CMD" -m pip show "$lib" &> /dev/null; then
    log "$lib is already installed."
  else
    log "Installing $lib..."
    "$PYTHON_CMD" -m pip install "$lib"
    log "$lib installed."
  fi

  "$PYTHON_CMD" -m pip show "$lib" | head -n 3 || true
done

# --- Summary ---
log "============== Summary =============="

docker --version || log "Docker not available"
if command -v docker-compose &> /dev/null; then
  docker-compose --version
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
  docker compose version | head -n 1
else
  log "Docker Compose not installed"
fi

"$PYTHON_CMD" --version
"$PYTHON_CMD" -m pip --version

for lib in "${REQUIREMENTS[@]}"; do
  "$PYTHON_CMD" -m pip show "$lib" | head -n 2 || log "$lib not installed"
done

log "--- Environment setup completed successfully! ---"
