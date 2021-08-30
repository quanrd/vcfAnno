#!/usr/bin/env perl

##TODO: convert vcf to maf
##Date: 2021-08-18
##Contact: tao.qing@yale.edu

#use strict;
#use warnings;
use LWP::UserAgent ();
use JSON;

if (@ARGV == 0 && -t STDIN && -t STDERR) { 
    print STDERR "$0: Usage: vcf2maf.pl -v <vcf file> \n";
}

my $vcf = $ARGV[0];
print $vcf."\n";

unless ($vcf=~m/(.+).vcf/){print STDERR "$0: please provide a vcf file"}
my $name = $1;


open(my $OUT, ">", $name.".tsv");

my $n=0;
open(my $vcfFile, "<", $vcf) or die "Error: cannot read $vcf: $!\n";;
	#important iterms to extract
	my @info_array=qw(Gene.refGene TYPE ExonicFunc.refGene AAChange.refGene CLNSIG CLNDN AF);

	while(my $line=<$vcfFile>){
		chomp($line);
		#print header
		if($n==0 && $line=~m/#CHROM/){
			 @elem_nam=split("\t",$line);
			 $spl_num=@elem_nam-1;
			 @spl_nam=@elem_nam[9..$spl_num];
			 $header="Chrom\tPos\tRef\tALT\tQual\t".join("\t",@info_array)."\tSample\tGT\tDP\tRO\tAO\tRate\tAF_get_from_API\n";
			print $OUT $header;
			$n++;
		}

		#process variants
		if($line!~m/^#/){
			my @elem=split("\t",$line);
			my @info=split(";",$elem[7]);

			my %info_elem;
			foreach (@info) {
				my @tmp=split("=",$_);
				$info_elem{$tmp[0]}= $tmp[1];
			}
			
			my @info_value=();
			foreach (@info_array) {
				push @info_value, $info_elem{$_};
			}

			my $mut=$elem[0]."-".$elem[1]."-".$elem[3]."-".$elem[4];

			my $i=0;
			my $m=0;
			#all samples
			foreach(@elem[9..$spl_num]){
					my $genotype=$_;
					my %qc_hash=depth_info($elem[8],$genotype);
					if($qc_hash{"RO"} != 0){ 
						if($qc_hash{"AO"}=~m/(\d+),(\d+)/){
							$rate=sprintf("%.2f",$1/$qc_hash{"RO"}).",".sprintf("%.2f",$2/$qc_hash{"RO"});
						}else{
							$rate = sprintf("%.2f",$qc_hash{"AO"}/$qc_hash{"RO"});
						}
					}else{
						$rate="Inf";
					}
					#results to tsv file
					my $output=join("\t",@elem[0,1,3,4,5])."\t".join("\t",@info_value)."\t".$spl_nam[$i]."\t".$qc_hash{"GT"}."\t".$qc_hash{"DP"}."\t".$qc_hash{"RO"}."\t".$qc_hash{"AO"}."\t".$rate."\t".exac_api($mut)."\n";
					print $OUT $output;
				$i++;
			}
		}
	}

#function convert genotype information to hash.
sub depth_info  
{
	my($key,$value)=@_;

		my @key=split(":",$key);
		my @value=split(":",$value);
		my %info;
		my $i=0;
		foreach(@key){
			$info{$_}=$value[$i];
			$i++;
		}
	my %depth_info;
	$depth_info{"GT"}=$info{"GT"};
	$depth_info{"DP"}=$info{"DP"};
	$depth_info{"RO"}=$info{"RO"};
	$depth_info{"AO"}=$info{"AO"};
	return(%depth_info);
}

sub exac_api  
{
	my($variant)=@_;
	my $ua = LWP::UserAgent->new(timeout => 10);
	$ua->env_proxy;
	my $response = $ua->get("http://exac.hms.harvard.edu/rest/variant/".$variant);
	if ($response->is_success) {
		my $content = decode_json($response->decoded_content);
		%variant=%{%{$content}{'variant'}};
		$allele_freq=%variant{'allele_freq'};
	}else {
		$allele_freq="NA";
	}
	return($allele_freq);
}


$OUT ->close;