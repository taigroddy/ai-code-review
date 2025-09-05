#!/bin/bash

# AI Code Review Tool Troubleshooting Script
# Usage: bash troubleshoot.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}❌ $1${NC}"
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
    echo -e "${PURPLE}🔧 $1${NC}"
}

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="ai-code-review"

print_header "AI Code Review Tool Troubleshooting"
echo ""

# Check 1: Binary exists
print_info "1. Checking if binary exists..."
if [ -f "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
    print_success "Binary found at: ${INSTALL_DIR}/${SCRIPT_NAME}"
    
    if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
        print_success "Binary is executable"
    else
        print_warning "Binary exists but is not executable"
        print_info "Fix: chmod +x ${INSTALL_DIR}/${SCRIPT_NAME}"
    fi
else
    print_error "Binary not found at: ${INSTALL_DIR}/${SCRIPT_NAME}"
    print_info "Fix: Re-run the installer"
    echo "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/taigroddy/ai-code-review/main/install.sh)\""
fi

echo ""

# Check 2: PATH configuration
print_info "2. Checking PATH configuration..."
print_info "Current PATH: $PATH"

if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    print_success "Install directory is in PATH"
else
    print_warning "Install directory NOT in PATH"
    print_info "Current session fix: export PATH=\"\$PATH:$INSTALL_DIR\""
    
    # Check shell config files
    case "$SHELL" in
        */zsh)
            config_file="$HOME/.zshrc"
            ;;
        */bash)
            config_file="$HOME/.bashrc"
            ;;
        */fish)
            config_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            config_file="$HOME/.profile"
            ;;
    esac
    
    print_info "Checking shell config: $config_file"
    if [ -f "$config_file" ] && grep -q "$INSTALL_DIR" "$config_file"; then
        print_warning "PATH entry exists in config but not active"
        print_info "Fix: source $config_file"
    else
        print_warning "PATH entry missing from config"
        print_info "Fix: echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> $config_file"
    fi
fi

echo ""

# Check 3: Command accessibility
print_info "3. Checking command accessibility..."
if command -v "$SCRIPT_NAME" &> /dev/null; then
    print_success "Command '$SCRIPT_NAME' is accessible"
    
    # Try to get version
    if version_output=$("$SCRIPT_NAME" --version 2>&1); then
        print_success "Command executes successfully"
        print_info "Version: $version_output"
    else
        print_warning "Command found but execution failed"
        print_info "Error output: $version_output"
    fi
else
    print_warning "Command '$SCRIPT_NAME' not accessible"
    
    # Try with full path
    if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
        print_info "Binary exists, trying full path..."
        if version_output=$("${INSTALL_DIR}/${SCRIPT_NAME}" --version 2>&1); then
            print_success "Full path works: ${INSTALL_DIR}/${SCRIPT_NAME}"
            print_info "Issue is PATH related"
        else
            print_error "Full path also fails"
            print_info "Error: $version_output"
        fi
    fi
fi

echo ""

# Check 4: Aliases
print_info "4. Checking aliases..."
aliases_working=0

for alias_name in cr code-review review; do
    if alias "$alias_name" &> /dev/null; then
        print_success "Alias '$alias_name' is active"
        aliases_working=$((aliases_working + 1))
    else
        print_warning "Alias '$alias_name' not found"
    fi
done

if [ $aliases_working -eq 0 ]; then
    print_warning "No aliases are active"
    case "$SHELL" in
        */zsh)
            config_file="$HOME/.zshrc"
            ;;
        */bash)
            config_file="$HOME/.bashrc"
            ;;
        */fish)
            config_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            config_file="$HOME/.profile"
            ;;
    esac
    
    if [ -f "$config_file" ] && grep -q "alias cr=" "$config_file"; then
        print_info "Aliases exist in config but not active"
        print_info "Fix: source $config_file"
    else
        print_info "Aliases missing from config"
        print_info "Fix: Re-run installer or add manually"
    fi
fi

echo ""

# Check 5: Dependencies
print_info "5. Checking dependencies..."

if command -v gemini &> /dev/null; then
    print_success "Gemini CLI found"
    
    if [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
        print_success "GOOGLE_CLOUD_PROJECT is set: $GOOGLE_CLOUD_PROJECT"
        
        if gemini -p "test" &> /dev/null; then
            print_success "Gemini authentication works"
        else
            print_warning "Gemini authentication failed"
            print_info "Fix: gemini"
        fi
    else
        print_warning "GOOGLE_CLOUD_PROJECT not set"
        print_info "Fix: export GOOGLE_CLOUD_PROJECT=\"your-project-id\""
    fi
else
    print_error "Gemini CLI not found"
    print_info "Install from: https://github.com/google-gemini/gemini-cli"
fi

if command -v git &> /dev/null; then
    print_success "Git found"
else
    print_error "Git not found"
    print_info "Install Git first"
fi

echo ""

# Summary and recommendations
print_header "🎯 Summary & Recommendations"
echo ""

if command -v "$SCRIPT_NAME" &> /dev/null && [ $aliases_working -gt 0 ]; then
    print_success "Everything looks good! Your installation is working."
    print_info "Try: cr --target main"
else
    print_warning "Issues detected. Quick fixes:"
    echo ""
    
    # Provide shell-specific fix
    case "$SHELL" in
        */zsh)
            config_file="$HOME/.zshrc"
            ;;
        */bash)
            config_file="$HOME/.bashrc"
            ;;
        */fish)
            config_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            config_file="$HOME/.profile"
            ;;
    esac
    
    print_info "Quick fix (run these commands):"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\""
    echo "alias cr='ai-code-review'"
    echo "alias code-review='ai-code-review'" 
    echo "alias review='ai-code-review'"
    echo ""
    print_info "Permanent fix:"
    echo "source $config_file"
    echo ""
    print_info "Or restart your terminal"
    echo ""
    print_info "If still not working, re-run installer:"
    echo "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/taigroddy/ai-code-review/main/install.sh)\""
fi

echo ""
print_info "For more help, visit: https://github.com/taigroddy/ai-code-review"
