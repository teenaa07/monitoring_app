$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path "raw" | Out-Null
Write-Host "Downloading UCI Physical Therapy Exercises..."
Invoke-WebRequest -Uri "https://archive.ics.uci.edu/static/public/730/physical%2Btherapy%2Bexercises%2Bdataset.zip" -OutFile "raw/uci_physical_therapy_exercises.zip"
Write-Host "Downloading KneE-PAD..."
Invoke-WebRequest -Uri "https://zenodo.org/records/12112951/files/dataset.zip?download=1" -OutFile "raw/knee_pad_dataset.zip"
Write-Host "Done. Raw research data is stored under data/raw and is not served by the frontend."
