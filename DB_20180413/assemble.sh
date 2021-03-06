#!/bin/bash

# assemble.sh generated by masurca
CONFIG_PATH="/scratch/user/tangxt/DBiology/DB1813/test0413/build_masurca_se.conf"
CMD_PATH="/software/tamusc/Bio/MaSuRCA/3.1.2/bin/masurca"

# Test that we support <() redirection
(eval "cat <(echo test) >/dev/null" 2>/dev/null) || {
  echo >&2 "ERROR: The shell used is missing important features."
  echo >&2 "       Run the assembly script directly as './$0'"
  exit 1
}

# Parse command line switches
while getopts ":rc" o; do
  case "${o}" in
    c)
    echo "configuration file is '$CONFIG_PATH'"
    exit 0
    ;;
    r)
    echo "Rerunning configuration"
    exec perl "$CMD_PATH" "$CONFIG_PATH"
    echo "Failed to rerun configuration"
    exit 1
    ;;
    *)
    echo "Usage: $0 [-r] [-c]"
    exit 1
    ;;
  esac
done
set +e
# Set some paths and prime system to save environment variables
save () {
  (echo -n "$1=\""; eval "echo -n \"\$$1\""; echo '"') >> environment.sh
}
GC=
RC=
NC=
if tty -s < /dev/fd/1 2> /dev/null; then
  GC='\e[0;32m'
  RC='\e[0;31m'
  NC='\e[0m'
fi
log () {
  d=$(date)
  echo -e "${GC}[$d]${NC} $@"
}
fail () {
  d=$(date)
  echo -e "${RC}[$d]${NC} $@"
  exit 1
}
signaled () {
  fail Interrupted
}
trap signaled TERM QUIT INT
rm -f environment.sh; touch environment.sh

# To run tasks in parallel
run_bg () {
  semaphore -j $NUM_THREADS --id masurca_$$ -- "$@"
}
run_wait () {
  semaphore -j $NUM_THREADS --id masurca_$$ --wait
}
export PATH="/general/software/x86_64/tamusc/Bio/MaSuRCA/3.1.2/bin:/general/software/x86_64/tamusc/Bio/MaSuRCA/3.1.2/bin/../CA/Linux-amd64/bin:$PATH"
save PATH
NUM_THREADS=10
save NUM_THREADS
log 'Processing pe library reads'
rm -rf meanAndStdevByPrefix.pe.txt
echo 'se 400 20' >> meanAndStdevByPrefix.pe.txt
run_bg rename_filter_fastq 'se' <(exec expand_fastq '/scratch/user/tangxt/DBiology/test0413.data/Phage_Pool_TruSeq_12_CTTGTA_R1.fastq' | awk '{if(length($0>200)) print substr($0,1,200); else print $0;}') <(exec expand_fastq '/scratch/user/tangxt/DBiology/test0413.data/Phage_Pool_TruSeq_12_CTTGTA_R1.fastq' | awk '{if(length($0>200)) print substr($0,1,200); else print $0;}' ) > 'se.renamed.fastq'
run_wait

