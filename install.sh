#!/bin/bash
# ============================================
# TeleClaude - One-liner Install Script
# Control Claude Code from Telegram or Terminal
#
# Usage: curl -sSL https://raw.githubusercontent.com/gatordevin/teleclaude/main/install.sh | bash
# ============================================

set -e

# ============================================
# Color Codes for Pretty Output
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ============================================
# Helper Functions
# ============================================

print_header() {
    echo ""
    echo -e "${CYAN}  ============================================${NC}"
    echo -e "${CYAN}  ${BOLD}TeleClaude Installer${NC}"
    echo -e "${CYAN}  Control Claude Code from Telegram${NC}"
    echo -e "${CYAN}  ============================================${NC}"
    echo ""
}

success() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

error() {
    echo -e "  ${RED}[X]${NC} $1"
}

warning() {
    echo -e "  ${YELLOW}[!]${NC} $1"
}

info() {
    echo -e "  ${BLUE}[i]${NC} $1"
}

step() {
    echo ""
    echo -e "  ${CYAN}--- $1 ---${NC}"
    echo ""
}

# ============================================
# Detect Operating System
# ============================================

detect_os() {
    OS="unknown"
    ARCH="$(uname -m)"

    case "$(uname -s)" in
        Linux*)
            OS="linux"
            # Check for WSL
            if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
                OS="wsl"
            fi
            ;;
        Darwin*)
            OS="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS="windows"
            ;;
        *)
            OS="unknown"
            ;;
    esac

    echo "$OS"
}

# ============================================
# Check and Install Node.js
# ============================================

check_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//')
        MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)

        if [ "$MAJOR_VERSION" -ge 18 ]; then
            success "Node.js v$NODE_VERSION detected (v18+ required)"
            return 0
        else
            warning "Node.js v$NODE_VERSION detected, but v18+ is required"
            return 1
        fi
    else
        warning "Node.js not found"
        return 1
    fi
}

install_nodejs() {
    local os=$1

    info "Installing Node.js LTS..."

    case "$os" in
        macos)
            if command -v brew &> /dev/null; then
                info "Using Homebrew to install Node.js..."
                brew install node@20
                brew link node@20 --force --overwrite
            else
                warning "Homebrew not found. Installing via official installer..."
                curl -fsSL https://nodejs.org/dist/v20.11.0/node-v20.11.0.pkg -o /tmp/node.pkg
                sudo installer -pkg /tmp/node.pkg -target /
                rm /tmp/node.pkg
            fi
            ;;
        linux|wsl)
            # Try nvm first, then package managers
            if command -v nvm &> /dev/null; then
                info "Using nvm to install Node.js..."
                nvm install 20
                nvm use 20
            elif command -v apt-get &> /dev/null; then
                info "Using apt to install Node.js..."
                curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                sudo apt-get install -y nodejs
            elif command -v dnf &> /dev/null; then
                info "Using dnf to install Node.js..."
                sudo dnf install -y nodejs
            elif command -v yum &> /dev/null; then
                info "Using yum to install Node.js..."
                curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
                sudo yum install -y nodejs
            elif command -v pacman &> /dev/null; then
                info "Using pacman to install Node.js..."
                sudo pacman -S --noconfirm nodejs npm
            else
                error "Could not detect package manager."
                info "Please install Node.js manually: https://nodejs.org/"
                exit 1
            fi
            ;;
        windows)
            warning "On Windows, please install Node.js from https://nodejs.org/"
            warning "Or use: winget install OpenJS.NodeJS.LTS"
            exit 1
            ;;
        *)
            error "Unsupported operating system"
            exit 1
            ;;
    esac
}

# ============================================
# Check and Install Git
# ============================================

check_git() {
    if command -v git &> /dev/null; then
        success "Git $(git --version | awk '{print $3}') detected"
        return 0
    else
        warning "Git not found"
        return 1
    fi
}

install_git() {
    local os=$1

    info "Installing Git..."

    case "$os" in
        macos)
            if command -v brew &> /dev/null; then
                brew install git
            else
                xcode-select --install
            fi
            ;;
        linux|wsl)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y git
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y git
            elif command -v yum &> /dev/null; then
                sudo yum install -y git
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm git
            fi
            ;;
    esac
}

# ============================================
# Install TeleClaude
# ============================================

