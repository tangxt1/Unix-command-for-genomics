#BSUB -L /bin/bash              # uses the bash login shell to initialize the job's execution environment.
#BSUB -J hisat2                 # job name
#BSUB -n 20                     # assigns 20 cores for execution
#BSUB -R "span[ptile=20]"       # assigns 20 cores per node
#BSUB -R "rusage[mem=2700]"     # reserves 2700MB memory per core
#BSUB -M 2700                   # sets to 2,700MB (~2.7GB) per process enforceable memory limit. Total job memory = (M * n)
#BSUB -W 24:00                  # sets to 24 hours the job's runtime wall-clock limit.
#BSUB -o /scratch/user/tangxt/DBiology/DB1813_FinalProject.data/brach.stdout.%J              # directs the job's standard output to stdout.jobid
#BSUB -e /scratch/user/tangxt/DBiology/DB1813_FinalProject.data/brach.stderr.%J              # directs the job's standard error to stderr.jobid

module load HISAT2/2.1.0-intel-2017A-Python-2.7.12
module load SAMtools/1.6-GCCcore-6.3.0

<<README
    - HISAT2 manual: http://ccb.jhu.edu/software/hisat2/manual.shtml
README

# This template script aligns paired end reads and sorts the output into a bam file

################################################################################
# TODO Edit these variables as needed:
threads=20                      # make sure this is <= your BSUB -n value

pe_1='/scratch/user/tangxt/DBiology/DB1813_FinalProject.data/Canis-lupus-familiaris.FinalProject.data/slow/brach.R1.fastq'
pe_2='/scratch/user/tangxt/DBiology/DB1813_FinalProject.data/Canis-lupus-familiaris.FinalProject.data/slow/brach.R2.fastq'

# you can use an already prefixed genome found at: /scratch/datasets/ucsc/genome_indexes/
genome_index_prefix='/scratch/group/digibio/Canis-lupus-familiaris/HISAT2_Index/Canis_familiaris.CanFam3.1.dna.toplevel.fa.SpliceSitesExonNames'

# read group information
id='Clfamiliaris'
library='sra'
platform='ILLUMINA'
sample='brach'

output_bam="/scratch/user/tangxt/DBiology/DB1813_FinalProject.data/${sample}_pe_aln.bam"
################################################################################
# If you will be using cufflinks downstream, run hisat2 with the --dta-cufflinks option instead of --dta
hisat2 --dta --tmo -p $threads --rg-id "$id" --rg "LB:$library" --rg "SM:$sample" --rg "PL:$platform" -x $genome_index_prefix -q -1 $pe_1 -2 $pe_2 -S out.sam

samtools view -bS out.sam | samtools sort -m 2G -@ $threads - -T $sample -o $output_bam

rm out.sam

<<CITATION
    - Acknowledge TAMU HPRC: https://hprc.tamu.edu/research/citations.html

    - HISAT2:
        Kim D, Langmead B and Salzberg SL. HISAT: a fast spliced aligner with low memory requirements.
        Nature Methods 12, 357–360 (2015). doi:10.1038/nmeth.3317

CITATION
