#!/bin/bash
# test_a1.sh

testName=test_a1

rm -rf backup_test
cp -r -a backup_$testName backup_test

#test results
./backup_summary.sh src backup_test > output.txt 2> err.txt

nlinesout=$(wc -l ${testName}.out | cut -d\  -f1)

#test results
# correct in head 
if cat output.txt   | grep . | head -${nlinesout} | tr -s ' ' | sort | diff - ${testName}.out > /dev/null
then
    score=$((score+60))
# correct in tail 
elif cat output.txt | grep . | tail -${nlinesout} | tr -s ' ' | sort | diff - ${testName}.out > /dev/null
then
    score=$((score+60))
fi

if [[ "$(ls -l backup_test)" == $(ls -l src) ]]
then
    score=$((score+25))
fi

if [[ "$(ls -l backup_test/aaa)" == $(ls -l src/aaa) ]]
then
    score=$((score+15))
fi


rm -rf output.txt err.txt backup_test


echo Score: $score
