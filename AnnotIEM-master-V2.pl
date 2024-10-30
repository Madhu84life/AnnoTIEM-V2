$inp=@ARGV[0];chomp $inp;

`./CODES/E1-SPLIT-SEQUENCE-MASTER $inp`;
######################## Prepare Output Files ############################
$dtimeN=localtime();chomp $dtimeN;
@dtnm= split(/\s+/,$dtimeN);chomp @dtnm[1];chomp @dtnm[2];chomp @dtnm[3];chomp @dtnm[4];
$date=@dtnm[1].@dtnm[2]."_".@dtnm[4];
@dtnm[3]=~ s/\://g;chomp @dtnm[3];
$dandt=$date."_".@dtnm[3];chomp $dandt;
`mkdir RESULT-FILES-$inp-$dandt`;
open(REF1,">$inp-Parsed-Output-reformated-ncbi");
open(REF2,">$inp-Parsed-Output-reformated-silva");
open(REF3,">$inp-Parsed-Output-reformated-rdp");
open(REF4,">$inp-Parsed-Output-reformated-gtdb");
open(OUT1,">$inp-Annotation-with-Parameters");
open(OUT4,">$inp-Annotation-Final-Result");
open(LOG,">$inp-LOGFILE");
$dtime0=localtime();chomp $dtime0;
$numseq=`grep -c ">" $inp`;chomp $numseq;
print LOG "Running AnnotIEM-V3 for sequence set < $inp >\n";
print LOG "Number of Sequences = $numseq\n";
print LOG "Runtime Start = $dtime0\n";
print LOG ">>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
print REF1 "Query-set|Datadase|Query-ID|Query-Length|Organismname|Subject-ID|Subject-Lineage|Subject-Length|Bit-Score|E-value|Identity|Alignment-Length\n";
print REF2 "Query-set|Datadase|Query-ID|Query-Length|Organismname|Subject-ID|Subject-Lineage|Subject-Length|Bit-Score|E-value|Identity|Alignment-Length\n";
print REF3 "Query-set|Datadase|Query-ID|Query-Length|Organismname|Subject-ID|Subject-Lineage|Subject-Length|Bit-Score|E-value|Identity|Alignment-Length\n";
print REF4 "Query-set|Datadase|Query-ID|Query-Length|Organismname|Subject-ID|Subject-Lineage|Subject-Length|Bit-Score|E-value|Identity|Alignment-Length\n";
print OUT1 "OTU-ID\tTopHitSpecies\tDatabase\tIdentityTopHit\tRankTopHit\tMajorityHitSpecies\tIdentityMajorityHit\tDrop\tRank\tTotalNumberOfHit\tFrequencyMajorityHit\tTopHitGenus\tDatabase\tIdentityTopHit\tRankTopHit\tMajorityHitGenus\tIdentityMajorityHit\tDrop\tRank\tTotalNumberOfHit\tFrequencyMajorityHit\n";
print OUT4 "Status\tSequence-ID\tRecommended-Annotation\tTaxonomy\n";

