# HRannot
HRannot is an accurate and user-friendly gene annotation pipeline for vertebrates which could annotate both protein-coding genes and pseudogenes comprehensively based on both homology method and RNA-seq data.

## 1 Installation

git clone https://github.com/zhengchangsulab/HRannot.git \
cd HRannot/bin \
PATH=$PATH:$PWD
chmod 711 *

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
•	Reference CDS isoforms from homologous species\
•	RNA-seq short reads from the individual or its homologous species\
•	High-quality sequencing reads (e.g illumina short reads or HiFi long reads) from the individual\
•	rRNA database\
•	Rfam database

## 3 Run the pipeline
### Step 1: Use Splign to map the reference CDS isoforms to the target assembly.
reference_cds=reference_CDS.fa\
genome=my_genome.fa\
mkdir fasta_dir\
cp $genome fasta_dir\
cp $reference_cds fasta_dir\
splign -mklds fasta_dir\
cd fasta_dir\
makeblastdb -dbtype nucl -parse_seqids -in reference_CDS.fa\
makeblastdb -dbtype nucl -parse_seqids -in my_genome.fa\
compart -qdb reference_CDS.fa -sdb my_genome.fa > cdna.compartments\
cd ..\
splign -ldsdir fasta_dir -comps ./fasta_dir/cdna.compartments > splign.output.ref

### Step 2: Use Bowtie2 to map the high-quality sequencing reads to the target assembly allowing no-mismatch.
genome=my_genome.fa\
r1=Illumina paired-end-1.fastq\
r2=Illumina paired-end-2.fastq\
threads=48\
bowtie2-build $genome chicken\
bowtie2 -p $threads -x chicken -1 $r1 -2 $r2 --score-min L,0,0 | samtools view -Sb -@ $threads-1 | samtools sort -@ $threads-1 > out.bam\
bedtools genomecov -ibam out.bam -bga > out.bed\
awk '$4<10{print $0}' out.bed > notsupport.region \
(Here we consider regions supported by less than 10 reads as not supported regions.)

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

### Step 6: Run the HRannot scripts.
HRannot.py -g genome.fa \\\
	-c CDS.txt \\\
	-sh splign.output.ref \\\
	-sr splign.output.rna \\\
	-ns notsupport.region \\\
	-nc non-coding-RNA.txt \\\
	-l 300 \\\
	-s 0.985 \
chmod 711 HRannot.sh \
./HRannot.sh

### Important Notes:
• CDS.txt in Step 6 is the name of each reference CDSs isoforms. Examples are shown in examples/CDS.txt. \
• Step 1, Step 2, Step 3 and Step 4 can be executed simultaneously if there are enough memory on your cluster.

## 4 Outputs
•	final.right.truegene.gff3: annotation for protein coding genes.\
•	final.right.pseudogene.gff3: annotation for pseudogenes.
