#!/bin/bash

function upload_files {
  for file in *; do
    echo -n "Uploading $file ->   "
    curl --upload-file ./$file https://transfer.sh/${TRAVIS_BUILD_NUMBER}-${TRAVIS_JOB_NUMBER}_${file}
    echo "   ...done!"
  done
}

if [ -e /obs/src/api/log ]; then
  pushd /obs/src/api/log
  upload_files
fi
