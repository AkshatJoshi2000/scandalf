#!/bin/bash

# Function to set text color to red
red() {
    tput setaf 1
}

# Function to set text color to green
green() {
    tput setaf 2
}

# Function to set text color to yellow
yellow() {
    tput setaf 3
}

# Function to set text color to cyan
cyan() {
    tput setaf 6
}

# Function to reset text color to default
reset() {
    tput sgr0
}

# Function to print "ScanDalf" in ASCII art with cyan color
print_scandalf() {
    cyan
    echo '
  _________                    ________         .__   _____ 
 /   _____/ ____ _____    ____ \______ \ _____  |  |_/ ____\
 \_____  \_/ ___\\__  \  /    \ |    |  \\__  \ |  |\   __\ 
 /        \  \___ / __ \|   |  \|    `   \/ __ \|  |_|  |   
/_______  /\___  >____  /___|  /_______  (____  /____/__|   
        \/     \/     \/     \/        \/     \/            

    '
    reset
}

# Initialize variables
url=""
wordlist="$HOME/Desktop/recon/SecLists/Discovery/Web-Content/raft-medium-directories.txt"
result_dir="$HOME/Desktop/scandalf/result"

# Check for necessary tools
for tool in feroxbuster subfinder amass httpx; do
    if ! command -v $tool &> /dev/null; then
        red
        echo "Error: $tool is not installed. Exiting."
        reset
        exit 1
    fi
done

# Parse command line arguments
while getopts ":u:w:" opt; do
    case $opt in
        u) url="$OPTARG";;
        w) wordlist="$OPTARG";;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    esac
done

# Check if the URL is provided
if [ -z "$url" ]; then
    red
    echo "No URL provided. Exiting."
    reset
    exit 1
fi

# Create result directory
dir="$result_dir/$url"
mkdir -p "$dir" || { red; echo "Failed to create directory $dir. Exiting."; reset; exit 1; }

# Function for forced browsing
forced_browsing() {
    local resolved_file="$dir/${url}_resolved"
    if [ -f "$resolved_file" ]; then
        while IFS= read -r line; do
            local target_url=$line
            yellow
            echo "  ==> Running feroxbuster on $target_url"
            reset
            feroxbuster -u "$target_url" -s 200 -w $wordlist > "$dir/target_forced_browsing" 2>&1
            cat "$dir/target_forced_browsing" | sort -u | uniq >> "$dir/${url}_stat_200_forced_browsing"
            rm $dir/target_forced_browsing
        done < "$resolved_file"
    else
        red
        echo "Resolved file not found: $resolved_file"
        reset
    fi
}


# Subdomain Enumeration
sub_domain_enumeration() {
    yellow
    echo "  ==> Running subfinder on $url"
    subfinder -d $url > "$dir/${url}_subdomains" 2>&1

    echo "  ==> Running amass enum on $url"
    amass enum -timeout 1 -d $url >> "$dir/${url}_subdomains" 2>&1

    echo " ==> Running amass active on $url"
    amass -active -brute -d $url >> "$dir/${url}_subdomains" 2>&1 
    reset

    sort -u "$dir/${url}_subdomains" > "$dir/${url}_sorted_sub_domain" 
    httpx -follow-redirects -status-code -vhost -threads 300 -silent -l "$dir/${url}_sorted_sub_domain" | sort -u | grep "[200]" | cut -d [ -f1 | uniq > "$dir/${url}_resolved"
}

main() {
    print_scandalf
    green
    echo "Performing Subdomain Enumeration..."
    reset
    sub_domain_enumeration
    green
    echo "Performing Forced Browsing..."
    reset
    forced_browsing
    green
    echo "Scan completed successfully."
    reset
}

main