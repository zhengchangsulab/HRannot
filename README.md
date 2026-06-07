# HRannot
HRannot is an accurate and user-friendly gene annotation pipeline for vertebrates which could annotate both protein-coding genes and pseudogenes comprehensively based on both homology method and RNA-seq data.

## 1 Installation

git clone https://github.com/zhengchangsulab/HRannot.git \
cd HRannot/bin \
chmod 711 * \
PATH=$PATH:$PWD

## 2 Dependencies
### 2.1 Required tools:
•	Splign/2.0.0\
•	Python/3.6.8\
•	Bowtie2/2.4.1\
•	SAMtools/1.10\
•	BEDTools/2.29.0\
•	Trinity/2.13.0\
•	STAR/2.7.0c\
•	GFF3toolkit/2.1.0\
•	Infernal/1.1.2

### 2.2 Required raw data and database:
•	Reference CDS isoforms from homologous species.\
•	RNA-seq short reads from the individual or its homologous species.\
•	High-quality DNA sequencing reads (e.g illumina short reads or HiFi long reads) from the individual.\
•	rRNA database.\
•	Rfam database.

## 3 Run the pipeline
### Step 0: Get the reference CDS name from each species.

grep ">" species1.reference_CDS.fa > species1.reference_CDS.name \
grep ">" species2.reference_CDS.fa > species2.reference_CDS.name \
......

### Step 1: Use Splign to map the reference CDS isoforms of each species to the target assembly.
reference_cds=species1.reference_CDS.fa\
genome=my_genome.fa\
mkdir fasta_dir1\
cp $genome fasta_dir1\
cp $reference_cds fasta_dir1\
splign -mklds fasta_dir1\
cd fasta_dir1\
makeblastdb -dbtype nucl -parse_seqids -in species1.reference_CDS.fa\
makeblastdb -dbtype nucl -parse_seqids -in my_genome.fa\
compart -qdb species1.reference_CDS.fa -sdb my_genome.fa > cdna.compartments\
cd ..\
splign -ldsdir fasta_dir1 -comps ./fasta_dir1/cdna.compartments > species1.splign.output.ref \
\
reference_cds=species2.reference_CDS.fa\
genome=my_genome.fa\
mkdir fasta_dir2\
cp $genome fasta_dir2\
cp $reference_cds fasta_dir2\
splign -mklds fasta_dir2\
cd fasta_dir2\
makeblastdb -dbtype nucl -parse_seqids -in species2.reference_CDS.fa\
makeblastdb -dbtype nucl -parse_seqids -in my_genome.fa\
compart -qdb species2.reference_CDS.fa -sdb my_genome.fa > cdna.compartments\
cd ..\
splign -ldsdir fasta_dir2 -comps ./fasta_dir2/cdna.compartments > species2.splign.output.ref \
......

### Step 2: Use Bowtie2 to map the high-quality DNA sequencing reads to the target assembly allowing no mismatches and no gaps.

genome=my_genome.fa\
r1=Illumina paired-end-1.fastq\
r2=Illumina paired-end-2.fastq\
threads=48\
bowtie2-build $genome chicken\
bowtie2 -p $threads -x chicken -1 $r1 -2 $r2 --score-min L,0,0 | samtools view -Sb -@ $threads-1 | samtools sort -@ $threads-1 > out.bam\
bedtools genomecov -ibam out.bam -bga > out.bed

### Step 3: Use Infernal to predict non-coding RNAs against Rfam database.
Rfam_path=Path of Rfam database\
Genome=my_genome.fa\
esl-seqstat $Genome\
cmscan --cpu 48 --tblout result.tbl $Rfam_path/Rfam.cm $Genome > result_final.cmscan