head -q -n 40000  se.renamed.fastq | grep --text -v '^+' | grep --text -v '^@' > pe_data.tmp
PE_AVG_READ_LENGTH=`awk '{n+=length($1);m++;}END{print int(n/m)}' pe_data.tmp`
save PE_AVG_READ_LENGTH
echo "Average PE read length $PE_AVG_READ_LENGTH"
KMER=`for f in se.renamed.fastq;do head -n 80000 $f |tail -n 40000;done | perl -e 'while($line=<STDIN>){$line=<STDIN>;chomp($line);push(@lines,$line);$line=<STDIN>;$line=<STDIN>}$min_len=100000;$base_count=0;foreach $l(@lines){$base_count+=length($l);push(@lengths,length($l));@f=split("",$l);foreach $base(@f){if(uc($base) eq "G" || uc($base) eq "C"){$gc_count++}}} @lengths =sort {$b <=> $a} @lengths; $min_len=$lengths[int($#lengths*.75)];  $gc_ratio=$gc_count/$base_count;$kmer=0;if($gc_ratio<0.5){$kmer=int($min_len*.7);}elsif($gc_ratio>=0.5 && $gc_ratio<0.6){$kmer=int($min_len*.5);}else{$kmer=int($min_len*.33);} $kmer++ if($kmer%2==0); $kmer=31 if($kmer<31); $kmer=127 if($kmer>127); print $kmer'`
save KMER
echo "choosing kmer size of $KMER for the graph"
KMER_J=$KMER
MIN_Q_CHAR=`cat se.renamed.fastq |head -n 50000 | awk 'BEGIN{flag=0}{if($0 ~ /^\+/){flag=1}else if(flag==1){print $0;flag=0}}'  | perl -ne 'BEGIN{$q0_char="@";}{chomp;@f=split "";foreach $v(@f){if(ord($v)<ord($q0_char)){$q0_char=$v;}}}END{$ans=ord($q0_char);if($ans<64){print "33\n"}else{print "64\n"}}'`
save MIN_Q_CHAR
echo MIN_Q_CHAR: $MIN_Q_CHAR
JF_SIZE=`ls -l *.fastq | awk '{n+=$5}END{s=int(n/50); if(s>44000000)print s;else print "44000000";}'`
save JF_SIZE
perl -e '{if(int('$JF_SIZE')>44000000){print "WARNING: JF_SIZE set too low, increasing JF_SIZE to at least '$JF_SIZE', this automatic increase may be not enough!\n"}}'
log Creating mer database for Quorum.
quorum_create_database -t 10 -s $JF_SIZE -b 7 -m 24 -q $((MIN_Q_CHAR + 5)) -o quorum_mer_db.jf se.renamed.fastq
if [ 0 != 0 ]; then
  fail Increase JF_SIZE in config file, the recommendation is to set this to genome_size*coverage/2
fi

log Error correct PE.

quorum_error_correct_reads  -q $((MIN_Q_CHAR + 40)) --contaminant=/general/software/x86_64/tamusc/Bio/MaSuRCA/3.1.2/bin/../share/adapter.jf -m 1 -s 1 -g 1 -a 3 -t 10 -w 10 -e 3   quorum_mer_db.jf se.renamed.fastq --no-discard -o pe.cor --verbose 1>quorum.err 2>&1 || {
  fail Error correction of PE reads failed. Check pe.cor.log.
}


log Estimating genome size.
jellyfish count -m 31 -t 10 -C -s $JF_SIZE -o k_u_hash_0 pe.cor.fa
ESTIMATED_GENOME_SIZE=`jellyfish histo -t 10 -h 1 k_u_hash_0 | tail -n 1 |awk '{print $2}'`
if [ $ESTIMATED_GENOME_SIZE -ge 15000000 ]; then echo "WARNING! CA_PARAMETERS = cgwErrorRate=0.25 and LIMIT_JUMP_COVERAGE = 60 in config file should only be used for bacterial genomes; set cgwErrorRate=0.15 and  LIMIT_JUMP_COVERAGE=300 for eukaryotes and plants!";fi
save ESTIMATED_GENOME_SIZE
echo "Estimated genome size: $ESTIMATED_GENOME_SIZE"

log Creating k-unitigs with k=$KMER
create_k_unitigs_large_k -c $(($KMER-1)) -t 10 -m $KMER -n $ESTIMATED_GENOME_SIZE -l $KMER -f 0.000001 pe.cor.fa  | grep --text -v '^>' | perl -ane '{$seq=$F[0]; $F[0]=~tr/ACTGactg/TGACtgac/;$revseq=reverse($F[0]); $h{($seq ge $revseq)?$seq:$revseq}=1;}END{$n=0;foreach $k(keys %h){print ">",$n++," length:",length($k),"\n$k\n"}}' > guillaumeKUnitigsAtLeast32bases_all.fasta
if [[ $KMER -eq $KMER_J ]];then
ln -s guillaumeKUnitigsAtLeast32bases_all.fasta guillaumeKUnitigsAtLeast32bases_all.jump.fasta
else
log Creating k-unitigs with k=$KMER_J
create_k_unitigs_large_k -c $(($KMER_J-1)) -t 10 -m $KMER_J -n $ESTIMATED_GENOME_SIZE -l $KMER_J -f 0.000001 pe.cor.fa  | grep --text -v '^>' | perl -ane '{$seq=$F[0]; $F[0]=~tr/ACTGactg/TGACtgac/;$revseq=reverse($F[0]); $h{($seq ge $revseq)?$seq:$revseq}=1;}END{$n=0;foreach $k(keys %h){print ">",$n++," length:",length($k),"\n$k\n"}}' > guillaumeKUnitigsAtLeast32bases_all.jump.fasta
fi


