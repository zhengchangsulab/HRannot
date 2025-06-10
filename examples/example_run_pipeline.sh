HRannot.py -g genome.fa \
	-c CDS.txt \
	-sh splign.output.ref \
	-sr splign.output.rna \
	-ns notsupport.region \
	-nc non-coding-RNA.txt \
	-l 300 \
	-s 0.985
chmod 711 HRannot.sh
./HRannot.sh

