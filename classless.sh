#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "   Usage: bash classless.sh -n '<company name>' [-a|-c] OR bash classless.sh -l <file> [-a|-c]"
    echo ""
    echo "   Options:"
    echo "   -h                          Help Menu"
    echo "   -n <input name>             Specify the company name"
    echo "   -l <file>                   Use a list of company names from the file"
    echo "   -a                          Find ASN for the specified company name"
    echo "   -c                          Find CIDR Ranges for the specified company name"
    echo "   -o <output file>            File to write output result."
    exit 0
}

cexit() {
    echo -e "${RED}[!] Script interrupted. Exiting...${NC}"
    exit 0
}

trap 'cexit 1' SIGINT;

while getopts ":n:acl:o:h" opt; do
    case $opt in
        n)
            input_name="$OPTARG"
            ;;
        a)
            asn_only=true
            ;;
        c)
            cidr_only=true
            ;;
        l)
            input_list_file="$OPTARG"
            ;;
        o)
            if [ -z "$OPTARG" ]; then
                echo -e "${RED}[!] Please specify an output file after the -o option.${NC}"
                show_help
                exit 0
            fi
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

if [[ -z "$input_name" && -z "$input_list_file" ]]; then
    echo -e "${RED}[!] Please provide either a company name using the -n option or a file using the -l option.${NC}"
    show_help
    exit 0
fi

if [[ -n "$input_name" && -n "$input_list_file" ]]; then
    echo -e "${RED}[!] Please provide either a single company name or a file, not both.${NC}"
    show_help
    exit 0
fi

if [[ -n "$input_list_file" && ! -f "$input_list_file" ]]; then
    echo -e "${RED}[!] File '$input_list_file' not found.${NC}"
    show_help
    exit 0
fi

if [ -n "$output_file" ]; then
    if [ -z "$input_name" ] && [ -z "$input_list_file" ]; then
        echo -e "${RED}[!] Please specify a company name or file before using the -o option.${NC}"
        show_help
        exit 0
    fi
fi


if [ -n "$input_list_file" ]; then
    input_names=$(cat "$input_list_file")
else
    input_names="$input_name"
fi


if [ "$asn_only" = true ]; then
    echo -e "${YELLOW}[!] Finding ASN's ${NC}";
    for name in $input_names; do
        curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" "https://bgp.he.net/search?search%5Bsearch%5D=${name}&output=json" | grep '<td><a href="/AS' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\///g' | { [ -z "$output_file" ] && cat || tee -a "$output_file" > /dev/null; };
    done
fi

if [ "$cidr_only" = true ]; then
    echo -e "${YELLOW}[!] Finding CIDR ranges${NC}";
    for name in $input_names; do
        for cidr in $(curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" "https://bgp.he.net/search?search%5Bsearch%5D=${name}&output=json" | grep '<td><a href="/AS' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\///g'); do
            curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0" "https://bgp.he.net/${cidr}#_prefixes&output=json" | grep '<a href="/net' | cut -d '=' -f2 | cut -d '"' -f2 | sed 's/\/net\///g' | grep '\.' | { [ -z "$output_file" ] && cat || tee -a "$output_file" > /dev/null; }
        done    
    done
fi


if [ "$asn_only" = true ]; then
    [ -n "$output_file" ] && echo -e "${GREEN}[**]" $(cat "$output_file" | wc -l)" ASN found.${NC}"
fi
if [ "$cidr_only" = true ]; then
    [ -n "$output_file" ] && echo -e "${GREEN}[**]" $(cat "$output_file" | wc -l)" CIDR Ranges found.${NC}";
fi
