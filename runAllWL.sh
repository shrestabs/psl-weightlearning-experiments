# Run weight Learning experiments on all examples in the repository
#!/bin/bash
set -e
readonly BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly OTHER_EXAMPLES_DIR="other-examples"
readonly PSL_EXAMPLES_DIR="psl-examples"
readonly OUTDIR="out"
readonly INFERRED_PREDICATES_PATH="./inferred-predicates/*"
# if out directory not found run WL, else skip.

#TODO: measure time taken for experiments
declare -a WL_METHODS=("bayesian.GaussianProcessPrior" "maxlikelihood.MaxLikelihoodMPE" "maxlikelihood.MaxPiecewisePseudoLikelihood" "search.Hyperband" "search.InitialWeightHyperband" "search.grid.ContinuousRandomGridSearch" "search.grid.GuidedRandomGridSearch" "search.grid.RandomGridSearch")
BASE_WEIGHT_NAME='org.linqs.psl.application.learning.weight.'

echo "Beginning Weight Learning experiments. Begin fresh experiments? (Press: y) \n(Delete all output directory and files). Default: Continue from cached output"
read setclear
if [[ $setclear = "y" ]] ; then
    find . -type d -name "out" -exec rm -rf {} +
fi

for dataset_dir in ./$OTHER_EXAMPLES_DIR/*; do # for all datasets i.e examples
    dataset=$(echo $dataset_dir | cut -d/ -f3)
    echo "dataset dir" $dataset_dir "dataset" $dataset
    for split in {0..4}; do # for all splits
        # create eval.data file from template 
        if [[ ! -e "$dataset_dir/psl-cli/${dataset}-eval.data" ]]; then
            sed "s/__fold__/$split/g" "$dataset_dir/psl-cli/${dataset}-template-eval.data" > "$dataset_dir/psl-cli/${dataset}-eval.data"
        fi
        # create learn.data file from template
        if [[ ! -e "$dataset_dir/psl-cli/${dataset}-learn.data" ]]; then
            sed "s/__fold__/$split/g" "$dataset_dir/psl-cli/${dataset}-template-learn.data" > "$dataset_dir/psl-cli/${dataset}-learn.data"
        fi
        # make logs dir
        mkdir -p "${OTHER_EXAMPLES_DIR}/${dataset}/$OUTDIR"
        pushd . > /dev/null
        cd "$dataset_dir/psl-cli/"

        #run uniform on eval
        if [[ -e "../$OUTDIR/${dataset}-${split}-uniform-out.txt" ]]; then
            echo "Output file already exists, skipping: ${dataset}-${split}-uniform-out.txt"
        else
            echo "--Running example: ${dataset}-uniform"
            # comment weight learning. sed -i doesnt work on mac
            sed  's/runWeightLearning "$@"/# runWeightLearning/' run.sh > runtemp.sh ; mv runtemp.sh run.sh
            # create a uniform weighted psl file 
            cp ${dataset}.psl ${dataset}-learned.psl
            sh ./run.sh --postgres ${DEFAULT_POSTGRES_DB} -D log4j.threshold=DEBUG > "../$OUTDIR/${dataset}-${split}-uniform-out.txt" 2> "../$OUTDIR/${dataset}-${split}-uniform-err.txt"
            # uncomment weight learning
            sed 's/# runWeightLearning/runWeightLearning "$@"/' run.sh > runtemp.sh ; mv runtemp.sh run.sh
            rm ${dataset}-learned.psl
            for this_inferred_predicate in "$INFERRED_PREDICATES_PATH" ; do
                predicate_file=$(echo $this_inferred_predicate | cut -d/ -f3)
                cp $this_inferred_predicate "../$OUTDIR/${dataset}-${split}-uniform-inferred-${predicate_file%%}"
            done
        fi

        # for all weight learning methods
        for wl_method in "${WL_METHODS[@]}" ; do
            echo "Running $wl_method on $split on $dataset"
            # replace weight learning method
            sed "s/readonly ADDITIONAL_LEARN_OPTIONS='--learn'/readonly ADDITIONAL_LEARN_OPTIONS='--learn ${BASE_WEIGHT_NAME}${wl_method}'/" run.sh > runtemp.sh ; mv runtemp.sh run.sh
            # run weight learning and eval with ./run.sh
            if [[ -e "../$OUTDIR/${dataset}-${split}-${wl_method}-out.txt" ]]; then
                echo "Output file already exists, skipping: $wl_method on $split on $dataset"
            else
                echo "--Running example: $wl_method on $split on $dataset"
                sh ./run.sh --postgres ${DEFAULT_POSTGRES_DB} -D log4j.threshold=DEBUG > "../$OUTDIR/${dataset}-${split}-${wl_method}-out.txt" 2> "../$OUTDIR/${dataset}-${split}-${wl_method}-err.txt"
            fi
            # backup the -learned.psl to out directory with WL method suffixed.
            cp "${dataset}-learned.psl" "../out/${dataset}-${split}-${wl_method}-learned.psl"
            # backup the inferred predicates/predicate.txt to out directory with WL method suffixed. 
            for this_inferred_predicate in "$INFERRED_PREDICATES_PATH" ; do
                predicate_file=$(echo $this_inferred_predicate | cut -d/ -f3)
                cp $this_inferred_predicate "../$OUTDIR/${dataset}-${split}-${wl_method}-inferred-${predicate_file%%}"
            done
        done
    done
    popd > /dev/null
    rm "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-eval.data"
    rm "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-learn.data"
done

# if out directory seen in all repos parse and summarize result as a table.
