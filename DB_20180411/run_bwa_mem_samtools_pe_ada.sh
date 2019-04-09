#BSUB -L /bin/bash              # uses the bash login shell for job environment
#BSUB -J bwa_pe                 # job name
#BSUB -n 20                     # assigns 20 cores for execution
#BSUB -R "span[ptile=20]"       # assigns 20 cores per node
#BSUB -R "rusage[mem=2500]"     # reserves 2500MB memory per core
#BSUB -M 2500                   # sets to 2500MB per process enforceable memory limit.
#BSUB -W 8:00                   # sets to 8 hour the job's runtime wall-clock limit.
#BSUB -o /scratch/user/tangxt/DBiology/DB1813_20180411.data/stdout.%J              # directs the job's standard output to stdout.jobid
#BSUB -e /scratch/user/tangxt/DBiology/DB1813_20180411.data/stderr.%J              # directs the job's standard error to stderr.jobid

module load BWA/0.7.17-GCCcore-6.3.0
module load SAMtools/1.7-GCCcore-6.3.0

<<README
    - BWA manual: http://bio-bwa.sourceforge.net/bwa.shtml
    - SAMtools manual: http://samtools.github.io/hts-specs/SAMv1.pdf
README

################################################################################
# TODO Edit these variables as needed:
threads=20                       # make sure this is <= your BSUB -n value

pe1_1="/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_R1.fastq.gz"
pe1_2="/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_R2.fastq.gz"

read_group_id='DR'
library='pe'
sample='DR34'
platform='ILLUMINA'

# look for already indexed genome here /scratch/datasets/genome_indexes/ucsc/
ref_genome="/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/C_dubliniensis_CD36.fasta"

output_bam="/scratch/user/tangxt/DBiology/DB1813_20180411.data/${sample}.bam"

################################################################################
# create genome bwa index only if it hasn't been created yet
if [ ! -f ${ref_genome}.bwt ]; then
  bwa index $ref_genome
fi

# piping bwa mem results into samtools for sorting works best for small genomes; for large genomes you may need to run multiple steps
bwa mem -M -t $threads -R "@RG\tID:$readgroup\tLB:$library\tSM:$sample\tPL:$platform" $ref_genome $pe1_1 $pe1_2 | samtools view -h -Sb - | samtools sort -m 2G --threads $threads - -T $TMPDIR/sorted -o $output_bam


<<CITATION
    - Acknowledge TAMU HPRC: https://hprc.tamu.edu/research/citations.html

    - BWA:
        Li H. and Durbin R. (2009) Fast and accurate short read alignment with Burrows-Wheeler transform. Bioinformatics, 25, 1754-1760.

    - SAMtools:
        Li H.*, Handsaker B.*, Wysoker A., Fennell T., Ruan J., Homer N., Marth G., Abecasis G., Durbin R. and 1000 Genome Project
        Data Processing Subgroup (2009) The Sequence alignment/map (SAM) format and SAMtools. Bioinformatics, 25, 2078-9.
CITATION
