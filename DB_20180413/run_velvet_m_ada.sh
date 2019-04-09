#BSUB -L /bin/bash              # uses the bash login shell to initialize the job's execution environment.
#BSUB -J velvet_se              # job name
#BSUB -n 10                     # assigns 10 cores for execution
#BSUB -R "span[ptile=10]"       # assigns 10 cores per node
#BSUB -R "rusage[mem=1000]"     # reserves 1000MB memory per core
#BSUB -M 1000                   # sets to 1000MB (~1GB) the per process enforceable memory limit.
#BSUB -W 6:00                   # sets to 6 hours the job's runtime wall-clock limit.
#BSUB -o /scratch/user/tangxt/DBiology/test0413.data/stdout.%J              # directs the job's standard output to stdout.jobid
#BSUB -e /scratch/user/tangxt/DBiology/test0413.data/stderr.%J              # directs the job's standard error to stderr.jobid

module load Velvet/1.2.10-ictce-7.1.2

for i in {19..53..2};do velveth \
                            /scratch/user/tangxt/DBiology/test0413.data/out_"$i" \
                            $i \
                            -fastq \
                            -short \
                            /scratch/user/tangxt/DBiology/test0413.data/Phage_Pool_TruSeq_12_CTTGTA_R1.fastq;

                        velvetg \
                            /scratch/user/tangxt/DBiology/test0413.data/out_"$i";
done