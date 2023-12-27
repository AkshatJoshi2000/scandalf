#!/bin/bash

# Based on OS uncomment the one that would work for you, and comment the one not required. 

# Go based packages
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# amass go installation
go install -v github.com/owasp-amass/amass/v4/...@master

# amass macOS
# brew tap owasp-amass/amass
# brew install amass


# Python based packages
pip3 install py-altdns==1.0.2

# Kali
# sudo apt update && sudo apt install -y feroxbuster

# linux
# curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | bash -s $HOME/.local/bin

# macOS
# brew install feroxbuster

# Windows via chocolatey
# choco install feroxbuster


# nuclei go installation
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
# nuclei macOS installation
# brew install nuclei

# go installation for waybackurls
go install github.com/tomnomnom/waybackurls@latest

# go installation for gf
go install github.com/tomnomnom/gf@latest

# go installation for gau
$ go install github.com/lc/gau/v2/cmd/gau@latest
# gau automatically looks for a configuration file at $HOME/.gau.toml or%USERPROFILE%\.gau.toml. I have added this file in the resources. 


