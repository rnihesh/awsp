#!/usr/bin/env bash
#
# awsp Installer
# AWS Profile Switcher - Quick Installation Script
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
REPO_URL="https://github.com/rnihesh/awsp"
INSTALL_DIR="$HOME/.awsp"
awsp_FILE="awsp.sh"

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║                                           ║"
    echo "  ║      awsp - AWS Profile Switcher          ║"
    echo "  ║                                           ║"
    echo "  ╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print step
print_step() {
    echo -e "${BLUE}==>${NC} ${BOLD}$1${NC}"
}

# Print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect shell
detect_shell() {
    # First check SHELL environment variable (most reliable for user's default shell)
    local shell_path="${SHELL:-$(basename "$0")}"
    local shell_name=$(basename "$shell_path")
    
    case "$shell_name" in
        zsh)
            echo "zsh"
            ;;
        bash)
            echo "bash"
            ;;
        *)
            # Fallback to version variables if SHELL is not set or unknown
            if [ -n "$ZSH_VERSION" ]; then
                echo "zsh"
            elif [ -n "$BASH_VERSION" ]; then
                echo "bash"
            else
                echo "$shell_name"
            fi
            ;;
    esac
}

# Get shell config file
get_shell_config() {
    local shell_name="$1"
    case "$shell_name" in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            if [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check for AWS CLI
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
        print_success "AWS CLI found (v$aws_version)"
    else
        print_error "AWS CLI not found!"
        echo "    Please install AWS CLI first:"
        echo "    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    # Check for fzf (optional)
    if command -v fzf &> /dev/null; then
        print_success "fzf found (fuzzy search enabled)"
    else
        print_warning "fzf not found (will use basic selection menu)"
        echo "    For better experience, install fzf:"
        echo "    https://github.com/junegunn/fzf#installation"
    fi
    
    # Check for git (for clone method)
    if command -v git &> /dev/null; then
        print_success "git found"
    else
        print_warning "git not found (will use curl/wget instead)"
    fi
}

# Download awsp
download_awsp() {
    print_step "Installing awsp..."
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Clean up any extra files from previous full repo installation
    if [ -d "$INSTALL_DIR/.git" ] || [ -f "$INSTALL_DIR/README.md" ]; then
        print_step "Cleaning up old installation files..."
        # Keep only awsp.sh, remove everything else
        find "$INSTALL_DIR" -mindepth 1 -not -name "awsp.sh" -exec rm -rf {} +
    fi
    
    # Download only the awsp.sh script file
    download_file
    
    print_success "awsp installed to $INSTALL_DIR"
}

# Download file using curl or wget
download_file() {
    local url="$REPO_URL/raw/main/$awsp_FILE"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$INSTALL_DIR/$awsp_FILE"
    elif command -v wget &> /dev/null; then
        wget -qO "$INSTALL_DIR/$awsp_FILE" "$url"
    else
        print_error "Neither curl nor wget found. Cannot download."
        exit 1
    fi
}

# Configure shell
configure_shell() {
    print_step "Configuring shell..."
    
    local current_shell=$(detect_shell)
    local config_file=$(get_shell_config "$current_shell")
    local source_line="[ -f ~/.awsp/awsp.sh ] && . ~/.awsp/awsp.sh"
    
    echo "    Detected shell: $current_shell"
    echo "    Config file: $config_file"
    
    # Check if already configured
    if grep -q "awsp.sh" "$config_file" 2>/dev/null; then
        print_warning "awsp already configured in $config_file"
        
        # Update old path if needed
        if grep -q ".awsp.sh" "$config_file"; then
            print_step "Updating configuration path..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' 's|~/.awsp.sh|~/.awsp/awsp.sh|g' "$config_file"
            else
                sed -i 's|~/.awsp.sh|~/.awsp/awsp.sh|g' "$config_file"
            fi
            print_success "Configuration updated"
        fi
    else
        # Add source line to config
        echo "" >> "$config_file"
        echo "# awsp - AWS Profile Switcher" >> "$config_file"
        echo "$source_line" >> "$config_file"
        print_success "Added awsp to $config_file"
    fi
    
    # Export the config file path for use in completion message
    CONFIGURED_SHELL_RC="$config_file"
}

# Print completion message
print_completion() {
    local config_file="${CONFIGURED_SHELL_RC:-$HOME/.$(detect_shell)rc}"
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✓ awsp installed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}To activate awsp in your current terminal, run:${NC}"
    echo ""
    echo -e "  ${CYAN}source $config_file${NC}"
    echo ""
    echo -e "  (New terminal windows will have awsp ready to use)"
    echo ""
    echo -e "${BOLD}Quick Start:${NC}"
    echo ""
    echo -e "  ${CYAN}awsp${NC}              # Interactive profile selector"
    echo -e "  ${CYAN}awsp <profile>${NC}    # Switch to specific profile"
    echo -e "  ${CYAN}awsp status${NC}      # Show profile and SSO status"
    echo -e "  ${CYAN}awsp clear${NC}        # Clear current profile"
    echo -e "  ${CYAN}awsp-current${NC}      # Show current profile"
    echo ""
    echo -e "${BOLD}Documentation:${NC} $REPO_URL"
    echo ""
}

# Uninstall function
uninstall() {
    print_banner
    print_step "Uninstalling awsp..."
    
    # Remove install directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_success "Removed $INSTALL_DIR"
    fi
    
    # Remove from shell configs
    for config_file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [ -f "$config_file" ] && grep -q "awsp" "$config_file"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/# awsp/d' "$config_file"
                sed -i '' '/awsp.sh/d' "$config_file"
            else
                sed -i '/# awsp/d' "$config_file"
                sed -i '/awsp.sh/d' "$config_file"
            fi
            print_success "Cleaned $config_file"
        fi
    done
    
    echo ""
    print_success "awsp has been uninstalled"
    echo "    Please restart your terminal or run: exec \$SHELL"
}

# Main installation
main() {
    print_banner
    
    # Handle uninstall flag
    if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
        uninstall
        exit 0
    fi
    
    check_prerequisites
    echo ""
    download_awsp
    echo ""
    configure_shell
    print_completion
}

# Run main
main "$@"