### Step 4: Use Bowtie2 to map the RNA-seq reads to rRNA database to get the cleaned reads. Assemble the cleaned reads into transcripts using STAR and Trinity genome-guided method.
rrna=rrna_database.fa\
left=RNA-seq paired-end-1.fastq\
right=RNA-seq paired-end-2.fastq\
bowtie2-build $rrna rrna_data\
bowtie2 -p 48 --very-sensitive-local -x rrna_data -1 $left -2 $right --un-conc-gz paired_unaligned.fq.gz --un-gz unpaired_unaligned.fq.gz\
genome=my_genome.fa\
left=paired_unaligned.fq.1\
right=paired_unaligned.fq.2\
PREFIX=F025\
threads=16\
mkdir star\
STAR --runThreadN $threads --runMode genomeGenerate --genomeDir ./star --genomeFastaFiles $genome\
STAR --genomeDir ./star --runThreadN $threads --readFilesIn $left $right --outFileNamePrefix $PREFIX --outSAMtype BAM SortedByCoordinate --outBAMsortingThreadN $threads --limitBAMsortRAM 214748364800\
RNAbam=$PREFIX\Aligned.sortedByCoord.out.bam\
Trinity --output Trinity_GG --genome_guided_bam $RNAbam --genome_guided_max_intron 200000 --CPU $threads --max_memory 350G --verbose

### Step 5: Use Splign to map the transcripts obtained in step 4 to the target assembly.
genome=my_genome.fa\
rna=transcripts.fa\
mkdir fasta_dir\
cp $genome fasta_dir\
cp $rna fasta_dir\
splign -mklds fasta_dir\
cd fasta_dir\
makeblastdb -dbtype nucl -parse_seqids -in transcripts.fa\
makeblastdb -dbtype nucl -parse_seqids -in my_genome.fa\
compart -qdb transcripts.fa -sdb my_genome.fa > rna.compartments\
cd ..\
splign -ldsdir fasta_dir -comps ./fasta_dir/rna.compartments -type est > splign.output.rna

### Step 6: Run the HRannot scripts. Users can define the parameters by themselves.
./HRannot.py -h \
&emsp;&emsp;usage: HRannot.py -g  -c  -sh  -p  -sr  -ns  -nc  [-l] [-s] \
\
optional arguments: \
&emsp;&emsp;-h &emsp;&emsp;--help &emsp;&emsp;show this help message and exit \
&emsp;&emsp;-g &emsp;&emsp;--genome &emsp;&emsp;Required \
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Target assembled genome \
	-c , --CDS           Required \
                         Homology CDS isoforms and their corresponding genes’ name \
    -sh , --splignh      Required \
                         Splign output from homology CDS \
    -p , --prefix        Required \
                         Prefix of the corresponding Splign output \
    -sr , --splignR      Required \
                         Splign output from RNA-seq data \
    -ns , --nonsupport   Required \
                         Bed file of the genome region not supported by the high-quality sequencing reads \
    -nc , --noncoding    Required \
                         Non-coding RNAs in the genome \
    -l , --minORFlen     Default=300 \
                         Minimum length of the open reading frames identified by RNA-seq data \
    -s , --minRNAsco     Default=0.985 \
                         Minimum score of Splign output from RNA-seq data \\

An example to run HRannot: \
HRannot.py -g genome.fa \\\
    -m species1.splign.output.ref,species2.splign.output.ref \\\
	-c species1.reference_CDS.name,species2.reference_CDS.name \\\
	-p species1,species2 \\\
	-r splign.output.rna \\\
	-b out.bed \\\
	-f 10 \\\
	-n result_final.cmscan \\\
	-l 300 \\\
	-s 0.985 \\\
	-o 0.95 \\\
	-i 0.99 \\
	
chmod 711 HRannot.sh \
./HRannot.sh

### Important Notes:
• Step 1, Step 2, Step 3 and Step 4 can be executed simultaneously if there are enough memory on your cluster.

## 4 Outputs
•	final.right.truegene.gff3: annotation for protein coding genes.\
•	final.right.pseudogene.gff3: annotation for pseudogenes.
