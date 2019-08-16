# Run weight Learning experiments on all examples in the repository
#!/bin/bash
set -e
readonly BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly OTHER_EXAMPLES_DIR="other-examples"
readonly PSL_EXAMPLES_DIR="psl-examples"
readonly OUTDIR="out"
readonly INFERRED_PREDICATES_DIR="inferred-predicates"
# if out directory not found run WL, else skip.

# Debug fucntion for testing the script w.r.t new file creation and deletion
emulate_psl()
{
    echo "got $1 $2 $3 $4"
    wl_method=$1    # uniform is 1 wl is 2
    dataset=$2
    split=$3
    #sleep 1s    #  uncomment to for a natural emulation WL/infernce takes these seconds
    if [[ $wl_method != "uniform" ]]; then
        touch "${dataset}-learned.psl"
    fi

    touch "../$OUTDIR/${dataset}-${split}-${wl_method}-out.txt"
    touch "../$OUTDIR/${dataset}-${split}-${wl_method}-err.txt"
    if [[ ! -d $INFERRED_PREDICATES_DIR ]] ; then
        mkdir -p inferred-predicates
        touch $INFERRED_PREDICATES_DIR/dummypredicate.txt
    fi
}

#TODO: measure time taken for experiments
declare -a WL_METHODS=("bayesian.GaussianProcessPrior" "maxlikelihood.MaxLikelihoodMPE" "maxlikelihood.MaxPiecewisePseudoLikelihood" "search.Hyperband" "search.InitialWeightHyperband" "search.grid.ContinuousRandomGridSearch" "search.grid.GuidedRandomGridSearch" "search.grid.RandomGridSearch")
BASE_WEIGHT_NAME='org.linqs.psl.application.learning.weight.'

# printf instead of echo for consitent \n print(mac/ubunutu)
printf "Beginning Weight Learning experiments. Ensure you have changed run script for java heap size and time command. \nBegin fresh experiments? (Press: y) \n(Delete all output directory and files). Default: Continue from cached output\n"
read setclear
if [[ $setclear = "yes" ]] ; then
    find . -type d -name "$OUTDIR" -exec rm -rf {} +
    find . -type d -name "$INFERRED_PREDICATES_DIR" -exec rm -rf {} +
    rm -f "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-eval.data"
    rm -f "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-learn.data"
fi

for dataset_dir in ./$OTHER_EXAMPLES_DIR/*; do # for all datasets i.e examples
    dataset=$(echo $dataset_dir | cut -d/ -f3)
    echo "dataset dir" $dataset_dir "dataset" $dataset
    for split in {0..4}; do # for all splits
        # create eval.data file from template
        echo "$dataset_dir $dataset $split"
        if [[ ! -e "$dataset_dir/psl-cli/${dataset}-eval.data" ]]; then
            sed "s/__fold__/$split/g" "$dataset_dir/psl-cli/${dataset}-template-eval.data" > "$dataset_dir/psl-cli/${dataset}-eval.data"
        fi
        # create learn.data file from template
        if [[ ! -e "$dataset_dir/psl-cli/${dataset}-learn.data" ]]; then
            sed "s/__fold__/$split/g" "$dataset_dir/psl-cli/${dataset}-template-learn.data"  > "$dataset_dir/psl-cli/${dataset}-learn.data"
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
            sed  's/runWeightLearning "$@".*/# runWeightLearning "$@"/g' run.sh > runtemp.sh ; mv runtemp.sh run.sh
            chmod 755 run.sh
            # create a uniform weighted psl file 
            cp ${dataset}.psl ${dataset}-learned.psl
            ./run.sh --postgres psl  -D log4j.threshold=DEBUG > "../$OUTDIR/${dataset}-${split}-uniform-out.txt" 2> "../$OUTDIR/${dataset}-${split}-uniform-err.txt"
            #emulate_psl "uniform" $dataset $split $wl_method
            # uncomment weight learning
            sed 's/# runWeightLearning "$@".*/runWeightLearning "$@"/g' run.sh > runtemp.sh ; mv runtemp.sh run.sh
            chmod 755 run.sh
            for this_inferred_predicate in "./$INFERRED_PREDICATES_DIR/*" ; do
                predicate_file=$(echo $this_inferred_predicate | cut -d/ -f3)
                cp $this_inferred_predicate "../$OUTDIR/${dataset}-${split}-uniform-inferred-${predicate_file%%}"
            done
            rm ${dataset}-learned.psl
        fi

        # for all weight learning methods
        for wl_method in "${WL_METHODS[@]}" ; do
            echo "Running $wl_method on $split on $dataset"
            # replace weight learning method
            sed "s/readonly ADDITIONAL_LEARN_OPTIONS='--learn.*'/readonly ADDITIONAL_LEARN_OPTIONS='--learn ${BASE_WEIGHT_NAME}${wl_method}'/g" run.sh > runtemp.sh ; mv runtemp.sh run.sh
            chmod 755 run.sh
            # run weight learning and eval with ./run.sh
            if [[ -e "../$OUTDIR/${dataset}-${split}-${wl_method}-out.txt" ]]; then
                echo "Output file already exists, skipping: $wl_method on $split on $dataset"
            else
                echo "--Running example: $wl_method on $split on $dataset"
                ./run.sh --postgres psl  -D log4j.threshold=DEBUG > "../$OUTDIR/${dataset}-${split}-${wl_method}-out.txt" 2> "../$OUTDIR/${dataset}-${split}-${wl_method}-err.txt"
                #emulate_psl $wl_method $dataset $split
            fi
            # backup the -learned.psl to out directory with WL method suffixed.
            cp "${dataset}-learned.psl" "../out/${dataset}-${split}-${wl_method}-learned.psl"
            # backup the inferred predicates/predicate.txt to out directory with WL method suffixed. 
            for this_inferred_predicate in "./$INFERRED_PREDICATES_DIR/*" ; do
                predicate_file=$(echo $this_inferred_predicate | cut -d/ -f3)
                cp $this_inferred_predicate "../$OUTDIR/${dataset}-${split}-${wl_method}-inferred-${predicate_file%%}"
            done
        done
        popd > /dev/null
    done
    rm -f "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-eval.data"
    rm -f "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-learn.data"
done

# if out directory seen in all repos parse and summarize result as a table.
