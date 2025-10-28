HRannot.py -g genome.fa \
	-m Fulmarus_glacialis.splign.output.ref,Parus_major.splign.output.ref \
	-c Fulmarus_glacialis.reference_CDS.name,Parus_major.reference_CDS.name \
	-p Fulmarus_glacialis,Parus_major \
	-r splign.output.rna \
	-b out.bed \
	-f 10 \
	-n result_final.cmscan \
	-l 300 \
	-s 0.985 \
	-o 0.95 \
	-i 0.99

chmod 711 HRannot.sh
./HRannot.sh

