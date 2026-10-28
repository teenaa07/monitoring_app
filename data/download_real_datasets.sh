#!/usr/bin/env bash
set -e
mkdir -p raw
curl -L "https://archive.ics.uci.edu/static/public/730/physical%2Btherapy%2Bexercises%2Bdataset.zip" -o raw/uci_physical_therapy_exercises.zip
curl -L "https://zenodo.org/records/12112951/files/dataset.zip?download=1" -o raw/knee_pad_dataset.zip
echo "Done. Raw research data is stored under data/raw and is not served by the frontend."
