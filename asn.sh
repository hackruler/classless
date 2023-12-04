#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "   Usage: bash asn.sh -l 'company name' "
    echo "   Options:"
    echo "   -h                          Help Menu"
    echo "   -l <input name>             Specify the company name you want to find CIDR ranges. (e.g., bash asn.sh -l 'Disney')"
    echo "   -o <output file>            file to write output result."
    exit 0
}

cexit() {
    echo -e "${RED}[!] Script interrupted. Exiting...${NC}"
    exit "$1"
}

trap 'cexit 1' SIGINT;

while getopts ":l:o:h" opt; do
    case $opt in
        l)
            input_name="$OPTARG"
            ;;
        o)
			output_file="$OPTARG"
			;;
        h)
            show_help
            ;;             
        \?)
            echo -e "${RED}Invalid option.${NC}"
            show_help
            ;;
    esac
done

echo -e "${YELLOW}[!] Finding ASN to "$input_name"${NC}";

curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" https://bgp.he.net/search\?search%5Bsearch%5D=${input_name}\&output=json | grep '<td><a href="/AS' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\///g' | tee asn.txt > /dev/null;

echo -e "${GREEN}[*]" $(cat asn.txt | wc -l) "ASN found${NC}";
echo -e "${YELLOW}[!] Finding CIDR ranges respective to ASN. ${NC}";


if [ -z "$output_file" ]; then
    for cidr in $(cat asn.txt); do
    	curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" https://bgp.he.net/${cidr}#_prefixes\&output=json | grep '<a href="/net' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\/net\///g' | grep '\.';
	done
else
    for cidr in $(cat asn.txt); do
    	curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" https://bgp.he.net/${cidr}#_prefixes\&output=json | grep '<a href="/net' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\/net\///g' | grep '\.' | tee -a "$output_file" > /dev/null
    done
fi

if [ -z "$output_file" ]; then
    echo -e "${GREEN}[*] ........... SCRIPT ENDED .................${NC}"
else
    echo -e "${GREEN}[*] CIDR ranges are stored in "$output_file"${NC}"
    echo -e "${GREEN}[**]" $(cat "$output_file" | wc -l)" CIDR ranges found.${NC}";
fi