log 'Computing super reads from PE '
rm -rf work1
createSuperReadsForDirectory.perl -l $KMER -mean-and-stdev-by-prefix-file meanAndStdevByPrefix.pe.txt -kunitigsfile guillaumeKUnitigsAtLeast32bases_all.fasta -t 10 -mikedebug work1 pe.cor.fa 1> super1.err 2>&1
if [[ ! -e work1/superReads.success ]];then
fail Super reads failed, check super1.err and files in ./work1/
fi
extractreads.pl <( awk 'BEGIN{last_readnumber=-1;last_super_read=""}{readnumber=int(substr($1,3));if(readnumber%2>0){readnumber--}super_read=$2;if(readnumber==last_readnumber){if(super_read!=last_super_read){print read;print $1;}}else{read=$1;last_super_read=$2}last_readnumber=readnumber}' work1/readPlacementsInSuperReads.final.read.superRead.offset.ori.txt )  pe.cor.fa 1 > pe.linking.fa
NUM_LINKING_MATES=`wc -l pe.linking.fa | perl -ane '{print int($F[0]/2)}'`
MAX_LINKING_MATES=`perl -e '{$g=int('$ESTIMATED_GENOME_SIZE');$g=250000000 if($g>250000000);print $g}'`
grep --text -A 1 '^>se' pe.linking.fa | grep --text -v '^\-\-' | sample_mate_pairs.pl $MAX_LINKING_MATES $NUM_LINKING_MATES 1 > se.tmp
error_corrected2frg se 400 20 2000000000 se.tmp > se.linking.frg
rm se.tmp
echo -n 'Linking PE reads '; cat ??.linking.frg | grep -c --text '^{FRG' 
create_sr_frg.pl < work1/superReadSequences.fasta 2>/dev/null | fasta2frg.pl super >  superReadSequences_shr.frg


log 'Celera Assembler'
rm -rf CA
TOTAL_READS=`cat  *.frg | grep -c --text '^{FRG' `
save TOTAL_READS
ovlRefBlockSize=`perl -e '$s=int('$TOTAL_READS'/8); if($s>100000){print $s}else{print "100000"}'`
save ovlRefBlockSize
ovlHashBlockSize=`perl -e '$s=int('$TOTAL_READS'/80); if($s>10000){print $s}else{print "10000"}'`
save ovlHashBlockSize
ovlCorrBatchSize=$ovlHashBlockSize
save ovlCorrBatchSize
ovlMerThreshold=`jellyfish histo -t 10 k_u_hash_0 | awk '{thresh=75;if($1>1) {dist+=$2;if(dist>int("'$ESTIMATED_GENOME_SIZE'")*0.98&&flag==0){if($1>thresh) thresh=$1;flag=1}}}END{print thresh}'`
echo ovlMerThreshold=$ovlMerThreshold

runCA ovlMerThreshold=$ovlMerThreshold gkpFixInsertSizes=0 ovlMerSize=30 cgwErrorRate=0.25 ovlMemory=4GB jellyfishHashSize=$JF_SIZE ovlRefBlockSize=$ovlRefBlockSize ovlHashBlockSize=$ovlHashBlockSize ovlCorrBatchSize=$ovlCorrBatchSize stopAfter=consensusAfterUnitigger unitigger=bog -p genome -d CA merylThreads=10 frgCorrThreads=1 frgCorrConcurrency=10 cnsConcurrency=3 ovlCorrConcurrency=10 ovlConcurrency=10 ovlThreads=1 doFragmentCorrection=0 doOverlapBasedTrimming=0 doExtendClearRanges=0 ovlMerSize=30 superReadSequences_shr.frg   se.linking.frg    1> runCA1.out 2>&1

if [[ -e "CA/4-unitigger/unitigger.err" ]];then
  echo "Overlap/unitig success"
else
  fail Overlap/unitig failed, check output under CA/ and runCA1.out
fi

recompute_astat_superreads.sh genome CA $PE_AVG_READ_LENGTH work1/readPlacementsInSuperReads.final.read.superRead.offset.ori.txt

