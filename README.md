# Hurtful Words: Quantifying Biases in Clinical Contextual Word Embeddings

## Paper
If you use this code in your research, please cite the following [publication](https://dl.acm.org/doi/abs/10.1145/3368555.3384448):

```
Haoran Zhang, Amy X. Lu, Mohamed Abdalla, Matthew McDermott, and Marzyeh Ghassemi. 2020.
Hurtful words: quantifying biases in clinical contextual word embeddings.
In Proceedings of the ACM Conference on Health, Inference, and Learning (CHIL ’20).
Association for Computing Machinery, New York, NY, USA, 110–120.
```

A publically available version of this paper is also on [arXiv](https://arxiv.org/abs/2003.11515).

## Pretrained Models
The pretrained BERT models used in our experiments are available to download here:
- [Baseline_Clinical_BERT](https://www.cs.toronto.edu/pub/haoran/hurtfulwords/baseline_clinical_BERT_1_epoch_512.tar.gz)
- [Adversarially_Debiased_Clinical_BERT](https://www.cs.toronto.edu/pub/haoran/hurtfulwords/adv_clinical_BERT_1_epoch_512.tar.gz) (Gender)


## Step 0: Environment and Prerequisites
- Before starting, go to the [MIMIC-benchmarks repository](https://github.com/YerevaNN/mimic3-benchmarks), and follow all of the steps in the `Building a benchmark` section.
- Run the following commands to clone this repo and create the Conda environment
```
git clone https://github.com/MLforHealth/HurtfulWords.git
cd HurtfulWords/
conda create -y -n hurtfulwords python=3.7
conda activate hurtfulwords
pip install -r requirements.txt
```

## Step 1a: Create sample dataset from MIMIC3 dataset
- To gain access to MIMIC-III dataset, please register https://physionet.org, complete required CITI training and follow instructions to gain access. Once access is granted data can be downloaded as ZIP file or using your terminal with following command
- ```
  wget -r -N -c -np --user adafe2 --ask-password https://physionet.org/files/mimiciii/1.4/
  ```
- Steps to generate sample dataset using complete dataset :
```
python scripts/create_sample_data.py \
 --input_dir /home/adafe/mimic-iii-clinical-database-1.4/mimic-iii-clinical-database-1.4 \
 --output_dir /home/adafe/mimic-iii-clinical-database-1.4/mimic-iii-clinical-database-1.4/selected \
 --patient_file PATIENTS.csv \
 --num_of_patients 3500 \
 --id_column SUBJECT_ID
```
where
- input_dir - location of full dataset
- output_dir - direcoty where corresponsing files for fixed number of patients will be created
- patient_file - name of main patient file, default - PATIENTS.csv
- num_of_patients - number of patients to be included in sample dataset, default 3500
- id_column - column corresponding to patient id, default - SUBJECT_ID

 

## Step 1b: Data processing
Reads in the tables from MIMIC and pregenerates data for clinical BERT pretraining. Reads in the cohorts defined by MIMIC-benchmarks and creates tasks for finetuning on downstream targets.
- In `bash_scripts/data_processing_pipeline.sh`, update `BASE_DIR`, `OUTPUT_DIR`, `SCIBERT_DIR` and `MIMIC_BENCHMARK_DIR`.
- In `scripts/get_data.py`, update data_dir with directory where sampled data is created from step 1a and output_folder where the pickle file needs to be stored.
- Run `bash_scripts/data_processing_pipeline.sh`. This creates the test and train set for inhosp_mort, phenotype_all and phenotype_first.

## Step 2: Training Baseline Clinical BERT
Pretrains baseline clinical BERT (initialized from SciBERT) for 1 epoch on sequences of length 128, then 1 epoch on sequences of length 512.
- In `bash_scripts/train_baseline_clinical_BERT.sh`, update `BASE_DIR`, `OUTPUT_DIR`, and `SCIBERT_DIR`. These variables should have the same values as in step 1.
- Run `bash_scripts/train_baseline_clinical_BERT.sh` on a GPU cluster. The resultant model will be saved in `${OUTPUT_DIR}/models/baseline_clinical_BERT_1_epoch_512/`.
** Due to resource limitations training the model using CPU took a long time about 24 hours for one epoch. 

## Step 3: Training Adversarial Clinical BERT
Pretrains clinical BERT (initialized from SciBERT) with adversarial debiasing using gender as the protected attribute, for 1 epoch on sequences of length 128, then 1 epoch on sequences of length 512. 
- In `bash_scripts/train_adv_clinical_bert.sh`, update `BASE_DIR`, `OUTPUT_DIR`, and `SCIBERT_DIR`. These variables should have the same values as in step 1.
- Run `bash_scripts/train_adv_clinical_bert.sh gender` on a GPU cluster. The resultant model will be saved in `${OUTPUT_DIR}/models/adv_clinical_BERT_gender_1_epoch_512/`.
** Due to resource limitations training the model using CPU took a long time about 24 hours for one epoch. 

## Step 4: Finetuning on Downstream Tasks
Generates static BERT representations for the downstream tasks created in Step 1. Trains various neural networks (grid searching over hyperparameters) on these tasks.
- In `bash_scripts/pregen_embs.sh`, update `BASE_DIR` and `OUTPUT_DIR`. Run this script on a GPU cluster. 
- In `bash_scripts/finetune_on_target.sh`, update `BASE_DIR` and `OUTPUT_DIR`. This script will output a trained model for a particular (target, model) combination, in the `${OUTPUT_DIR}/models/finetuned/` folder. The Python script `bash_scripts/run_clinical_targets.py` will queue up the 114 total (target, model) experiments conducted, as Slurm jobs. This script will have to be modified accordingly for other systems.

## Step 5: Analyze Downstream Task Results
Evalutes test-set predictions of the trained models, by generating various fairness metrics.
- Download pretrained model suggested above.
- In `bash_scripts/analyze_results.sh`, update `MODEL_ROOT_DIR`, `INHOSP_MORT_PATH`, `PHENOTYPE_ALL_PATH`, `PHENOTYPE_FIRST_PATH` and `output_path`. Run this script, which will output a .csv file containing fairness metrics for each model.

## Step 6: Compute fairness metrics for subgroups
- Download pretrained model suggested above.
- Execute `/scripts/fairness_eval.py` update `PHENOTYPE_ALL_PATH`, `BASELINE_MODEL_DIR` and `ADV_MODEL_DIR`. Also update `output_path_comp` and `output_path`. If you would like to run this for inhosp_mort / phenotype_first do necessary changes. 
- Run the python file, which will output csv for various sub-groups in `attribute_list`.

## Step 7: Log Probabiltiy Bias Scores
Following procedures in [Kurita et al.](http://arxiv.org/abs/1906.07337), we calculate the 'log probability bias score' to evaluate biases in the BERT model. Template sentences should be in the example format provided by `fill_in_blanks_examples/templates.txt`. A CSV file denoting context key words and the context category should alshould also be suppled (see `fill_in_blanks_examples/attributes.csv`). 

This step can be done independently of steps 4 and 5.
- In `bash_scripts/log_probability.sh`, update `BASE_DIR`, `OUTPUT_DIR`, and `MODEL_NAME`. Run this script.
- The statistical significance results can be found in `${OUTPUT_DIR}/${MODEL_NAME}_log_scores.tsv`.
- The notebook `notebooks/GetBasePrevs.ipynb` computes the base prevalences for categories in the notes.

## Step 8: Sentence Completion
`scripts/predict_missing.py` takes template sentences which contain `_` for tokens to be predicted. Template sentences can be specified directly in the script.

This step can be done independently of steps 1-6.
- In `scripts/predict_missing.py`, update `SCIBERT_DIR`. Run this script in the Conda environment. The results will be printed to the screen.
