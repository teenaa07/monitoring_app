# RehabCare — Supabase-connected rehabilitation monitoring app

This project is prepared so the **Supabase database is the source of truth** for patients, specialist doctors, exercise catalog, exercise assignments and treatment progress.

## Included
- Doctor/Admin and patient login
- Doctor-only patient creation
- Automatic specialist matching by rehabilitation type
- Physical / Mental Health / Substance Use rehabilitation pathways
- Condition-based exercise recommendations
- Real-dataset-backed exercise catalog metadata (including KneE-PAD)
- Doctor-customized exercise assignments
- Patient **My Exercises** page backed by Supabase
- Patient exercise session history
- Doctor treatment progress updates
- Patient progress dashboard
- Doctor treatment progress report and timeline
- Assessments and appointments

## Important
Run `database/schema.sql` **before testing the application**. Do not use an older Supabase schema with this project. The exact database setup and verification steps are in `database/SETUP_ORDER.md`.

The backend uses the Supabase **service-role key** server-side. Never expose that key in the frontend or commit `backend/.env`.

## Demo doctor
- Doctor ID: `DR-ADMIN-001`
- Password: `Admin@123`

Specialist accounts are also seeded by the schema for the three rehabilitation pathways. Change passwords before real deployment.
