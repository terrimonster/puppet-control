#!/bin/bash

failures=0
RC=0

if [ $(git rev-parse --is-bare-repository) = true ]
then
    REPOSITORY_BASENAME=$(basename "$PWD") 
    REPOSITORY_BASENAME=${REPOSITORY_BASENAME%.git}
else
    REPOSITORY_BASENAME=$(basename $(readlink -nf "$PWD"/..))
fi

subhook_root=hooks/commit_hooks
mktmpdir=`mkdir -p /tmp/$REPOSITORY_BASENAME`
tmptree="/tmp/$REPOSITORY_BASENAME"

while read oldrev newrev refname; do
    git archive $newrev | tar x -C ${tmptree}
	command=`git diff --name-only $oldrev $newrev`
    for changedfile in $(git diff --name-only $oldrev $newrev --diff-filter=ACM); do
        tmpmodule="$tmptree/$changedfile"
        #check puppet manifest syntax
        if type puppet >/dev/null 2>&1; then
            if [ $(echo $changedfile | grep -q '\.*.pp$'; echo $?) -eq 0 ]; then
                ${subhook_root}/puppet_manifest_syntax_check.sh $tmpmodule "${tmptree}/"
                RC=$?
                if [ "$RC" -ne 0 ]; then
                    failures=`expr $failures + 1`
                fi
            fi
        else
            echo "puppet not installed. Skipping puppet syntax checks..."
        fi

        #puppet manifest styleguide compliance
        if type puppet-lint >/dev/null 2>&1; then
            if [ $(echo $changedfile | grep -q '\.*.pp$' ; echo $?) -eq 0 ]; then 
                ${subhook_root}/puppet_lint_checks.sh $tmpmodule "${tmptree}/"
                RC=$?
                if [ "$RC" -ne 0 ]; then
                    failures=`expr $failures + 1`
                fi
            fi
        else
            echo "puppet-lint not installed. Skipping puppet-lint tests..."
        fi
    done
done
rm -rf ${tmptree}

#summary
if [ "$failures" -ne 0 ]; then
    echo -e "\x1B[0;31mError: $failures subhooks failed. Declining push.\x1B[0m"
    exit 1
fi

exit 0
