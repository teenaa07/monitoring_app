# RehabCare — Supabase setup order

Use this folder as the source of truth for the database.

## 1. Run the schema
Open Supabase → SQL Editor and run **database/schema.sql** as one script.

The schema creates/updates:
- rehabilitation types
- doctors and specialist doctors
- patients and patient login fields
- automatic specialist-doctor assignment by rehabilitation type
- real exercise catalog + dataset provenance
- rehabilitation plans and plan exercises
- exercise session progress
- doctor treatment progress
- assessments and appointments
- doctor/patient login helper functions

## 2. Verify the database
Run **database/verify_setup.sql**.

The first result should show active specialist doctors for all three pathways:
- Physical Rehabilitation
- Mental Health Rehabilitation
- Substance Use Rehabilitation

## 3. Configure backend
Copy `backend/.env.example` to `backend/.env` and fill in your Supabase project URL and **service-role key**. Keep `backend/.env` private and never put the service-role key in frontend code.

Required:
```
PORT=5000
FRONTEND_URL=http://localhost:5173
SESSION_SECRET=replace-with-a-long-random-secret
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR-SERVICE-ROLE-KEY
```

## 4. Configure frontend
Copy `frontend/.env.example` to `frontend/.env.local`:
```
VITE_API_URL=http://localhost:5000
```

## 5. Run
Backend:
```
cd backend
npm install
npm start
```

Frontend:
```
cd frontend
npm install
npm run dev
```

Check:
`http://localhost:5000/api/health`

It must return `databaseConfigured: true`.

## 6. Patient flow
Doctor creates a patient → Supabase stores the patient → database/backend automatically resolves a specialist matching the rehabilitation type → doctor recommends exercises → assignment is stored in `rehabilitation_plans` + `plan_exercises` → patient sees the assignment in **My Exercises**.

## 7. Treatment progress flow
Patient completing an exercise creates rows in `exercise_progress`.
The doctor opens **Progress Report** and records treatment progress (for example 20%, 40%, 60%, 80%, 100%) in `treatment_progress`.
The patient's Dashboard/Progress page reads the latest doctor treatment-progress record.
