#!/bin/bash

# AI Code Review Tool Installer
# Usage: sh -c "`curl -fsSL https://raw.githubusercontent.com/taigroddy/ai-code-review/main/install.sh`"

set -e

VERSION="0.0.1"
REPO_URL="https://raw.githubusercontent.com/taigroddy/ai-code-review/main"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="ai-code-review"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

# Check if running on supported OS
check_os() {
    case "$(uname -s)" in
        Darwin*) 
            print_info "Detected macOS"
            ;;
        Linux*)  
            print_info "Detected Linux"
            ;;
        *)       
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and try again"
        exit 1
    fi
}

# Create install directory
create_install_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "Creating install directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
}

# Download and install the script
install_script() {
    print_info "Downloading AI Code Review Tool v${VERSION}..."
    
    # Download the main script
    if curl -fsSL "${REPO_URL}/code-review.sh" > "${INSTALL_DIR}/${SCRIPT_NAME}"; then
        print_success "Downloaded successfully"
    else
        print_error "Failed to download the script"
        exit 1
    fi
    
    # Make it executable
    chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
    print_success "Made script executable"
}

# Add to PATH if needed
setup_path() {
    # Check if install dir is already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        print_info "Install directory already in PATH"
        return
    fi
    
    # Determine shell config file
    local shell_config=""
    case "$SHELL" in
        */zsh)
            shell_config="$HOME/.zshrc"
            ;;
        */bash)
            shell_config="$HOME/.bashrc"
            ;;
        */fish)
            shell_config="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_config="$HOME/.profile"
            ;;
    esac
    
    # Add to PATH
    print_info "Adding $INSTALL_DIR to PATH in $shell_config"
    echo "" >> "$shell_config"
    echo "# Added by AI Code Review Tool installer" >> "$shell_config"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_config"
    
    print_warning "Please restart your terminal or run: source $shell_config"
}

# Verify installation
verify_installation() {
    if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
        print_success "Installation successful!"
        print_info "AI Code Review Tool installed to: ${INSTALL_DIR}/${SCRIPT_NAME}"
    else
        print_error "Installation failed"
        exit 1
    fi
}

# Show usage instructions
show_usage() {
    echo ""
    print_header "🎉 Installation Complete!"
    echo ""
    print_info "Usage examples:"
    echo "  ${SCRIPT_NAME} --target main"
    echo "  ${SCRIPT_NAME} --target develop --no-save"
    echo "  ${SCRIPT_NAME} --target main --save-to review.md"
    echo "  ${SCRIPT_NAME} --target main --convention team-convention.md"
    echo "  ${SCRIPT_NAME} --setup"
    echo ""
    print_info "For help: ${SCRIPT_NAME} --help"
    echo ""
    print_warning "Don't forget to:"
    echo "  1. Install Gemini CLI: https://github.com/google/generative-ai-cli"
    echo "  2. Set GOOGLE_CLOUD_PROJECT environment variable"
    echo "  3. Run: gcloud auth login"
    echo "  4. Or use: ${SCRIPT_NAME} --setup"
}

# Main installation function
main() {
    print_header "Installing AI Code Review Tool v${VERSION}"
    echo ""
    
    check_os
    check_dependencies
    create_install_dir
    install_script
    setup_path
    verify_installation
    show_usage
}

# Run main function
main "$@"
