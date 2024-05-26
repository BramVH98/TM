#!/bin/bash

# To use this script properly, add it as a cron job (every 5 minutes)

# Set the variables (these should be set appropriately)
current_ip=""        # The current IP that should be replaced
check_ip_addr=""     # The IP to check and possibly take over
default_gw=""        # The default gateway for this IP
interface=""         # The network interface to use
log_file="/var/log/ip_takeover.log"  # Log file for script output

# Function to log messages
log_message() {
    echo "$(date): $1" | tee -a "$log_file"
}

# Ensure all required variables are set
if [[ -z "$current_ip" || -z "$check_ip_addr" || -z "$default_gw" || -z "$interface" ]]; then
    log_message "One or more required variables are not set. Exiting."
    exit 1
fi

# Validate IP address format
validate_ip() {
    local ip=$1
    local valid_ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    if [[ ! $ip =~ $valid_ip_regex ]]; then
        log_message "Invalid IP address format: $ip. Exiting."
        exit 1
    fi
}

validate_ip "$current_ip"
validate_ip "$check_ip_addr"
validate_ip "$default_gw"

# Ping the check_ip_addr to see if it is available
if ping -c 5 "$check_ip_addr" > /dev/null; then
    log_message "IP $check_ip_addr is responding. No action needed."
    exit 0
else
    log_message "IP $check_ip_addr is not responding. Attempting to take over the IP."

    # Add the new IP address to the interface
    if ip addr add "$check_ip_addr" dev "$interface"; then
        log_message "Added IP $check_ip_addr to $interface."

        # Remove the current IP address from the interface
        if ip addr del "$current_ip" dev "$interface"; then
            log_message "Removed IP $current_ip from $interface."

            # Test connectivity to the default gateway
            if ping -c 8 "$default_gw" > /dev/null; then
                log_message "Successfully pinged the default gateway $default_gw."
                exit 0
            else
                log_message "Failed to ping the default gateway $default_gw."
                # Revert changes
                ip addr del "$check_ip_addr" dev "$interface"
                ip addr add "$current_ip" dev "$interface"
                log_message "Reverted changes: Restored $current_ip and removed $check_ip_addr from $interface."
                exit 1
            fi
        else
            log_message "Failed to remove IP $current_ip from $interface."
            # Revert changes
            ip addr del "$check_ip_addr" dev "$interface"
            log_message "Reverted changes: Removed $check_ip_addr from $interface."
            exit 1
        fi
    else
        log_message "Failed to add IP $check_ip_addr to $interface."
        exit 1
    fi
fi
