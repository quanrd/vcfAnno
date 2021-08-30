## vcfAnno
Variant annotation for Bioinformatics Technical Challenge

vcfAnno.sh is a variant annotation script for the Bioinformatics Technical Challenge.
Before running vcfAnno, the following steps are required.


### 1. Install dependencies

BCFtools is a program for manipulating files in the Variant Call Format (VCF).
The BCFtools (v1.11) can be found from http://samtools.github.io/bcftools/howtos/install.html

vcfAnno uses Perl tool/script to annotate variant and convert VCF file to MAF file.
Perl 5, version 16, subversion 3 (v5.16.3) can be found from https://www.perl.org/
Perl modules JSON and LWP::UserAgent are required for REST API.


vcfAnno use ANNOVAR to annotate variants. The latest version of ANNOVAR can be found on the following site:
https://www.openbioinformatics.org/annovar/annovar_download_form.php

Put the vcf2maf.pl file in the working directory where one plan to run the analysis


### 2. Run the analysis

(1) Normalize indels

The position, reference allele and alternative allele of some indels in the Challenge_data.vcf are not in standard format. BCFtools could normalize those variants, check if REF alleles match the reference.

Please run the script in 1_norm_vcf_bcftools.sh. human_g1k_v37.fasta is the human genome hg19 reference sequencing file that has been used for the variant calling of Challenge_data.vcf, please replace the file path of human_g1k_v37.fasta according to your environment settings. 
The file human_g1k_v37.fasta can be downloaded from ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz

```
bcftools norm -f human_g1k_v37.fasta  Challenge_data.vcf  > Challenge_data_new.vcf
```

(2) vcfAnno

Run vcfAnno with the --help flag to get usage information:

```
sh vcfAnno.sh --help
```

vcfAnno has four parameters.

-f the file path of VCF file.

-d working directory (should be an absolute path)

-a ANNOVAR installing directory (should be an absolute path, e.g. /home/mary/software/annovar)

-v reference genome version of the VCF file (e.g. hg19, hg38).

Execute the following line in the your working directory:
```
sh vcfAnno.sh -f Challenge_data_new.vcf -d <your working directory> -a <path to ANNOVAR installation> -v hg19
```

### 3. Output

Challenge_data_new.hg19_multianno.tsv is the final result of vcfAnno.

The results including 17 columns, Please find the following information for the details.

* Chrom: Chromosome

* Pos: Position

* Ref: Reference allele

* ALT: Alternative allele

* Qual: Phred-scaled quality score assigned by the variant caller.

* Gene.refGene: Gene symbol

* ExonicFunc.refGene: effect of variant

* Type: Type of variation

* AAChange.refGene:

* CLNSIG: Clinical significance for this single variant recorded in ClinVar database

* CLNDN: Clinical Disease Name recorded in ClinVar database

* AF: Allele frequencies in ExAC exome cohort

* Sample: Sample name

* GT: Genotype

* DP: Depth of sequence coverage at the site of variation

* RO: Number of reads supporting the reference allele

* AO: Number of reads supporting the alternative allele

* Rate: Percentage of reads supporting the variant versus those supporting reference reads

* AF_get_from_API: The update allele frequencies of ExAC exome cohort obtained from REST API.






Note: vcfAnno does not separate multiallelic variants. The allele frequencies in AF column are directly obtained from the ANNOVAR ExAC database which is a little bit older than AF_get_from_API which were obtained using ExAC REST API.
