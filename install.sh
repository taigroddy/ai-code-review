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
        print_info "The AI Code Review Tool requires Gemini CLI to function."
        print_info "We can help you install it now."
        echo ""
        
        # Detect OS for installation
        case "$(uname -s)" in
            Darwin*)
                print_info "macOS detected. Installation options:"
                echo "  1. Install via Homebrew (recommended)"
                echo "  2. Install manually"
                echo "  3. Skip (I'll install it myself)"
                echo ""
                read -p "Choose option (1-3): " -n 1 -r
                echo ""
                
                case $REPLY in
                    1)
                        print_info "Installing Gemini CLI via Homebrew..."
                        if command -v brew &> /dev/null; then
                            if brew install gemini-cli; then
                                print_success "Gemini CLI installed successfully via Homebrew"
                            else
                                print_warning "Homebrew installation failed, trying alternative method..."
                                # Try npm installation as fallback
                                if command -v npm &> /dev/null; then
                                    print_info "Installing via npm..."
                                    npm install -g gemini-cli
                                else
                                    print_error "Failed to install via Homebrew and npm not available"
                                    print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                                    exit 1
                                fi
                            fi
                        else
                            print_error "Homebrew not found. Please install Homebrew first or choose option 2."
                            exit 1
                        fi
                        ;;
                    2)
                        print_info "Manual installation instructions:"
                        echo "1. Visit: https://github.com/google-gemini/gemini-cli"
                        echo "2. Download the latest release for macOS"
                        echo "3. Install and ensure it's in your PATH"
                        echo ""
                        read -p "Press Enter when installation is complete..."
                        ;;
                    3)
                        print_warning "Skipping Gemini CLI installation"
                        print_info "Please install it manually: https://github.com/google-gemini/gemini-cli"
                        exit 1
                        ;;
                    *)
                        print_error "Invalid option"
                        exit 1
                        ;;
                esac
                ;;
            Linux*)
                print_info "Linux detected. Installation options:"
                echo "  1. Install via package manager"
                echo "  2. Install manually"
                echo "  3. Skip (I'll install it myself)"
                echo ""
                read -p "Choose option (1-3): " -n 1 -r
                echo ""
                
                case $REPLY in
                    1)
                        print_info "Installing Gemini CLI via package manager..."
                        
                        # Try different package managers
                        if command -v curl &> /dev/null && command -v tar &> /dev/null; then
                            print_info "Downloading and installing Gemini CLI..."
                            
                            # Create temp directory
                            TEMP_DIR=$(mktemp -d)
                            cd "$TEMP_DIR"
                            
                            # Detect architecture
                            ARCH=$(uname -m)
                            case $ARCH in
                                x86_64)
                                    ARCH="amd64"
                                    ;;
                                aarch64|arm64)
                                    ARCH="arm64"
                                    ;;
                                *)
                                    print_error "Unsupported architecture: $ARCH"
                                    exit 1
                                    ;;
                            esac
                            
                            # Download latest release
                            DOWNLOAD_URL="https://github.com/google-gemini/gemini-cli/releases/latest/download/gemini-cli-linux-${ARCH}.tar.gz"
                            print_info "Downloading from: $DOWNLOAD_URL"
                            
                            if curl -fsSL "$DOWNLOAD_URL" -o gemini-cli.tar.gz; then
                                tar -xzf gemini-cli.tar.gz
                                
                                # Install to /usr/local/bin
                                if sudo mv gemini /usr/local/bin/; then
                                    sudo chmod +x /usr/local/bin/gemini
                                    print_success "Gemini CLI installed successfully to /usr/local/bin/gemini"
                                else
                                    # Fallback to user bin
                                    mkdir -p "$HOME/.local/bin"
                                    mv gemini "$HOME/.local/bin/"
                                    chmod +x "$HOME/.local/bin/gemini"
                                    print_success "Gemini CLI installed successfully to $HOME/.local/bin/gemini"
                                fi
                            else
                                print_error "Failed to download Gemini CLI"
                                print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                                exit 1
                            fi
                            
                            # Cleanup
                            cd - > /dev/null
                            rm -rf "$TEMP_DIR"
                            
                        elif command -v apt &> /dev/null; then
                            print_info "Trying apt package manager..."
                            # Note: This might not work as the package might not be in official repos
                            print_warning "Official apt package not available, using direct download method..."
                            
                            # Fallback to direct download
                            TEMP_DIR=$(mktemp -d)
                            cd "$TEMP_DIR"
                            ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
                            DOWNLOAD_URL="https://github.com/google-gemini/gemini-cli/releases/latest/download/gemini-cli-linux-${ARCH}.tar.gz"
                            
                            if curl -fsSL "$DOWNLOAD_URL" -o gemini-cli.tar.gz && tar -xzf gemini-cli.tar.gz; then
                                sudo mv gemini /usr/local/bin/ && sudo chmod +x /usr/local/bin/gemini
                                print_success "Gemini CLI installed successfully"
                            else
                                print_error "Installation failed"
                                print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                                exit 1
                            fi
                            
                            cd - > /dev/null && rm -rf "$TEMP_DIR"
                            
                        elif command -v yum &> /dev/null; then
                            print_info "Using direct download for RHEL/CentOS..."
                            
                            TEMP_DIR=$(mktemp -d)
                            cd "$TEMP_DIR"
                            ARCH=$(uname -m)
                            [[ $ARCH == "x86_64" ]] && ARCH="amd64"
                            DOWNLOAD_URL="https://github.com/google-gemini/gemini-cli/releases/latest/download/gemini-cli-linux-${ARCH}.tar.gz"
                            
                            if curl -fsSL "$DOWNLOAD_URL" -o gemini-cli.tar.gz && tar -xzf gemini-cli.tar.gz; then
                                sudo mv gemini /usr/local/bin/ && sudo chmod +x /usr/local/bin/gemini
                                print_success "Gemini CLI installed successfully"
                            else
                                print_error "Installation failed"
                                print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                                exit 1
                            fi
                            
                            cd - > /dev/null && rm -rf "$TEMP_DIR"
                            
                        elif command -v snap &> /dev/null; then
                            print_info "Trying snap installation..."
                            if sudo snap install gemini-cli; then
                                print_success "Gemini CLI installed via snap"
                            else
                                print_error "Snap installation failed"
                                print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                                exit 1
                            fi
                        else
                            print_error "No supported installation method found"
                            print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                            exit 1
                        fi
                        ;;
                    2)
                        print_info "Manual installation instructions:"
                        echo "1. Visit: https://github.com/google-gemini/gemini-cli"
                        echo "2. Download the latest release for Linux"
                        echo "3. Install and ensure it's in your PATH"
                        echo ""
                        read -p "Press Enter when installation is complete..."
                        ;;
                    3)
                        print_warning "Skipping Gemini CLI installation"
                        print_info "Please install it manually: https://github.com/google-gemini/gemini-cli"
                        exit 1
                        ;;
                    *)
                        print_error "Invalid option"
                        exit 1
                        ;;
                esac
                ;;
            *)
                print_info "Unsupported OS for automatic installation"
                print_info "Attempting universal installation method..."
                echo ""
                
                # Universal installation method using GitHub releases
                TEMP_DIR=$(mktemp -d)
                cd "$TEMP_DIR"
                
                # Detect OS and architecture
                OS=$(uname -s | tr '[:upper:]' '[:lower:]')
                ARCH=$(uname -m)
                
                case $ARCH in
                    x86_64)
                        ARCH="amd64"
                        ;;
                    aarch64|arm64)
                        ARCH="arm64"
                        ;;
                    *)
                        print_error "Unsupported architecture: $ARCH"
                        print_info "Please install manually: https://github.com/google/generative-ai-cli"
                        exit 1
                        ;;
                esac
                
                # Construct download URL
                FILENAME="gemini-cli-${OS}-${ARCH}"
                if [[ "$OS" == "windows" ]]; then
                    FILENAME="${FILENAME}.exe"
                else
                    FILENAME="${FILENAME}.tar.gz"
                fi
                
                DOWNLOAD_URL="https://github.com/google-gemini/gemini-cli/releases/latest/download/${FILENAME}"
                print_info "Downloading from: $DOWNLOAD_URL"
                
                if curl -fsSL "$DOWNLOAD_URL" -o "gemini-cli.${FILENAME##*.}"; then
                    if [[ "$OS" == "windows" ]]; then
                        # Windows executable
                        mkdir -p "$HOME/bin"
                        mv "gemini-cli.exe" "$HOME/bin/gemini.exe"
                        chmod +x "$HOME/bin/gemini.exe"
                        print_success "Gemini CLI installed to $HOME/bin/gemini.exe"
                        print_info "Add $HOME/bin to your PATH"
                    else
                        # Unix-like system with tar.gz
                        tar -xzf "gemini-cli.tar.gz"
                        
                        # Try to install to system directory first, fallback to user directory
                        if sudo mv gemini /usr/local/bin/ 2>/dev/null && sudo chmod +x /usr/local/bin/gemini; then
                            print_success "Gemini CLI installed to /usr/local/bin/gemini"
                        else
                            mkdir -p "$HOME/.local/bin"
                            mv gemini "$HOME/.local/bin/"
                            chmod +x "$HOME/.local/bin/gemini"
                            print_success "Gemini CLI installed to $HOME/.local/bin/gemini"
                        fi
                    fi
                else
                    print_error "Failed to download Gemini CLI"
                    print_info "Please install manually: https://github.com/google-gemini/gemini-cli"
                    exit 1
                fi
                
                # Cleanup
                cd - > /dev/null
                rm -rf "$TEMP_DIR"
                ;;
        esac
        
        # Check again after installation attempt
        print_info "Verifying Gemini CLI installation..."
        
        # Refresh PATH and check multiple times
        export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:$HOME/bin"
        hash -r  # Refresh command hash table
        
        # Also try common snap paths
        if [ -d "/snap/bin" ]; then
            export PATH="$PATH:/snap/bin"
        fi
        
        local attempts=0
        local max_attempts=5
        
        while [ $attempts -lt $max_attempts ]; do
            # Try multiple possible command names
            if command -v gemini &> /dev/null || command -v generative-ai-cli &> /dev/null; then
                # Check which command works
                if command -v gemini &> /dev/null; then
                    print_success "Gemini CLI found as 'gemini'!"
                    break
                elif command -v generative-ai-cli &> /dev/null; then
                    print_success "Gemini CLI found as 'generative-ai-cli'!"
                    # Create a symlink for consistency
                    if [ -w "/usr/local/bin" ]; then
                        sudo ln -sf "$(which generative-ai-cli)" /usr/local/bin/gemini
                    elif [ -d "$HOME/.local/bin" ]; then
                        ln -sf "$(which generative-ai-cli)" "$HOME/.local/bin/gemini"
                    fi
                    print_info "Created 'gemini' alias for convenience"
                    break
                fi
            fi
            
            attempts=$((attempts + 1))
            print_info "Attempt $attempts/$max_attempts: Gemini CLI not found yet..."
            
            if [ $attempts -lt $max_attempts ]; then
                print_info "Troubleshooting steps:"
                echo "  - Checking installation completion..."
                echo "  - Refreshing command cache..."
                echo "  - Checking common installation paths..."
                
                # Try to find the binary in common locations
                for path in "/usr/local/bin/gemini" "/usr/bin/gemini" "$HOME/.local/bin/gemini" "$HOME/bin/gemini" "/snap/bin/gemini-cli"; do
                    if [ -x "$path" ]; then
                        print_info "Found Gemini CLI at: $path"
                        export PATH="$(dirname "$path"):$PATH"
                        break
                    fi
                done
                
                echo ""
                read -p "Press Enter to try again (or Ctrl+C to exit)..."
                
                # Re-hash commands
                hash -r
            fi
        done
        
        if ! command -v gemini &> /dev/null && ! command -v generative-ai-cli &> /dev/null; then
            print_error "Gemini CLI installation verification failed"
            print_info "Troubleshooting steps:"
            echo "  1. Check if installation completed successfully"
            echo "  2. Verify the binary is in your PATH:"
            echo "     - /usr/local/bin"
            echo "     - $HOME/.local/bin"
            echo "     - /snap/bin"
            echo "  3. Try running: which gemini"
            echo "  4. Try running: find /usr -name '*gemini*' 2>/dev/null"
            echo "  5. Restart your terminal and try again"
            echo "  6. Manual installation: https://github.com/google-gemini/gemini-cli"
            exit 1
        fi
    else
        print_success "Gemini CLI found"
    fi
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
    print_info "Verifying Gemini CLI authentication..."
    if gemini -p "test" &> /dev/null; then
        print_success "Authentication verified"
    else
        print_warning "Gemini authentication failed. Please run 'gemini' to authenticate."
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
    
    # Also add to current session for immediate use
    alias cr='ai-code-review' 2>/dev/null
    alias code-review='ai-code-review' 2>/dev/null
    alias review='ai-code-review' 2>/dev/null
    
    print_warning "Please restart your terminal or run: source $shell_config"
    print_info "Or use the full path: ${INSTALL_DIR}/${SCRIPT_NAME}"
}

