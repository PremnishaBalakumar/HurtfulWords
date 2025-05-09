#!/bin/sh
#SBATCH --partition t4 
#SBATCH --gres gpu:2
#SBATCH -c 8
#SBATCH --output pregen_embs_%A.log
#SBATCH --mem 85gb

set -e
source activate hurtfulwords

BASE_DIR="/Users/aravind/Premnisha/MS/dlh/HurtfulWords/"
OUTPUT_DIR="/Users/aravind/Premnisha/MS/dlh/HurtfulWords/data"
cd "$BASE_DIR/scripts"
mkdir -p "$OUTPUT_DIR/pregen_embs/"
emb_method='cat4'

for target in inhosp_mort.pkl phenotype_all.pkl; do
	for model in baseline_clinical_BERT_1_epoch_128 baseline_clinical_BERT_1_epoch_512; do
	# for model in baseline_clinical_BERT_1_epoch_512; do
		python pregen_embeddings.py \
		    --df_path "$OUTPUT_DIR/finetuning/original/$target"\
		    --model "$OUTPUT_DIR/models/$model" \
		    --output_path "${OUTPUT_DIR}/pregen_embs/pregen_${model}_${emb_method}_${target}" \
		    --emb_method $emb_method
	done
done