####################### Program Start ############################
@list=`cat $inp | grep ">" |sed -e '{s/>//g}'`;
$cnt=0;
foreach $l(@list)
{
	chomp $l;
	$cnt++;
######################## Run BLASTn ############################
	`blastn -db ./DATABASES/16SMicrobial -query INPUT-seq-$l -evalue 0.000001 -perc_identity 90 -qcov_hsp_perc 90 -out Boutput-ncbi-$l`;
	`blastn -db ./DATABASES/GTDB2021 -query INPUT-seq-$l -evalue 0.000001 -perc_identity 90 -qcov_hsp_perc 90 -out Boutput-gtdb-$l`;
	`blastn -db ./DATABASES/SilvaAll-2020 -query INPUT-seq-$l -evalue 0.000001 -perc_identity 90 -qcov_hsp_perc 90 -out Boutput-silva-$l`;
	`blastn -db ./DATABASES/RDP-sequences-2020 -query INPUT-seq-$l -evalue 0.000001 -perc_identity 90 -qcov_hsp_perc 90 -out Boutput-rdp-$l`;
	$dtime1=localtime();chomp $dtime1;
	print LOG "$dtime1\tBlast runs complete for $l (No $cnt)\n";

####################### Parse BLASTn Outputs ##################	
	`./CODES/E2-PARSE-BLAST-OUTPUT Boutput-ncbi-$l`;
	`./CODES/E2-PARSE-BLAST-OUTPUT Boutput-gtdb-$l`;
	`./CODES/E2-PARSE-BLAST-OUTPUT Boutput-silva-$l`;
	`./CODES/E2-PARSE-BLAST-OUTPUT Boutput-rdp-$l`;
	$dtime2=localtime();chomp $dtime2;
        print LOG "$dtime2\tBlast Parsing complete for $l (No $cnt)\n";
######################## Reformat Parsed Outputs ###############
	`./CODES/E4-REFORMAT-PARSEDFILE-GTDB $l`;
	`./CODES/E4-REFORMAT-PARSEDFILE-NCBI $l`;
	`./CODES/E4-REFORMAT-PARSEDFILE-SILVA $l`;
	`./CODES/E4-REFORMAT-PARSEDFILE-RDP $l`;
	$dtime3=localtime();chomp $dtime3;
        print LOG "$dtime3\tReformatting complete for $l (No $cnt)\n";
	@rfncbi=`cat ParsedOutputReformated-ncbi-$l`;print REF1 @rfncbi;
	print REF1 "==========================================================================\n";
	@rfsilva=`cat ParsedOutputReformated-silva-$l`;print REF2 @rfsilva;
	print REF2 "==========================================================================\n";
	@rfrdp=`cat ParsedOutputReformated-rdp-$l`;print REF3 @rfrdp;
	print REF3 "==========================================================================\n";
	@rfgtdb=`cat ParsedOutputReformated-gtdb-$l`;print REF4 @rfgtdb;
	print REF4 "==========================================================================\n";
####################### Annotate and Select ####################
	`./CODES/E5-COMBINE-AND-SELECT-XX8 $l`;
	#`perl xx-8-v3.pl $l`;
	`./CODES/E6-TAG-AND-FLAG $l`;
	`./CODES/E7-ASSIGN-TAXONOMY $l`;
	`./CODES/E8-FORMAT-FINAL $l`;
	#`perl assign-taxonomy5.pl $l`;
	#`perl format-final.pl $l`;
	@annot=`cat Annotation-$l`;print OUT1 @annot;
	@marked=`cat SelectedTaxonomyMarked-$l`;print OUT4 @marked;
	$dtime4=localtime();chomp $dtime4;
        print LOG "$dtime4\tAnnotation complete for $l (No $cnt)\n";
####################### Clean Interim Data ######################
	`rm INPUT-seq-$l`;
	`rm Boutput-ncbi-$l`;`rm Boutput-gtdb-$l`;`rm Boutput-silva-$l`;`rm Boutput-rdp-$l`;
	`rm ParsedOutput-ncbi-$l`;`rm ParsedOutput-gtdb-$l`;`rm ParsedOutput-silva-$l`;`rm ParsedOutput-rdp-$l`;
	`rm ParsedOutputReformated-ncbi-$l`;`rm ParsedOutputReformated-gtdb-$l`;`rm ParsedOutputReformated-silva-$l`;`rm ParsedOutputReformated-rdp-$l`;
	`rm Annotation-$l`;
	`rm Selected-$l`;
	`rm SelectedTaxonomy-$l`;
	`rm SelectedTaxonomyMarked-$l`;
	`rm DTF-$l`;`rm Temp-out-$l`;
	`rm Temp-merge-$l`;`rm Temp-merge2-$l`;`rm Temp-merge3-$l`;
	`rm 5-temp-$l`;`rm 4-temp-$l`;`rm 3-temp-$l`;`rm 2-temp-$l`;`rm 1-temp-$l`;
	print LOG ">>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
}
`mv $inp-* RESULT-FILES-$inp-$dandt`;
$dtime5=localtime();chomp $dtime5;
print LOG "Runtime End = $dtime5\n";
