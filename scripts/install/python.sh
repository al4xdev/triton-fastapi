PROJECT_ROOT="$(dirname "$(dirname "$0")")"
MIDDLEWARE_DIR="$PROJECT_ROOT/middleware/src"
MIDDLEWARE_VENV_DIR="$MIDDLEWARE_DIR/.venv"

set -euo pipefail

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - python.sh: $1"
}
xport PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

log_step "Installing Python 3 and development headers..."
sudo apt-get install -y python3

log_step "Installing uv (Python package installer and manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

if command -v uv &> /dev/null; then
    log_step "uv installed successfully. Version: $(uv --version)"
else
    log_step "ERROR: uv installation failed. Please check internet connection or permissions."
    exit 1
fi

log_step "Creating Python virtual environment for middleware using uv..."

uv venv --python 3.11 "$MIDDLEWARE_VENV_DIR"

if [ -d "$MIDDLEWARE_VENV_DIR" ]; then
    log_step "Virtual environment created at: $MIDDLEWARE_VENV_DIR"
else
    log_step "ERROR: Failed to create virtual environment for middleware."
    exit 1
fi

log_step "Activating virtual environment and installing middleware dependencies..."
source "$MIDDLEWARE_VENV_DIR/bin/activate"

log_step "Installing dependencies from middleware/pyproject.toml and uv.lock..."
if uv sync; then
    log_step "Middleware dependencies installed successfully."
else
    log_step "ERROR: Failed to install middleware dependencies using uv sync."
    exit 1
fi

deactivate

log_step "Python environment setup complete."

