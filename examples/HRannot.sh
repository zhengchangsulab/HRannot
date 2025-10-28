echo "### Start analyzing the results of splign for ref_based"
ref.get_best1.py Fulmarus_glacialis.reference_CDS.name Fulmarus_glacialis.splign.output.ref Fulmarus_glacialis
sort -k2,2 -k5,5 -k3,3n -k4,4n best1_Fulmarus_glacialis > sorted_best1_Fulmarus_glacialis
ref.get_best1.py Parus_major.reference_CDS.name Parus_major.splign.output.ref Parus_major
sort -k2,2 -k5,5 -k3,3n -k4,4n best1_Parus_major > sorted_best1_Parus_major
ref.compare.py Fulmarus_glacialis,Parus_major 0.95 0.99  > best1
sort -k2,2 -k5,5 -k3,3n -k4,4n best1 > sorted_best1
ref.get_best2.py > best2.gff3
ref.get_cds.py best2.gff3 genome.fa > cds.fa
ref.find_ORF.py
awk '$3=="gene"{print $9}' best2_pseudogene.gff3 > best2_pseudogene
cat extend_log.txt | grep -f best2_pseudogene > best2_pseudogene_log
grep -v "notextend" best2_pseudogene_log > best2_pseudogene_need_extend
echo "### Finish analyzing the results of splign for ref_based"

echo "### Start analyzing the results of splign for RNA_based"
rna.get_best1.py splign.output.rna
sort -k2,2 -k5,5 -k3,3n -k4,4n best1 > sorted.best1
rna.get_pass.py 0.985 > best1.pass.sort
rna.get_best2.py > rna_based.gff3
echo "### Finish analyzing the results of splign for RNA_based"

echo "### Start getting the ref_based gff3"
ref.get_best3.py
ref.check_extended1.py genome.fa > test
ref.get_cds.py test genome.fa > test.fa
ref.check_extended2.py > extended_pseudogene.gff3
ref.get_cds.py extended_pseudogene.gff3 genome.fa > extended_pseudogene_cds.fa
ref.find_ORF1.py
cat best2_truegene.gff3 extended_truegene.gff3 > final_truegene.gff3
cat pseudogene_part1.gff3 pseudogene_part2.gff3 > final_pseudogene.gff3
awk '$4<10{print $0}' out.bed > notsupport.region
ref.merge_bed.py notsupport.region > new.notsupport.region
ref.check_pseudogene.py new.notsupport.region > shortreads_notsupport.pseudogene
ref.get_best4.py > ref_based1.gff3
ref.get_best5.py
echo "### Finish getting the ref_based gff3"

echo "### Start getting the rna_based_uniq gff3"
rna.merge_ref_rna.py > rna_uniq.gff3
rna.check_non_coding.py result_final.cmscan > rna_uniq1.gff3
rna.get_cds.py rna_uniq1.gff3 genome.fa > rna_uniq_cds.fa
rna.verify_gene.py 300  > rna_uniq_good_orf.fa
grep ">" rna_uniq_good_orf.fa | sed 's/.//' > total.support
rna.support.get_best2.py > rna_support.gff3
rna.support.match_cds.py > rna_support1.gff3
rna.support.get_best3.py > rna_support2.gff3
rna.support.get_best4.py > rna_support3.gff3
echo "### Finish getting the rna_based_uniq gff3"

echo "### Start getting final protein coding genes and pseudogenes"
cat ref_true_gene.gff3 rna_support3.gff3 > tobe_check.gff3
final.check.py tobe_check.gff3 > final.right.truegene.gff3
final.check.py ref_pseudogene.gff3 > final.right.pseudogene.gff3
echo "### Finish getting the protein coding genes and pseudogenes"

echo "### Remove unnecessary files"
rm *best* pseudogene_* ref_* new_old.name extend_* extended_* cds.fa rna_* test* final_* short* total.support tobe_check.gff3 *.region
echo "### Finish removing unnecessary files"
echo "Finished!"