NUM_SUPER_READS=`cat superReadSequences_shr.frg  | grep -c --text '^{FRG' `
save NUM_SUPER_READS
( cd CA
  tigStore -g genome.gkpStore -t genome.tigStore 2 -d layout -U | tr -d '-' | awk 'BEGIN{print ">unique unitigs"}{if($1 == "cns"){seq=$2}else if($1 == "data.unitig_coverage_stat" && $2>=5){print seq"N"}}' | jellyfish count -L 2 -C -m 30 -s $ESTIMATED_GENOME_SIZE -t 10 -o unitig_mers /dev/fd/0
  cat <(overlapStore -b 1 -e $NUM_SUPER_READS -d genome.ovlStore  | awk '{if($1<'$NUM_SUPER_READS' && $2<'$NUM_SUPER_READS') print $0}'|filter_overlap_file -t 10 <(gatekeeper -dumpfastaseq genome.gkpStore ) unitig_mers /dev/fd/0) <(overlapStore -d genome.ovlStore | awk '{if($1>='$NUM_SUPER_READS' || $2>='$NUM_SUPER_READS') print $1" "$2" "$3" "$4" "$5" "$6" "$7}')  |convertOverlap -b -ovl > overlaps.ovb
  rm -rf 4-unitigger 5-consensus genome.tigStore genome.ovlStore
  overlapStore -c genome.ovlStore -M 4096 -t 10 -g genome.gkpStore overlaps.ovb 1>overlapstore.err 2>&1
)
runCA ovlMerThreshold=$ovlMerThreshold gkpFixInsertSizes=0 ovlMerSize=30 cgwErrorRate=0.25 ovlMemory=4GB jellyfishHashSize=$JF_SIZE ovlRefBlockSize=$ovlRefBlockSize ovlHashBlockSize=$ovlHashBlockSize ovlCorrBatchSize=$ovlCorrBatchSize stopAfter=consensusAfterUnitigger unitigger=bog -p genome -d CA merylThreads=10 frgCorrThreads=1 frgCorrConcurrency=10 cnsConcurrency=3 ovlCorrConcurrency=10 ovlConcurrency=10 ovlThreads=1 doFragmentCorrection=0 doOverlapBasedTrimming=0 doExtendClearRanges=0 ovlMerSize=30 superReadSequences_shr.frg   se.linking.frg    1> runCA2.out 2>&1

if [[ -e "CA/5-consensus/consensus.success" ]];then
  echo "Unitig consensus success"
else
  echo "Fixing unitig consensus..."
  mkdir CA/fix_unitig_consensus
  ( cd CA/fix_unitig_consensus
    cp `which fix_unitigs.sh` .
    ./fix_unitigs.sh genome 
  )
fi

recompute_astat_superreads.sh genome CA $PE_AVG_READ_LENGTH work1/readPlacementsInSuperReads.final.read.superRead.offset.ori.txt
runCA ovlMerSize=30 cgwErrorRate=0.25 ovlMemory=4GB unitigger=bog -p genome -d CA cnsConcurrency=3 computeInsertSize=0 doFragmentCorrection=0 doOverlapBasedTrimming=0 doExtendClearRanges=0 ovlMerSize=30 1>runCA3.out 2>&1
if [[ -e "CA/9-terminator/genome.qc" ]];then
  echo "CA success"
else
  fail CA failed, check output under CA/ and runCA3.out
fi
log 'Gap closing'
closeGapsLocally.perl --max-reads-in-memory 1000000000 -s 44000000 --Celera-terminator-directory CA/9-terminator --reads-file 'se.renamed.fastq' --output-directory CA/10-gapclose --min-kmer-len 17 --max-kmer-len $(($PE_AVG_READ_LENGTH-5)) --num-threads 10 --contig-length-for-joining $(($PE_AVG_READ_LENGTH-1)) --contig-length-for-fishing 200 --reduce-read-set-kmer-size 21 1>gapClose.err 2>&1
if [[ -e "CA/10-gapclose/genome.ctg.fasta" ]];then
  echo "Gap close success. Output sequence is in CA/10-gapclose/genome.{ctg,scf}.fasta"
else
  fail Gap close failed, you can still use pre-gap close files under CA/9-terminator/. Check gapClose.err for problems.
fi
log 'All done'
