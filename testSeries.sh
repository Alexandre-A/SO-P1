#!/bin/bash

echo TEST1
./backup_summary.sh src backup_test
rm -rf backup_test
echo 
echo TEST2
./backup_summary.sh -c src backup_test
rm -rf backup_test
echo 
echo TEST3
./backup_summary.sh -r "file1.*" src backup_test
rm -rf backup_test
echo 
echo TEST4
./backup_summary.sh -b ign src backup_test
ls backup_test/morestuff/file20*
rm -rf backup_test
echo 
echo TEST5
./backup_summary.sh -c -r "file1.*" src backup_test
rm -rf backup_test
echo 
echo TEST6
./backup_summary.sh -c -b ign src backup_test
rm -rf backup_test
echo 
echo TEST7
./backup_summary.sh -b ign -r "file1.*" src backup_test
ls backup_test/morestuff/file1*
rm -rf backup_test
