#!/bin/bash

##
# @brief: Sets the terminal text color to red.
##
red() {
    tput setaf 1
}

##
# @brief: Sets the terminal text color to green.
##
green() {
    tput setaf 2
}

##
# @brief: Sets the terminal text color to yellow.
##
yellow() {
    tput setaf 3
}

##
# @brief: Sets the terminal text color to cyan.
##
cyan() {
    tput setaf 6
}

##
# @brief: Resets the terminal text color to the default.
##
reset() {
    tput sgr0
}

##
# @brief: Prints the "ScanDalf" banner in ASCII art in red color.
# @description: Displays the ASCII art banner for the ScanDalf tool, followed by a descriptive tagline.
#               This function is used to visually signify the start of the tool's execution in the terminal.
##
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
wordlist= "<DEFAULT LIST>"
mutation_word_list="<MUTATION WORDLIST>"
fingerprint = "<DEFAULT FINGERPRINT FILE>"
result_dir="<PATH FOR RESULT DIRECTORY>"

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

##
# @brief: Performs forced browsing using feroxbuster.
# @description: Reads resolved URLs from a file and runs feroxbuster on each URL.
#               Outputs the results to a specified file.
##
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

##
# @brief: Enumerates subdomains of the given URL.
# @description: Uses subfinder, amass, and altdns to find subdomains and writes the results to a file.
##
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

##
# @brief: Performs a nuclei scan on the enumerated subdomains.
##
nuclei_scan(){
    cat "$dir/${url}_subdomains"| httpx -silent |sort -u| nuclei -c 200 -silent -o "$dir/${url}_nuclei" > /dev/null 2>&1
    cyan
    echo '      ==> Nuclei file created'
    reset
}

##
# @brief: Extracts various vulnerabilities from URLs.
# @description: Utilizes tools like waybackurls and gau to collect URLs, then uses gf (grep framework) to identify 
#               common vulnerabilities like XSS, SSTI, SSRF, SQLi, redirects, RCE, LFI, and IDOR. It generates separate 
#               files for each vulnerability type if applicable URLs are found.
##
vuln_extractor(){
    waybackurls ${url} > $dir/${url}_urls > /dev/null 2>&1; gau $url --threads 300  >> $dir/${url}_urls
    cat "$dir/${url}_stat_200_forced_browsing.txt" >> $dir/${url}_urls
    cat $dir/${url}_urls | sort -u > $dir/${url}_final_urls

    if [ -f "$dir/${url}_final_urls" ]; then
        cyan
        echo "      ==> wayback & gau were successfully exacuted"
        reset
    else
        red
        echo "      ==> wayback & gau did not exacute successfully"
        reset
    fi

    gf xss $dir/${url}_final_urls | cut -d : -f3-| sort -u > $dir/${url}_xss > /dev/null 2>&1
    if [ -f "$dir/${url}_xss" ]; then
        cyan
        echo "      ==> xss file generated"
        reset
    else
        red
        echo "      ==> xss file was not generated"
        reset
    fi

    gf ssti $dir/${url}_final_urls | sort -u > $dir/${url}_ssti > /dev/null 2>&1
    if [ -f "$dir/${url}_ssti" ]; then
        cyan
        echo "      ==> ssti file generated"
        reset
    else
        red
        echo "      ==> ssti file was not generated"
        reset
    fi

    gf ssrf $dir/${url}_final_urls | sort -u > $dir/${url}_ssrf > /dev/null 2>&1
    if [ -f "$dir/${url}_ssrf" ]; then
        cyan
        echo "      ==> ssrf file generated"
        reset
    else
        red
        echo "      ==> ssrf file was not generated"
        reset
    fi

    gf sqli $dir/${url}_final_urls | sort -u > $dir/${url}_redirect > /dev/null 2>&1
    if [ -f "$dir/${url}_redirect" ]; then
        cyan
        echo "      ==> sqli file generated"
        reset
    else
        red
        echo "      ==> sqli file was not generated"
        reset
    fi

    gf redirect $dir/${url}_final_urls | cut -d : -f3- | sort -u > $dir/${url}_redirect >/dev/null 2>&1
    if [ -f "$dir/${url}_redirect" ]; then
        cyan
        echo "      ==> redirect file generated"
        reset
    else
        red
        echo "      ==> redirect file was not generated"
        reset
    fi

    gf rce $dir/${url}_final_urls | sort -u > $dir/${url}_rce > /dev/null 2>&1
    if [ -f "$dir/${url}_rce" ]; then
        cyan
        echo "      ==> rce file generated"
        reset
    else
        red
        echo "      ==> rce file was not generated"
        reset
    fi

    gf potential $dir/${url}_final_urls | cut -d : -f3- | sort -u > $dir/${url}_potential >/dev/null 2>&1
    if [ -f "$dir/${url}_potential" ]; then
        cyan
        echo "      ==> potential file generated"
        reset
    else
        red
        echo "      ==> potential file was not generated"
        reset
    fi

    gf lfi $dir/${url}_final_urls | sort -u > $dir/${url}_lfi > /dev/null 2>&1
    if [ -f "$dir/${url}_lfi" ]; then
        cyan
        echo "      ==> lfi file generated"
        reset
    else
        red
        echo "      ==> lfi file was not generated"
        reset
    fi

    gf idor $dir/${url}_final_urls | sort -u > $dir/${url}_idor > /dev/null 2>&1
    if [ -f "$dir/${url}_idor" ]; then
        cyan
        echo "      ==> Idor file generated"
        reset
    else
        red
        echo "      ==> Idor file was not generated"
        reset
    fi
}

##
# @brief: Checks for potential subdomain takeovers.
# @description: Uses tools like subjack and subover to check for subdomain takeover vulnerabilities in the 
#               enumerated subdomains. Outputs potential vulnerable subdomains to a file.
##
subdomain_takeover(){
    subjack -w $dir/${url}_subdomains -t 300 -timeout 30 -c $fingerprint > $dir/potential_takover_domain.txt > /dev/null 2>&1
    subover -l $dir/${url}_subdomains -t 300 -timeout 30 >> $dir/potential_takover_domain.txt
    if [ -f "$dir/potential_takover_domain.txt" ]; then
        cyan
        echo "      ==> potential subdomain takeover file generated"
        reset
    else
        red
        echo "      ==> subdomain file was not generated"
        reset
    fi
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
    echo "Performing checks for subdomain takeover"
    reset
    subdomain_takeover

    green
    echo "Performing nuclei scan"
    reset
    nuclei_scan

    green
    echo "Scan completed successfully."
    reset
}

main