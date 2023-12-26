
# ScanDalf

<img width="452" alt="Screenshot 2023-12-26 at 2 02 48 AM" src="https://github.com/AkshatJoshi2000/scandalf/assets/39386084/8fe2ab82-57bd-43b7-a7b0-91ab1abcc095">

ScanDalf is a sophisticated Bash script designed for cybersecurity professionals focusing on web reconnaissance and penetration testing. This tool streamlines the process of subdomain enumeration and forced browsing, leveraging popular cybersecurity tools like feroxbuster, subfinder, amass, and httpx. It features an intuitive command-line interface with colorful text outputs, enhancing user experience and readability.

## Authors

- [@AkshatJoshi2000](https://github.com/AkshatJoshi2000)


## Tools

List of tools that are used to perform and cover different aspects of web reconnaissance, from various sources, using different methods. 


| Tool | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Subfinder` | `Subdomain Enumeration`  | Itis a subdomain discovery tool that returns valid subdomains for websites, using passive online sources.|
| `amass`| `Attack Surface Mapper`| performs network mapping of attack surfaces and external asset discovery using open source information gathering and active reconnaissance techniques. |
| `Feroxbuster` | `Forced Browsing` | feroxbuster is a tool designed to perform Forced Browsing. Forced browsing is an attack where the aim is to enumerate and access resources that are not referenced by the webapps, but are still accessible by an attacker.|
|`altdns`|`Subdomain discovery`|Altdns is a DNS recon tool that allows for the discovery of subdomains that conform to patterns.|




## Usage

` ./scandalf -u <URL> [-w] <wordlist>`




## Documentation

[Documentation](https://linktodocumentation)


## User details

To run this project, you will need to change the following  variables in your scandalf.sh file

`1. wordlist` - Set this as any default wordlist

`2. mutation_word_list` - add a mutation list, you can also use the one that I have provided just alter the path.

`3. result_dir` - set this to where you want to store yout final reports of the recon. 


## Support

For support, email akshatjoshi2000@gmail.com.

