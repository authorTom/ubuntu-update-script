#!/bin/bash

################################################################################
# Ubuntu System Update Script
#
# Description: Interactive script to check for and apply Ubuntu system updates
#              with email notifications and package cleanup
#
# Author: Generated with Claude Code
# Version: 1.0
# Date: 2025-11-11
#
# Usage: sudo ./update-system.sh [OPTIONS]
# Options:
#   -h, --help     Display this help message
#   -e, --email    Email address for notifications (optional)
#   -y, --yes      Skip confirmation prompts (non-interactive mode)
################################################################################

set -o errexit   # Exit on error
set -o pipefail  # Exit on pipe failure
set -o nounset   # Exit on undefined variable

# Script variables
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/system-update-$(date +%Y%m%d-%H%M%S).log"
EMAIL_RECIPIENT=""
AUTO_YES=false
EXIT_CODE=0

# Update tracking variables
UPDATES_AVAILABLE=0
PACKAGES_UPGRADED=0
PACKAGES_REMOVED=0
PACKAGES_INSTALLED=0
ERRORS_OCCURRED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

# Print colored output
print_info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    ERRORS_OCCURRED=$((ERRORS_OCCURRED + 1))
}

print_header() {
    echo -e "${BLUE}================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}================================${NC}" | tee -a "$LOG_FILE"
}

# Display usage information
show_help() {
    cat << EOF
${SCRIPT_NAME} - Ubuntu System Update Script

USAGE:
    sudo ${SCRIPT_NAME} [OPTIONS]

DESCRIPTION:
    Interactive script to check for and apply Ubuntu system updates,
    with optional email notifications and automatic package cleanup.

OPTIONS:
    -h, --help              Display this help message and exit
    -e, --email EMAIL       Send notification email to specified address
    -y, --yes               Skip confirmation prompts (automatic mode)

EXAMPLES:
    # Run interactively with prompts
    sudo ${SCRIPT_NAME}

    # Run with email notification
    sudo ${SCRIPT_NAME} --email admin@example.com

    # Run automatically without prompts
    sudo ${SCRIPT_NAME} --yes --email admin@example.com

REQUIREMENTS:
    - Must be run with sudo/root privileges
    - Ubuntu operating system
    - For email: mailutils or sendmail package installed

LOG FILES:
    Logs are saved to: /var/log/system-update-YYYYMMDD-HHMMSS.log

EOF
}

