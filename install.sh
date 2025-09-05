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

# Check basic dependencies
check_basic_dependencies() {
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
check_gemini_cli() {
    print_info "Checking Gemini CLI installation..."
    
    if ! command -v gemini &> /dev/null; then
        print_warning "Gemini CLI not found"
        echo ""
        print_info "Installing Gemini CLI is required for AI Code Review Tool"
        print_info "Please visit: https://github.com/google/generative-ai-cli"
        echo ""
        read -p "Have you installed Gemini CLI? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Gemini CLI is required. Please install it first."
            print_info "Installation instructions: https://github.com/google/generative-ai-cli"
            exit 1
        fi
        
        # Check again after user confirmation
        if ! command -v gemini &> /dev/null; then
            print_error "Gemini CLI still not found. Please ensure it's properly installed and in PATH."
            exit 1
        fi
    fi
    
    print_success "Gemini CLI found"
}

# Setup Google Cloud Project
setup_google_cloud() {
    print_info "Setting up Google Cloud Project..."
    
    if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
        echo ""
        print_warning "GOOGLE_CLOUD_PROJECT environment variable not set"
        read -p "Enter your Google Cloud Project ID: " project_id
        
        if [ -z "$project_id" ]; then
            print_error "Google Cloud Project ID is required"
            exit 1
        fi
        
        # Add to shell config
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
        
        echo "" >> "$shell_config"
        echo "# Google Cloud Project for AI Code Review Tool" >> "$shell_config"
        echo "export GOOGLE_CLOUD_PROJECT=\"$project_id\"" >> "$shell_config"
        export GOOGLE_CLOUD_PROJECT="$project_id"
        
        print_success "Google Cloud Project ID saved: $project_id"
    else
        print_success "Google Cloud Project already set: $GOOGLE_CLOUD_PROJECT"
    fi
}

# Verify authentication
verify_authentication() {
    print_info "Verifying Google Cloud authentication..."
    
    if ! gemini -p "test" &> /dev/null; then
        print_warning "Gemini authentication failed"
        echo ""
        print_info "Please authenticate with Google Cloud:"
        print_info "Run: gcloud auth login"
        echo ""
        read -p "Have you completed authentication? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Authentication is required. Please run: gcloud auth login"
            exit 1
        fi
        
        # Test again
        if ! gemini -p "test" &> /dev/null; then
            print_error "Authentication still failed. Please ensure you're properly logged in."
            print_info "Try running: gcloud auth login"
            exit 1
        fi
    fi
    
    print_success "Authentication verified"
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
    else
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
    fi
    
    # Add convenient aliases
    setup_aliases
}

# Setup convenient aliases
setup_aliases() {
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
    
    # Check if aliases already exist
    if ! grep -q "alias cr=" "$shell_config" 2>/dev/null; then
        print_info "Adding convenient aliases to $shell_config"
        echo "" >> "$shell_config"
        echo "# AI Code Review Tool aliases" >> "$shell_config"
        echo "alias cr='ai-code-review'" >> "$shell_config"
        echo "alias code-review='ai-code-review'" >> "$shell_config"
        echo "alias review='ai-code-review'" >> "$shell_config"
        
        print_success "Added aliases: cr, code-review, review"
    else
        print_info "Aliases already exist in $shell_config"
    fi
    
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
    print_success "AI Code Review Tool is ready to use!"
    echo ""
    print_info "Usage examples:"
    echo "  ${SCRIPT_NAME} --target main"
    echo "  cr --target main                    # Short alias"
    echo "  review --target develop --no-save   # Alternative alias"
    echo "  ${SCRIPT_NAME} --target main --save-to review.md"
    echo "  ${SCRIPT_NAME} --target main --convention team-convention.md"
    echo "  ${SCRIPT_NAME} --target main --language vi"
    echo ""
    print_info "Available aliases:"
    echo "  cr           → ai-code-review"
    echo "  code-review  → ai-code-review"
    echo "  review       → ai-code-review"
    echo ""
    print_info "For help: ${SCRIPT_NAME} --help"
}

# Main installation function
main() {
    print_header "Installing AI Code Review Tool v${VERSION}"
    echo ""
    
    check_os
    check_basic_dependencies
    check_gemini_cli
    setup_google_cloud
    create_install_dir
    install_script
    setup_path
    verify_installation
    verify_authentication
    show_usage
}

# Run main function
main "$@"
