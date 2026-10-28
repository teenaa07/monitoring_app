# Real rehabilitation datasets used by RehabCare

This project now includes dataset-backed exercise metadata and recommendation records. The raw research datasets are **not copied into this ZIP** because the KneE-PAD archive is about 289 MB and the UCI Physical Therapy Exercises archive is about 45.7 MB. The project instead stores verified source metadata and uses dataset-derived exercise labels in the Supabase seed.

## 1. KneE-PAD
- Dataset: Knee Rehabilitation Exercises for Postural Assessment using Wearable Devices
- Exercises represented in RehabCare: squat, seated leg extension, gait/walking
- 31 participants with knee pathologies; 2,086 published files; 8 synchronized sEMG/IMU sensors
- Zenodo: https://zenodo.org/records/12112951
- DOI: 10.5281/zenodo.12112951

## 2. UCI Physical Therapy Exercises
- 8 physical-therapy exercise types
- Correct, fast and low-amplitude execution categories
- 5 subjects; 268,881 instances; 25 Hz wearable accelerometer/gyroscope/magnetometer data
- UCI: https://archive.ics.uci.edu/dataset/730/physical%2Btherapy%2Bexercises%2Bdataset
- DOI: 10.24432/C5JK60
- License: CC BY 4.0

## Important
Dataset evidence is used to enrich the exercise catalog and condition-matching workflow. It is **not** a clinical prescribing rule. A doctor must review and approve every recommendation before it is assigned to a patient.
