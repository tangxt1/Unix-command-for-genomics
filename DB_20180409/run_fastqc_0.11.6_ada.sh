#BSUB -L /bin/bash              # uses the bash login shell to initialize the job's execution environment.
#BSUB -J fastqc                 # job name
#BSUB -n 2                      # assigns 2 cores for execution
#BSUB -R "span[ptile=2]"        # assigns 2 cores per node
#BSUB -R "rusage[mem=2500]"     # reserves 2500MB memory per core
#BSUB -M 2500                   # sets to 2500MB process enforceable memory limit. (M * n)
#BSUB -W 1:00                   # sets to 1 hour the job's runtime wall-clock limit.
#BSUB -o /scratch/user/tangxt/DB1813/DB_20180409.data stdout.%J              # directs the job's standard output to stdout.jobid
#BSUB -e /scratch/user/tangxt/DB1813/DB_20180409.data stderr.%J              # directs the job's standard error to stderr.jobid

module load FastQC/0.11.6-Java-1.8.0

<<README
    - FASTQC homepage: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
    - FASTQC manual: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/
README

################################################################################
# TODO Edit these variables as needed:
threads=2                       # make sure this is <= your BSUB -n value

pe1_1='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_R1.fastq.gz'
pe1_2='/scratch/datasets/GCATemplates/data/miseq/c_dubliniensis/DR34_R2.fastq.gz'

################################################################################
# use -o <directory> to save results to <directory> instead of directory where reads are located
#   <directory> must already exist before using -o <directory> option
# --nogroup will calculate average at each base instead of bins after the first 50 bp
# fastqc runs one thread per file; using 20 threads for 2 files does not speed up the processing
fastqc -t $threads -o /scratch/user/tangxt/DB1813/DB_20180409.data $pe1_1 $pe1_2

<<CITATION
    - Acknowledge TAMU HPRC: https://hprc.tamu.edu/research/citations.html

    - FastQC: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
CITATION
