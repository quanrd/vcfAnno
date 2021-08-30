#!/bin/bash

# Usage info
usage="$(basename "$FUNCNAME") [-f VCF] [-d WORKDIR] [-a ANNOVAR] [-v GENOME]...
     -f VCF file 
     -d work directory (absolute path)
     -a Annovar software path directory (absolute path)
     -v Reference genome version, e.g. hg19, hg38
"
#parse arguments
OPTIND=1
while getopts ":f:d:a:v:" opt; do
    case "$opt" in
        f)
            vcf=$OPTARG
            ;;
        d)  workdir="$OPTARG"
            ;;
        a)  annovar="$OPTARG"
            ;;
        v)  genome="$OPTARG"
            ;;
        :)  
            printf "missing argument for -%s\n" "$OPTARG" >&2
            echo "$usage" >&2
            exit 1
            ;;
        \?)
            echo "$usage" >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --


if ! [ -x "$(command -v perl)" ]; then
  echo 'Error: perl is not installed.' >&2
  exit 1
fi


#work dir
cd $workdir

#output file name
nam="$(echo $(basename "$vcf") | sed -e 's/.vcf//;')";

annovardb=${annovar}/humandb/


#prepare Annovar database
refGene=$(ls ${annovardb}/${genome}_refGene* 2> /dev/null | wc -l)
if [ $refGene == "0" ]; then
    ${annovar}/annotate_variation.pl -downdb -buildver ${genome} -webfrom annovar refGene ${annovar}/humandb/
fi

gnomad_exome=$(ls "${annovardb}/${genome}_gnomad211_exome.txt" 2> /dev/null | wc -l)
if [ $gnomad_exome == "0" ]; then
#if [ ! -d "${annovar}/humandb/hg19_gnomad211_exome*" ]; then
    ${annovar}/annotate_variation.pl -downdb -webfrom annovar -buildver ${genome} gnomad211_exome ${annovar}/humandb
fi

clinvar=$(ls "${annovardb}/${v}_clinvar_20200316.txt" 2> /dev/null | wc -l)
if [ $clinvar == "0" ]; then
    ${annovar}/annotate_variation.pl -downdb -webfrom annovar -buildver ${genome} clinvar_20200316 ${annovar}/humandb
fi


#variants annotation
${annovar}/table_annovar.pl -vcfinput ${vcf} ${annovar}/humandb/ -buildver ${genome} -out ${nam} -remove -protocol refGene,gnomad211_exome,clinvar_20200316 -operation gx,f,f -nastring .; 

#convert annotated vcf file to maf (tsv format)
perl vcf2maf.pl ${nam}.${genome}_multianno.vcf


#rm intermediate files
rm ${nam}.avinput
rm ${nam}.${genome}_multianno.txt

