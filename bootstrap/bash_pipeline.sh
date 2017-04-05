gotree generate yuletree -l 500 -n 200 > true_500.nw
gotree generate yuletree -l 200 -n 200 > true_200.nw
gotree generate yuletree -l 100 -n 200 > true_100.nw

mkdir true_500 true_200 true_100

gotree divide -i true_500.nw -o true_500/true_500
gotree divide -i true_200.nw -o true_200/true_200
gotree divide -i true_100.nw -o true_100/true_100

for t in `ls true_500/true_500_*.nw`
do
    seq-gen -q -op -a0.5 -g4 -mGTR -l1000 -r 3 5 7 4 6 2 -f 0.25 0.15 0.2 0.4 -z ${RANDOM} ${t} -n 1 > ${t}.ph
done

for t in `ls true_200/true_200_*.nw`
do
    seq-gen -q -op -a0.5 -g4 -mGTR -l1000 -r 3 5 7 4 6 2 -f 0.25 0.15 0.2 0.4 -z ${RANDOM} ${t} -n 1 > ${t}.ph
done

for t in `ls true_100/true_100_*.nw`
do
    seq-gen -q -op -a0.5 -g4 -mGTR -l500 -r 3 5 7 4 6 2 -f 0.25 0.15 0.2 0.4 -z ${RANDOM} ${t} -n 1 > ${t}.ph
done

for n in {100,200,500}
do
    for a in `ls true_${n}/true_${n}_*.ph`
    do
	# Rapid bootstrap with RAxML
	raxmlHPC-PTHREADS -f a -m GTRGAMMA -c 4 -s ${a} -n $(basename ${a}) -T 10 -p $RANDOM -x $RANDOM -# 100
	mv RAxML_bestTree*$(basename ${a}) true_${n}/$(basename $a)_raxml_best.nw
	mv RAxML_bootstrap*$(basename ${a}) true_${n}/$(basename $a)_raxml_rbs_trees.nw
	rm -f RAxML_*$(basename ${a})
	gotree compute support classical -i true_${n}/$(basename $a)_raxml_best.nw -b  true_${n}/$(basename $a)_raxml_rbs_trees.nw -o true_${n}/$(basename $a)_raxml_rbs_supports.nw -t 10
	
	# aLRT with phyml
	phyml  -b -4 -i ${a} -m GTR -a e -f e -t e -o tlr
	mv ${a}_phyml_tree.txt true_${n}/$(basename $a)_alrt.nw
	rm -f ${a}_phyml*
	
	# SBS with RAxML
	raxmlHPC-PTHREADS -m GTRGAMMA -c 4 -s ${a} -n $(basename ${a}) -T 10 -p $RANDOM -b $RANDOM -# 100
	mv RAxML_bootstrap.$(basename ${a}) true_${n}/$(basename $a)_raxml_sbs_trees.nw
	rm -f RAxML_*$(basename ${a})
	gotree compute support classical -i true_${n}/$(basename $a)_raxml_best.nw -b true_${n}/$(basename $a)_raxml_sbs.nw -o true_${n}/$(basename $a)_raxml_sbs_supports.nw -t 10
	
	# UltraFast Bootstrap with iqtree
	iqtree-omp -s ${a} -m GTR+G -bb 1000 -nt AUTO > true_${n}/$(basename $a)_iqtree.nw
	mv ${a}.treefile true_${n}/$(basename $a)_iqtree.nw
	rm -f ${a}.*
    done
done

for n in {100,200,500}
do
    for a in `ls true_${n}/true_${n}_*.ph`
	     truetree="${a%.*}"
	     gotree compare edges -i ${a}_raxml_rbs_supports.nw -c $truetree | awk 'BEGIN{FS="\t"}{if ($7>1){print $4 " " $9}}' > comp_rbs.txt
	     gotree compare edges -i ${a}_raxml_sbs_supports.nw -c $truetree | awk 'BEGIN{FS="\t"}{if ($7>1){print $4 " " $9}}' > comp_sbs.txt
	     gotree compare edges -i ${a}_alrt.nw -c $truetree | awk 'BEGIN{FS="\t"}{if ($7>1){print $4 " " $9}}' > comp_alrt.txt
	     gotree compare edges -i ${a}_raxml_iqtree.nw -c $truetree | awk 'BEGIN{FS="\t"}{if ($7>1){print $4 " " $9}}' > comp_iqtree.txt
	     paste comp_rbs.txt comp_sbs.txt comp_alrt.txt comp_iqtree.txt | awk '{print $1 $3 $5 $7 $8}' >> comp.txt
    do
done
