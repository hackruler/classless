#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "   Usage: bash asn.sh [options] 'company name' "
    echo ""
    echo "   Options:"
    echo "   -h                          Help Menu"
    echo "   -a <input name>             Find ASN for the specified company name (e.g., bash classless.sh -a '<comany name>')"
    echo "   -c <input name>             Find CIDR Rnages for the specified company name (e.g., bash classless.sh -c '<comany name>')"    
    echo "   -o <output file>            file to write output result."
    exit 0
}

cexit() {
    echo -e "${RED}[!] Script interrupted. Exiting...${NC}"
    [ -e asn_results123.txt ] && rm -f asn_results123.txt
    exit "$1"
}

trap 'cexit 1' SIGINT;

while getopts ":a:c:o:h" opt; do
    case $opt in
        a)
            asn_only=true
            input_name="$OPTARG"
            ;;
        c)
            cidr_only=true
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

if [ "$asn_only" = true ]; then
    echo -e "${YELLOW}[!] Finding ASN for "$input_name"${NC}";
    curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" https://bgp.he.net/search\?search%5Bsearch%5D=${input_name}\&output=json | grep '<td><a href="/AS' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\///g' | { [ -z "$output_file" ] && cat || tee "$output_file" > /dev/null; };
fi

if [ "$cidr_only" = true ]; then
    echo -e "${YELLOW}[!] Finding CIDR ranges for "$input_name"${NC}";
    curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" https://bgp.he.net/search\?search%5Bsearch%5D=${input_name}\&output=json | grep '<td><a href="/AS' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\///g' | tee -a asn_results123.txt > /dev/null; 

    for cidr in $(cat asn_results123.txt); do
        curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" https://bgp.he.net/${cidr}#_prefixes\&output=json | grep '<a href="/net' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\/net\///g' | grep '\.' | { [ -z "$output_file" ] && cat || tee -a "$output_file" > /dev/null; };
    done

fi

if [ "$asn_only" = true ]; then
    [ -n "$output_file" ] && echo -e "${GREEN}[**]" $(cat "$output_file" | wc -l)" ASN found.${NC}"
fi
if [ "$cidr_only" = true ]; then
    rm asn_results123.txt
    [ -n "$output_file" ] && echo -e "${GREEN}[**]" $(cat "$output_file" | wc -l)" CIDR Ranges found.${NC}";
fi
