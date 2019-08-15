# Run weight Learning experiments on all examples in the repository
readonly BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly OTHER_EXAMPLES_DIR="${BASE_DIR}/other-examples"
readonly PSL_EXAMPLES_DIR="${BASE_DIR}/psl-examples"
readonly OUTDIR="out"
readonly INFERRED_PREDICATES_PATH="./inferred-predicates/*"
# if out directory not found run WL, else skip.

declare -a WL_METHODS=("bayesian.GaussianProcessPrior -D gpp.maxiterations=50" "maxlikelihood.MaxLikelihoodMPE" "maxlikelihood.MaxPiecewisePseudoLikelihood" "search.Hyperband" "search.InitialWeightHyperband" "search.grid.ContinuousRandomGridSearch" "search.grid.GuidedRandomGridSearch" "search.grid.RandomGridSearch")
BASE_WEIGHT_NAME='org.linqs.psl.application.learning.weight.'

for dataset in */ ; do # for all datasets i.e examples
    for split in {0..4}; do # for all splits
        # create eval.data file from template 
        if [[ ! -e "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-${split}-eval.data" ]]; then
            sed "s/__fold__/$split/g" "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-template-eval.data" > "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-${split}-eval.data"
        fi
        # create learn.data file from template
            if [[ ! -e "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-${split}-learn.data" ]]; then
                sed "s/__fold__/$split/g" "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-template-learn.data" > "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-${split}-learn.data"
            fi
        # make logs dir
        mkdir -p "${OTHER_EXAMPLES_DIR}/${dataset}/$OUTDIR"
        pushd . > /dev/null
        cd "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/"
        # comment weight learning. sed -i doesnt work on mac
        sed  's/runWeightLearning "$@"/# runWeightLearning/' run.sh > runtemp.sh ; mv runtemp.sh run.sh
        #run uniform on eval
        if [[ -e "${dataset}-uniform-out.txt" ]]; then
            echo "Output file already exists, skipping: ${dataset}-uniform-out.txt"
        else
            echo "--Running example: ${dataset}-uniform"
            ./run.sh --postgres ${DEFAULT_POSTGRES_DB} -D log4j.threshold=DEBUG > "../$OUTDIR/${dataset}-uniform-out.txt" 2> "../$OUTDIR/${dataset}-uniform-err.txt"
        fi
        # uncomment weight learning
        sed 's/# runWeightLearning/runWeightLearning "$@"/' run.sh > runtemp.sh ; mv runtemp.sh run.sh
        # for all weight learning methods
        for wl_method in "${WL_METHODS[@]}" ; do
            echo "Running $wl_method on $split on $dataset"
            # replace weight learning method
            sed "s/readonly ADDITIONAL_LEARN_OPTIONS='--learn'/readonly ADDITIONAL_LEARN_OPTIONS='--learn ${BASE_WEIGHT_NAME}${wl_method}'/" run.sh > runtemp.sh ; mv runtemp.sh run.sh
            # run weight learning and eval with ./run.sh
            if [[ -e "${dataset}-${split}-${wl_method}-out.txt" ]]; then
                echo "Output file already exists, skipping: $wl_method on $split on $dataset"
            else
                echo "--Running example: $wl_method on $split on $dataset"
                ./run.sh --postgres ${DEFAULT_POSTGRES_DB} -D log4j.threshold=DEBUG > "${dataset}-${split}-${wl_method}-out.txt" 2> "${dataset}/$OUTDIR/${dataset}-${split}-${wl_method}-err.txt"
            fi
            # move the -learned.psl to out directory with WL method suffixed.
            cp "${dataset}-learned.psl" "../out/${dataset}-${split}-${wl_method}-learned.psl"
            # move the inferred predicates/predicate.txt to out directory with WL method suffixed. 
            for this_inferred_predicate in "$INFERRED_PREDICATES_PATH" ; do
                predicate_file=$(echo $this_inferred_predicate | cut -d/ -f3)
                cp $this_inferred_predicate "../out/${dataset}-${wl_method}-${split}-inferred-${predicate_file%%}"
            done
        done
    done
    popd > /dev/null
    rm "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-${split}-eval.data"
    rm "$OTHER_EXAMPLES_DIR/$dataset/psl-cli/${dataset}-${split}-learn.data"
done

# if out directory seen in all repos parse and summarize result as a table.
