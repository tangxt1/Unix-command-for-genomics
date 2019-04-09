#BSUB -L /bin/bash              # uses the bash login shell to initialize the job's execution environment.
#BSUB -J spades_pe_2mp          # job name
#BSUB -n 20                     # assigns 20 cores for execution
#BSUB -R "span[ptile=20]"       # assigns 20 cores per node
#BSUB -R "rusage[mem=2700]"     # reserves 2700MB memory per core
#BSUB -M 2700                   # sets to 2700MB (~2.7GB) the per process enforceable memory limit.
#BSUB -W 24:00                  # sets to 24 hours the job's runtime wall-clock limit.
#BSUB -o stdout.%J              # directs the job's standard output to stdout.jobid
#BSUB -e stderr.%J              # directs the job's standard error to stderr.jobid

module load SPAdes/3.11.1-GCCcore-6.3.0

<<README
    - SPAdes manual: http://spades.bioinf.spbau.ru/release3.5.0/manual.html
README

################################################################################
# TODO Edit these variables as needed:
threads=20       # make sure this is <= your BSUB -n value
max_memory=52    # max memory used in Gb, make sure this is less than the BSUB total job memory

output_dir='build_DR34_pe_mp2kb_mp10kb'

# sample dataset estimated run time: ~10 hours; max memory ~40Gb; ~200 SUs
pe1_1='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_R1.fastq.gz'
pe1_2='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_R2.fastq.gz'

mp1_1='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_mp2kb_R1.fastq'
mp1_2='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_mp2kb_R2.fastq'

mp2_1='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_mp10kb_R1.fastq'
mp2_2='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_mp10kb_R2.fastq'

################################################################################
# command to run with defaults and the --cafeful option
spades.py --threads $threads --tmp-dir $TMPDIR --careful --memory $max_memory -o $output_dir \
 --pe1-1 $pe1_1 --pe1-2 $pe1_2 --mp1-1 $mp1_1 --mp1-2 $mp1_2 --mp2-1 $mp2_1 --mp2-2 $mp2_2


<<CITATION
    - Acknowledge TAMU HPRC: https://hprc.tamu.edu/research/citations.html

    - SPAdes:
        Bankevich A., et al. SPAdes: A New Genome Assembly Algorithm and Its Applications to Single-Cell Sequencing.
        J Comput Biol. 2012 May; 19(5): 455–477. doi:  10.1089/cmb.2012.0021
CITATION
