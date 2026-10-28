# Patient Email Setup

The backend uses Nodemailer.

1. Copy `backend/.env.example` to `backend/.env`.
2. Enter your SMTP provider details.
3. For Gmail, enable 2-Step Verification and create a Gmail App Password.
4. Put the App Password in `SMTP_PASS`.
5. Start the backend with `npm run dev`.
6. Test `POST /api/email/patient-welcome`.

## When a doctor adds a patient

Your production flow should be:

Doctor submits patient -> create patient/auth record -> save doctor_id and rehabilitation_type_id -> call the email endpoint -> patient receives welcome/notification email.

Do not place SMTP passwords or Supabase service-role keys in React/Vite frontend environment variables. They belong only on the server.
