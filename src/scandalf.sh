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
    red
    echo '
  _________                    ________         .__   _____ 
 /   _____/ ____ _____    ____ \______ \ _____  |  |_/ ____\
 \_____  \_/ ___\\__  \  /    \ |    |  \\__  \ |  |\   __\ 
 /        \  \___ / __ \|   |  \|    `   \/ __ \|  |_|  |   
/_______  /\___  >____  /___|  /_______  (____  /____/__|   
        \/     \/     \/     \/        \/     \/            

    '
    echo 'Your personal recon Wizard!'
    echo ' '
    reset
}

# Initialize variables
url=""
wordlist="$HOME/Desktop/recon/SecLists/Discovery/Web-Content/raft-medium-directories.txt"
mutation_word_list="$HOME/Desktop/scandalf/resources/mutation_file.txt"
result_dir="$HOME/Desktop/scandalf/result"

# Check for necessary tools
for tool in feroxbuster subfinder amass httpx; do
    if ! command -v $tool &> /dev/null; then
        cyan
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
            feroxbuster -u "$target_url" -s 200 -w $wordlist --silent --threads 300 -o "$dir/target_forced_browsing.txt" > /dev/null 2>&1

            cat "$dir/target_forced_browsing.txt" | sort -u | uniq | awk '{print $NF}' >> "$dir/${url}_stat_200_forced_browsing.txt"
            rm $dir/target_forced_browsing.txt
        done < "$resolved_file"
        cyan
        echo "      ==> 200_forced_browsing file created"
        reset
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
    subfinder -d $url -o "$dir/${url}_subdomains" > /dev/null 2>&1

    echo "  ==> Running amass enum on $url"
    amass enum -timeout 1 -d $url >> "$dir/${url}_subdomains" 2>&1

    echo "  ==> Running altdns on $url"
    altdns -i $dir/${url}_subdomains -o data_output -w $mutation_word_list -r > "$dir/results_output.txt" > /dev/null 2>&1
    cat "$dir/results_output.txt" >> "$dir/${url}_subdomains"
    rm $dir/results_output.txt

    reset

    sort -u "$dir/${url}_subdomains" > "$dir/${url}_sorted_sub_domain" 
    httpx -follow-redirects -status-code -vhost -threads 300 -silent -l "$dir/${url}_sorted_sub_domain" | sort -u | grep "[200]" | cut -d [ -f1 | uniq > "$dir/${url}_resolved"
}

nuclei_scan(){
    cat "$dir/${url}_subdomains"| httpx -silent |sort -u| nuclei -c 200 -silent -o "$dir/${url}_nuclei" > /dev/null 2>&1
    cyan
    echo '      ==> Nuclei file created'
    reset
}

vuln_extractor(){
    waybackurls ${url} > $dir/${url}_urls > /dev/null 2>&1; gau $url --threads 300  >> $dir/${url}_urls
    cat "$dir/${url}_stat_200_forced_browsing.txt" >> $dir/${url}_urls
    cat $dir/${url}_urls | sort -u > $dir/${url}_final_urls

    cyan
    echo "      ==> Wayback & gau were successfully executed"
    reset
    gf xss $dir/${url}_final_urls | cut -d : -f3-| sort -u > /dev/null 2>&1
    cyan
    echo "      ==> xss file generated"
    reset
    gf ssti $dir/${url}_final_urls | sort -u > $dir/${url}_ssti > /dev/null 2>&1
    cyan
    echo "      ==> ssti file generated"
    reset
    gf ssrf $dir/${url}_final_urls | sort -u > $dir/${url}_ssrf > /dev/null 2>&1
    cyan
    echo "      ==> ssrf file generated"
    reset
    gf sqli $dir/${url}_final_urls | sort -u > $dir/${url}_sqli > /dev/null 2>&1
    cyan
    echo "      ==> sqli file generated"
    reset
    gf redirect $dir/${url}_final_urls | cut -d : -f3- | sort > /dev/null 2>&1
    cyan
    echo "      ==> redirect file generated"
    reset
    gf rce $dir/${url}_final_urls | sort -u > $dir/${url}_rce > /dev/null 2>&1
    cyan
    echo "      ==> rce file generated"
    reset
    gf potential $dir/${url}_final_urls | cut -d : -f3- | sort > /dev/null 2>&1
    cyan
    echo "      ==> potential file generated"
    reset
    gf lfi $dir/${url}_final_urls | sort -u > $dir/${url}_lfi > /dev/null 2>&1
    cyan
    echo "      ==> lfi file generated"
    reset
    gf idor $dir/${url}_final_urls | sort -u > $dir/${url}_idor > /dev/null 2>&1
    cyan
    echo "      ==> idor file generated"
    reset
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
    echo "Performing vuln extraction"
    reset
    vuln_extractor
    green
    echo "Performing nuclei scan"
    reset
    nuclei_scan
    green
    echo "Scan completed successfully."
    reset
}

main