#!/bin/bash

function upload_files(files) {
  for file in $files; do
    echo -n "Uploading $file ->   "
    curl --upload-file ./$file https://transfer.sh/${TRAVIS_BUILD_NUMBER}-${TRAVIS_JOB_NUMBER}_${file}
    echo "   ...done!"
  done
}

if [ -e /obs/src/api/log ]; then
  upload_files(/obs/src/api/log/*)
fi