# Verify installation
verify_installation() {
    if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
        print_success "Installation successful!"
        print_info "AI Code Review Tool installed to: ${INSTALL_DIR}/${SCRIPT_NAME}"
        
        # Test if the command is accessible
        print_info "Testing command accessibility..."
        if command -v "${SCRIPT_NAME}" &> /dev/null; then
            print_success "Command '${SCRIPT_NAME}' is accessible in PATH"
        else
            print_warning "Command '${SCRIPT_NAME}' not found in current PATH"
            print_info "Current PATH: $PATH"
            print_info "Install directory: ${INSTALL_DIR}"
            
            # Check if install dir is in PATH
            if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
                print_info "Install directory is in PATH, but command not found"
                print_info "This might be resolved after restarting your terminal"
            else
                print_warning "Install directory not in current PATH"
                print_info "Adding to current session PATH..."
                export PATH="$PATH:$INSTALL_DIR"
                
                if command -v "${SCRIPT_NAME}" &> /dev/null; then
                    print_success "Command accessible after PATH update"
                else
                    print_error "Command still not accessible"
                fi
            fi
        fi
    else
        print_error "Installation failed - executable not found at ${INSTALL_DIR}/${SCRIPT_NAME}"
        exit 1
    fi
}

# Test installation and provide troubleshooting
test_installation() {
    print_info "Running installation tests..."
    echo ""
    
    # Test 1: Check if file exists and is executable
    if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
        print_success "✓ Binary exists and is executable"
    else
        print_error "✗ Binary not found or not executable"
        return 1
    fi
    
    # Test 2: Check if install directory is in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        print_success "✓ Install directory is in PATH"
    else
        print_warning "⚠ Install directory not in current PATH"
        export PATH="$PATH:$INSTALL_DIR"
        print_info "Added to current session PATH"
    fi
    
    # Test 3: Check if command is accessible
    if command -v "${SCRIPT_NAME}" &> /dev/null; then
        print_success "✓ Command is accessible"
        
        # Test 4: Try to run --version
        if "${SCRIPT_NAME}" --version &> /dev/null; then
            print_success "✓ Command executes successfully"
        else
            print_warning "⚠ Command found but execution failed"
        fi
    else
        print_warning "⚠ Command not accessible in current session"
        print_info "This will be resolved after restarting terminal or sourcing shell config"
    fi
    
    # Test 5: Check aliases
    if alias cr &> /dev/null; then
        print_success "✓ Aliases are active in current session"
    else
        print_warning "⚠ Aliases not active in current session"
    fi
    
    echo ""
    print_info "Installation test complete!"
}

