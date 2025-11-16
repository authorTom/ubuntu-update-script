# Ubuntu System Update Script

A comprehensive bash script for checking and applying Ubuntu system updates with interactive prompts, email notifications, and automatic cleanup.

## Features

- **Interactive Mode**: Prompts for user confirmation before applying updates
- **Comprehensive Updates**: Applies all available system updates using `apt upgrade`
- **Package Cleanup**: Automatically removes unused packages and cleans apt cache
- **Email Notifications**: Sends detailed update reports via email
- **Detailed Logging**: Creates timestamped logs in `/var/log/` for audit trails
- **Color-Coded Output**: Easy-to-read terminal output with status indicators
- **Error Handling**: Robust error checking with appropriate exit codes
- **Safety Checks**: Validates privileges, OS type, and required commands

## Requirements

- **Operating System**: Ubuntu (any supported version)
- **Privileges**: Must be run with sudo or as root
- **Required Packages**: `apt`, `apt-get` (pre-installed on Ubuntu)
- **Optional for Email**: `mailutils` or `sendmail`

### Installing Email Support (Optional)

To enable email notifications, install mailutils:

```bash
sudo apt update
sudo apt install mailutils
```

During installation, you may be prompted to configure the mail system. For most use cases, select "Internet Site" and use your system's hostname.

## Installation

1. **Download or create the script:**

```bash
cd /usr/local/bin
sudo nano update-system.sh
# Paste the script content and save
```

2. **Make the script executable:**

```bash
sudo chmod +x update-system.sh
```

3. **Verify installation:**

```bash
sudo ./update-system.sh --help
```

## Usage

### Basic Usage (Interactive Mode)

Run the script with sudo. It will prompt you before each major operation:

```bash
sudo ./update-system.sh
```

The script will:
1. Check prerequisites (permissions, OS, commands)
2. Update package lists
3. Display available updates
4. Prompt to install updates
5. Prompt to clean up unused packages

### With Email Notifications

Receive a summary report via email:

```bash
sudo ./update-system.sh --email admin@example.com
```

### Automatic Mode (No Prompts)

Run without interactive prompts (useful for cron jobs):

```bash
sudo ./update-system.sh --yes --email admin@example.com
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Display help message and exit |
| `-e`, `--email EMAIL` | Send notification to specified email address |
| `-y`, `--yes` | Skip confirmation prompts (automatic mode) |

## Examples

### Example 1: Manual Update with Prompts

```bash
sudo ./update-system.sh
```

Output:
```
================================
Running Prerequisite Checks
================================
[INFO] Checking privileges...
[SUCCESS] Running with appropriate privileges
[INFO] Checking operating system...
[SUCCESS] Ubuntu system detected: Ubuntu 22.04.3 LTS

================================
Updating Package Lists
================================
[INFO] Running apt update...
[SUCCESS] Package lists updated successfully

================================
Checking for Available Updates
================================
[INFO] Found 15 packages with available updates
[INFO] Upgradable packages:
...

Do you want to proceed with installing updates? [y/N]: y
```

### Example 2: Automated Updates with Email

```bash
sudo ./update-system.sh --yes --email sysadmin@company.com
```

This will run unattended and send a report like:

```
Ubuntu System Update Report
===========================

Server: web-server-01
Date: Wed Nov 11 14:30:22 UTC 2025
User: root

Update Summary:
--------------
Updates Available: 15
Packages Upgraded: 15
Packages Removed: 3
Errors Encountered: 0

Status: SUCCESS

Full log file: /var/log/system-update-20251111-143022.log
```

### Example 3: Scheduled Updates with Cron

Add to root's crontab to run weekly updates on Sunday at 2 AM:

```bash
sudo crontab -e
```

Add this line:

```cron
0 2 * * 0 /usr/local/bin/update-system.sh --yes --email admin@example.com
```

## Log Files

Each run creates a timestamped log file:

```
/var/log/system-update-YYYYMMDD-HHMMSS.log
```

Example: `/var/log/system-update-20251111-143022.log`

To view recent logs:

```bash
ls -lth /var/log/system-update-*.log | head -5
```

To view a specific log:

```bash
sudo less /var/log/system-update-20251111-143022.log
```

## Exit Codes

The script uses the following exit codes:

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | Prerequisite check failed (permissions, OS, commands) |
| 2 | Failed to update package lists |
| 3 | Failed to apply updates |
| 4 | Failed to clean up packages |
| 5 | Completed with errors |

## Troubleshooting

### Permission Denied

**Problem**: `[ERROR] This script must be run with sudo or as root`

**Solution**: Always run with sudo:
```bash
sudo ./update-system.sh
```

### Email Not Sending

**Problem**: Email notification fails or is not sent

**Solution**: Install mailutils and configure:
```bash
sudo apt install mailutils
echo "Test email" | mail -s "Test" your@email.com
```

### Package Lock Error

**Problem**: `Could not get lock /var/lib/dpkg/lock-frontend`

**Solution**: Another process is using apt. Wait for it to complete or check:
```bash
ps aux | grep -i apt
sudo lsof /var/lib/dpkg/lock-frontend
```

### Script Not Found

**Problem**: `command not found` when running the script

**Solution**: Use the full path or ensure the script is executable:
```bash
sudo /usr/local/bin/update-system.sh
# or
sudo chmod +x /path/to/update-system.sh
```

## Security Considerations

- **Run as Root**: The script requires root privileges to update system packages
- **Review Updates**: In interactive mode, review the list of updates before confirming
- **Log Access**: Log files contain system information; ensure proper file permissions
- **Email Security**: Email notifications may contain sensitive system information
- **Cron Jobs**: When scheduling, ensure the email system is properly configured

## Customization

### Change Log Directory

Edit the `LOG_FILE` variable in the script:

```bash
LOG_FILE="/custom/path/system-update-$(date +%Y%m%d-%H%M%S).log"
```

### Modify Email Format

Edit the `send_email_notification()` function to customize the email body and subject.

### Adjust Color Scheme

Modify the color variables at the top of the script:

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# ... etc
```

## Best Practices

1. **Test First**: Run in interactive mode first to review changes
2. **Check Logs**: Review log files after automated runs
3. **Email Notifications**: Set up email for scheduled/automated updates
4. **Regular Schedule**: Schedule updates during low-traffic periods
5. **Backup First**: Consider backing up critical data before major updates
6. **Monitor Disk Space**: Ensure adequate space for updates (check with `df -h`)

## Advanced Usage

### Pre-Update System Backup

Create a wrapper script to backup before updating:

```bash
#!/bin/bash
# backup-and-update.sh

echo "Creating system backup..."
# Your backup commands here
rsync -av /important/data /backup/location

echo "Running system updates..."
sudo /usr/local/bin/update-system.sh --yes --email admin@example.com
```

### Notification to Multiple Recipients

Use comma-separated addresses (depends on your mail configuration):

```bash
sudo ./update-system.sh --email "admin1@example.com,admin2@example.com"
```

## Contributing

This script can be customized and extended. Some ideas for enhancements:

- Add support for `dist-upgrade` option
- Implement Slack/Discord webhook notifications
- Add automatic reboot handling for kernel updates
- Create update reports in HTML format
- Add dry-run mode to preview changes without applying

## License

This script is provided for system administration purposes.

## Support

For issues, questions, or contributions, please refer to the script documentation or contact your system administrator.

---

**Last Updated**: 2025-11-11
**Version**: 1.0

