#!/usr/bin/env bash
#
# first-time-install-ansible.sh
# Bootstrap script to install Ansible using uv
#
# Usage: ./first-time-install-ansible.sh [--venv PATH]
#
# Options:
#   --venv PATH    Path to venv (default: ~/.ansible-venv)
#
# This script:
#   1. Installs uv (if not already installed)
#   2. Creates a Python venv at ~/.ansible-venv/
#   3. Installs Ansible and ansible-lint in the venv
#   4. Installs Ansible Galaxy roles and collections (if requirements.yml exists)
#

set -e

VENV_PATH="${VENV_PATH:-$HOME/.ansible-venv}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --venv)
            VENV_PATH="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--venv PATH]"
            echo ""
            echo "Options:"
            echo "  --venv PATH    Path to venv (default: ~/.ansible-venv)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== First-time Ansible Installation ==="
echo "Venv path: $VENV_PATH"
echo ""

# Function to install uv
install_uv() {
    echo "Checking for uv..."

    # Check if uv is already available
    if command -v uv &> /dev/null; then
        echo "  uv found: $(uv --version)"
        return 0
    fi

    echo "  uv not found, installing..."

    # Try to install uv based on available package manager
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu - install from official repo or pip
        echo "  Installing uv via pip..."
        if command -v pip3 &> /dev/null; then
            pip3 install uv
        elif command -v pip &> /dev/null; then
            pip install uv
        else
            # Fallback to official installer
            echo "  Installing uv via official installer..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
    elif command -v brew &> /dev/null; then
        # macOS
        echo "  Installing uv via Homebrew..."
        brew install uv
    elif command -v pip3 &> /dev/null; then
        # Direct pip install
        echo "  Installing uv via pip..."
        pip3 install uv
    elif command -v pip &> /dev/null; then
        echo "  Installing uv via pip..."
        pip install uv
    else
        # Fallback: use official installer
        echo "  Installing uv via official installer..."
        # Download and run installer
        TMP_DIR=$(mktemp -d)
        curl -LsSf -o "$TMP_DIR/install.sh" https://astral.sh/uv/install.sh
        sh "$TMP_DIR/install.sh"
        rm -rf "$TMP_DIR"
    fi

    # Add uv to PATH for this session
    if [ -f "$HOME/.local/bin/uv" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    elif [ -f "$HOME/.cargo/bin/uv" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Verify installation
    if command -v uv &> /dev/null; then
        echo "  uv installed successfully: $(uv --version)"
    else
        echo "ERROR: uv installation failed"
        exit 1
    fi
}

# Ensure uv is installed
install_uv

# Create venv if it doesn't exist
if [ -d "$VENV_PATH" ]; then
    echo "Venv already exists at: $VENV_PATH"
else
    echo "Creating venv at: $VENV_PATH"
    uv venv "$VENV_PATH"
fi

# Install Ansible and ansible-lint
echo "Installing Ansible and ansible-lint..."
uv pip install --python "$VENV_PATH/bin/python" ansible ansible-lint

# Install Ansible Galaxy roles and collections if requirements.yml exists
if [ -f "requirements.yml" ]; then
    echo "Installing Ansible Galaxy roles and collections..."
    mkdir -p roles/
    "$VENV_PATH/bin/ansible-galaxy" role install -p roles -r requirements.yml
    "$VENV_PATH/bin/ansible-galaxy" collection install -r requirements.yml
else
    echo "No requirements.yml found, skipping Galaxy install"
fi

# Verify installation
ANSIBLE_BIN="$VENV_PATH/bin/ansible"
if [ -f "$ANSIBLE_BIN" ]; then
    echo ""
    echo "=== Installation Complete ==="
    echo "Ansible installed: $($ANSIBLE_BIN --version | head -n 1)"
    echo "Ansible-lint installed: $($VENV_PATH/bin/ansible-lint --version | head -n 1)"
    echo ""
    echo "To run playbooks, use:"
    echo "  $ANSIBLE_BIN-playbook site.yml"
    echo ""
    echo "Or add to your shell profile:"
    echo "  export PATH=\"$VENV_PATH/bin:\$PATH\""
else
    echo "ERROR: Ansible installation failed"
    exit 1
fi