# Show usage instructions
show_usage() {
    echo ""
    print_header "🎉 Installation Complete!"
    echo ""
    print_success "AI Code Review Tool is ready to use!"
    echo ""
    
    # Test command availability and provide specific instructions
    if command -v "${SCRIPT_NAME}" &> /dev/null; then
        print_success "Command '${SCRIPT_NAME}' is ready to use!"
        print_info "Usage examples:"
        echo "  ${SCRIPT_NAME} --target main"
        echo "  cr --target main                    # Short alias"
        echo "  review --target develop --no-save   # Alternative alias"
    else
        print_warning "Command not immediately available. Choose one option:"
        echo ""
        print_info "Option 1: Restart your terminal and then use:"
        echo "  ${SCRIPT_NAME} --target main"
        echo "  cr --target main"
        echo ""
        print_info "Option 2: Source your shell config:"
        
        case "$SHELL" in
            */zsh)
                echo "  source ~/.zshrc"
                ;;
            */bash)
                echo "  source ~/.bashrc"
                ;;
            */fish)
                echo "  source ~/.config/fish/config.fish"
                ;;
            *)
                echo "  source ~/.profile"
                ;;
        esac
        
        echo ""
        print_info "Option 3: Use full path immediately:"
        echo "  ${INSTALL_DIR}/${SCRIPT_NAME} --target main"
    fi
    
    echo ""
    print_info "More usage examples:"
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
    print_info "Full path: ${INSTALL_DIR}/${SCRIPT_NAME} --help"
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
    test_installation
    show_usage
}

# Run main function
main "$@"