install_teleclaude() {
    local install_dir="$HOME/teleclaude"

    step "Installing TeleClaude"

    # Check if directory exists
    if [ -d "$install_dir" ]; then
        warning "Directory $install_dir already exists"
        info "Pulling latest changes..."
        cd "$install_dir"
        git pull origin main 2>/dev/null || true
    else
        info "Cloning TeleClaude repository..."
        git clone https://github.com/gatordevin/teleclaude.git "$install_dir"
        cd "$install_dir"
    fi

    success "Repository ready at $install_dir"

    # Install npm dependencies
    step "Installing Dependencies"

    info "Running npm install..."
    npm install

    success "Dependencies installed"
}

# ============================================
# Check/Install Claude Code CLI
# ============================================

check_claude_cli() {
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1)
        success "Claude Code CLI detected: $CLAUDE_VERSION"
        return 0
    else
        return 1
    fi
}

install_claude_cli() {
    step "Installing Claude Code CLI"

    info "Installing via npm..."
    npm install -g @anthropic-ai/claude-code

    if command -v claude &> /dev/null; then
        success "Claude Code CLI installed successfully"
    else
        warning "Claude CLI installed but may not be in PATH"
        info "Try reopening your terminal or adding npm global bin to PATH"
    fi
}

# ============================================
# Post-Install Setup Guide
# ============================================

show_next_steps() {
    local install_dir="$HOME/teleclaude"

    echo ""
    echo -e "${GREEN}  ============================================${NC}"
    echo -e "${GREEN}  ${BOLD}Installation Complete!${NC}"
    echo -e "${GREEN}  ============================================${NC}"
    echo ""
    echo -e "  ${CYAN}Next Steps:${NC}"
    echo ""
    echo -e "  ${BOLD}1.${NC} Navigate to the install directory:"
    echo -e "     ${DIM}cd $install_dir${NC}"
    echo ""
    echo -e "  ${BOLD}2.${NC} Run the setup wizard:"
    echo -e "     ${DIM}npm run setup${NC}"
    echo ""
    echo -e "  ${CYAN}The setup wizard will guide you through:${NC}"
    echo -e "     - Choosing CLI mode (local terminal chat) or Telegram mode"
    echo -e "     - Authenticating with Claude Code"
    echo -e "     - Creating a Telegram bot (if using Telegram mode)"
    echo -e "     - Configuring allowed users and working directory"
    echo ""
    echo -e "  ${CYAN}Quick Commands:${NC}"
    echo -e "     ${DIM}npm run chat${NC}      - Start local CLI chat"
    echo -e "     ${DIM}npm start${NC}         - Start Telegram bridge"
    echo -e "     ${DIM}npm run setup${NC}     - Re-run setup wizard"
    echo ""
    echo -e "  ${BLUE}Documentation:${NC} https://github.com/gatordevin/teleclaude"
    echo ""
}

# ============================================
# Main Installation Flow
# ============================================

main() {
    print_header

    # Detect OS
    step "Detecting System"
    OS=$(detect_os)
    ARCH=$(uname -m)

    case "$OS" in
        macos)
            success "Detected: macOS ($ARCH)"
            ;;
        linux)
            success "Detected: Linux ($ARCH)"
            ;;
        wsl)
            success "Detected: Windows Subsystem for Linux ($ARCH)"
            ;;
        windows)
            warning "Detected: Windows (native)"
            info "For Windows, consider using WSL or the install.bat script"
            info "Download: https://github.com/gatordevin/teleclaude"
            exit 1
            ;;
        *)
            error "Unknown operating system"
            exit 1
            ;;
    esac

    # Check/Install Git
    step "Checking Git"
    if ! check_git; then
        install_git "$OS"
        check_git || { error "Failed to install Git"; exit 1; }
    fi

    # Check/Install Node.js
    step "Checking Node.js"
    if ! check_nodejs; then
        install_nodejs "$OS"
        # Re-source shell profile to get new PATH
        if [ -f "$HOME/.bashrc" ]; then
            source "$HOME/.bashrc" 2>/dev/null || true
        fi
        if [ -f "$HOME/.zshrc" ]; then
            source "$HOME/.zshrc" 2>/dev/null || true
        fi
        check_nodejs || { error "Failed to install Node.js"; exit 1; }
    fi

    # Install TeleClaude
    install_teleclaude

    # Check/Install Claude Code CLI
    step "Checking Claude Code CLI"
    if ! check_claude_cli; then
        install_claude_cli
    fi

    # Show next steps
    show_next_steps

    # Offer to run setup
    echo -e "  ${YELLOW}Would you like to run the setup wizard now? (Y/n)${NC} "
    read -r response

    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo ""
        info "Setup skipped. Run 'npm run setup' when ready."
        echo ""
    else
        cd "$HOME/teleclaude"
        npm run setup
    fi
}

# Run main function
main "$@"