# Prompt user for yes/no confirmation
prompt_confirmation() {
    local prompt_message="$1"

    if [[ "$AUTO_YES" == true ]]; then
        print_info "Auto-confirm enabled: proceeding with $prompt_message"
        return 0
    fi

    while true; do
        read -p "$(echo -e ${CYAN}${prompt_message}${NC} [y/N]: )" response
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* | "" ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Log script start
log_start() {
    print_header "Ubuntu System Update Script Started"
    print_info "Date: $(date)"
    print_info "User: $(whoami)"
    print_info "Log file: $LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Log script end
log_end() {
    echo "" | tee -a "$LOG_FILE"
    print_header "Update Script Completed"
    print_info "Total errors encountered: $ERRORS_OCCURRED"
    print_info "Exit code: $EXIT_CODE"
    print_info "Log saved to: $LOG_FILE"
}

# Cleanup function for script exit
cleanup() {
    log_end
    exit "$EXIT_CODE"
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

################################################################################
# Prerequisite Check Functions
################################################################################

# Check if running with root/sudo privileges
check_root_privileges() {
    print_info "Checking privileges..."
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run with sudo or as root"
        print_info "Usage: sudo ${SCRIPT_NAME}"
        EXIT_CODE=1
        exit 1
    fi
    print_success "Running with appropriate privileges"
}

# Check if running on Ubuntu
check_ubuntu_system() {
    print_info "Checking operating system..."
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect operating system"
        EXIT_CODE=1
        exit 1
    fi

    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_error "This script is designed for Ubuntu systems only"
        print_error "Detected OS: $NAME"
        EXIT_CODE=1
        exit 1
    fi
    print_success "Ubuntu system detected: $VERSION"
}

# Check for required commands
check_required_commands() {
    print_info "Checking required commands..."
    local required_commands=("apt" "apt-get")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        EXIT_CODE=1
        exit 1
    fi
    print_success "All required commands available"
}

# Check if email command is available
check_email_capability() {
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        print_info "Checking email capability..."
        if command -v mail &> /dev/null || command -v sendmail &> /dev/null; then
            print_success "Email capability available"
            return 0
        else
            print_warning "Email requested but 'mail' or 'sendmail' not found"
            print_warning "Install mailutils: sudo apt install mailutils"
            print_warning "Continuing without email notifications..."
            EMAIL_RECIPIENT=""
        fi
    fi
}

# Run all prerequisite checks
run_prerequisite_checks() {
    print_header "Running Prerequisite Checks"
    check_root_privileges
    check_ubuntu_system
    check_required_commands
    check_email_capability
    print_success "All prerequisite checks passed"
    echo "" | tee -a "$LOG_FILE"
}

################################################################################
# Update Functions
################################################################################

# Update package lists
update_package_lists() {
    print_header "Updating Package Lists"
    print_info "Running apt update..."

    if apt update 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Package lists updated successfully"
        return 0
    else
        print_error "Failed to update package lists"
        EXIT_CODE=2
        return 1
    fi
}

# Check for available updates
check_available_updates() {
    print_header "Checking for Available Updates"

    # Get number of upgradable packages
    UPDATES_AVAILABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)

    if [[ $UPDATES_AVAILABLE -eq 0 ]]; then
        print_success "System is up to date! No updates available."
        return 1
    else
        print_info "Found $UPDATES_AVAILABLE packages with available updates"
        echo "" | tee -a "$LOG_FILE"
        print_info "Upgradable packages:" | tee -a "$LOG_FILE"
        apt list --upgradable 2>/dev/null | grep upgradable | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        return 0
    fi
}

# Apply system updates
apply_updates() {
    print_header "Applying System Updates"

    if ! prompt_confirmation "Do you want to proceed with installing updates?"; then
        print_warning "Update installation cancelled by user"
        return 1
    fi

    print_info "Installing updates... This may take a while."
    print_info "You can monitor progress in the output below:"
    echo "" | tee -a "$LOG_FILE"

    # Use apt upgrade with non-interactive frontend
    DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
    local apt_exit_code=${PIPESTATUS[0]}

    if [[ $apt_exit_code -eq 0 ]]; then
        print_success "Updates applied successfully"

        # Get statistics
        PACKAGES_UPGRADED=$(grep -c "^Unpacking" "$LOG_FILE" || echo "0")
        print_info "Packages upgraded: $PACKAGES_UPGRADED"
        return 0
    else
        print_error "Failed to apply updates (exit code: $apt_exit_code)"
        EXIT_CODE=3
        return 1
    fi
}

################################################################################
# Cleanup Functions
################################################################################

# Remove unused packages
cleanup_packages() {
    print_header "Cleaning Up Unused Packages"

    if ! prompt_confirmation "Do you want to remove unused packages?"; then
        print_warning "Package cleanup cancelled by user"
        return 0
    fi

    print_info "Removing unused packages..."

    # Run autoremove
    if apt autoremove -y 2>&1 | tee -a "$LOG_FILE"; then
        PACKAGES_REMOVED=$(grep -oP '\d+(?= to remove)' "$LOG_FILE" | tail -1 || echo "0")
        print_success "Removed $PACKAGES_REMOVED unused packages"
    else
        print_error "Failed to remove unused packages"
        EXIT_CODE=4
    fi

    print_info "Cleaning package cache..."

    # Run autoclean
    if apt autoclean -y 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Package cache cleaned"
    else
        print_error "Failed to clean package cache"
        EXIT_CODE=4
    fi
}

################################################################################
# Email Notification Functions
################################################################################

# Send email notification
send_email_notification() {
    if [[ -z "$EMAIL_RECIPIENT" ]]; then
        return 0
    fi

    print_header "Sending Email Notification"

    local email_subject="Ubuntu System Update Report - $(hostname) - $(date +%Y-%m-%d)"
    local email_body

    # Generate email body
    email_body=$(cat <<EOF
Ubuntu System Update Report
===========================

Server: $(hostname)
Date: $(date)
User: $(whoami)

Update Summary:
--------------
Updates Available: $UPDATES_AVAILABLE
Packages Upgraded: $PACKAGES_UPGRADED
Packages Removed: $PACKAGES_REMOVED
Errors Encountered: $ERRORS_OCCURRED

Status: $(if [[ $ERRORS_OCCURRED -eq 0 && $UPDATES_AVAILABLE -gt 0 ]]; then echo "SUCCESS"; elif [[ $ERRORS_OCCURRED -gt 0 ]]; then echo "COMPLETED WITH ERRORS"; else echo "NO UPDATES NEEDED"; fi)

Full log file: $LOG_FILE

---
This is an automated message from the Ubuntu System Update Script.
EOF
)

    # Send email
    if command -v mail &> /dev/null; then
        echo "$email_body" | mail -s "$email_subject" "$EMAIL_RECIPIENT" 2>&1 | tee -a "$LOG_FILE"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            print_success "Email notification sent to $EMAIL_RECIPIENT"
        else
            print_error "Failed to send email notification"
        fi
    elif command -v sendmail &> /dev/null; then
        {
            echo "To: $EMAIL_RECIPIENT"
            echo "Subject: $email_subject"
            echo ""
            echo "$email_body"
        } | sendmail -t 2>&1 | tee -a "$LOG_FILE"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            print_success "Email notification sent to $EMAIL_RECIPIENT"
        else
            print_error "Failed to send email notification"
        fi
    else
        print_warning "No email command available, skipping notification"
    fi
}

################################################################################
# Main Execution
################################################################################

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--email)
                if [[ -n "${2:-}" ]]; then
                    EMAIL_RECIPIENT="$2"
                    shift 2
                else
                    print_error "Email address not provided"
                    exit 1
                fi
                ;;
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_arguments "$@"
    log_start

    # Run prerequisite checks
    run_prerequisite_checks

    # Update package lists
    if ! update_package_lists; then
        EXIT_CODE=2
        send_email_notification
        return
    fi

    # Check for available updates
    if ! check_available_updates; then
        # No updates available
        send_email_notification
        return
    fi

    # Apply updates
    if apply_updates; then
        # Cleanup packages
        cleanup_packages
    fi

    # Send email notification
    send_email_notification

    # Final summary
    echo "" | tee -a "$LOG_FILE"
    print_header "Summary"
    print_info "Updates available: $UPDATES_AVAILABLE"
    print_info "Packages upgraded: $PACKAGES_UPGRADED"
    print_info "Packages removed: $PACKAGES_REMOVED"
    print_info "Errors encountered: $ERRORS_OCCURRED"

    if [[ $ERRORS_OCCURRED -eq 0 ]]; then
        print_success "Update process completed successfully!"
    else
        print_warning "Update process completed with $ERRORS_OCCURRED error(s)"
        print_warning "Check the log file for details: $LOG_FILE"
        EXIT_CODE=5
    fi
}

# Run main function with all arguments
main "$@"
