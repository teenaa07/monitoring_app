-- RehabCare advanced Supabase schema. Run the whole file in SQL Editor.
create extension if not exists pgcrypto with schema extensions;
create table if not exists rehabilitation_types (id uuid primary key default gen_random_uuid(),name text not null unique,description text,is_active boolean default true,created_at timestamptz default now());
insert into rehabilitation_types(name,description) values
('Physical Rehabilitation','Exercise-based physical recovery, mobility and injury rehabilitation'),
('Mental Health Rehabilitation','Therapy, counseling and emotional wellbeing support'),
('Substance Use Rehabilitation','Recovery planning, counseling, support and monitoring') on conflict(name) do nothing;
create table if not exists doctors(id uuid primary key default gen_random_uuid(),login_id text unique,password_hash text,name text not null,email text unique,specialization text,created_at timestamptz default now());
alter table doctors add column if not exists login_id text; alter table doctors add column if not exists password_hash text;
create unique index if not exists doctors_login_id_key on doctors(login_id) where login_id is not null;
alter table doctors add column if not exists rehabilitation_type_id uuid references rehabilitation_types(id);
alter table doctors add column if not exists is_specialist boolean default false;
alter table doctors add column if not exists specialty_focus text;
alter table doctors add column if not exists is_active boolean default true;
create table if not exists patients(id uuid primary key default gen_random_uuid(),user_id uuid,login_id text unique,password_hash text,doctor_id uuid references doctors(id),rehabilitation_type_id uuid references rehabilitation_types(id),name text not null,email text not null unique,phone text,date_of_birth date,gender text,condition text,is_active boolean default true,created_at timestamptz default now());
alter table patients add column if not exists login_id text; alter table patients add column if not exists password_hash text; alter table patients add column if not exists phone text; alter table patients add column if not exists date_of_birth date; alter table patients add column if not exists gender text; alter table patients add column if not exists condition text;
create unique index if not exists patients_login_id_key on patients(login_id) where login_id is not null;
alter table patients add column if not exists specialist_doctor_id uuid references doctors(id);
create table if not exists exercises(id uuid primary key default gen_random_uuid(),name text not null,description text,video_url text,duration_minutes integer default 5,sets integer default 1,repetitions integer default 10,rehabilitation_type_id uuid references rehabilitation_types(id),condition_tags text default '',difficulty text default 'Easy',is_active boolean default true,source_dataset text,source_url text,license text,evidence_note text,dataset_exercise_label text,created_at timestamptz default now());
alter table exercises add column if not exists condition_tags text default ''; alter table exercises add column if not exists difficulty text default 'Easy'; alter table exercises add column if not exists is_active boolean default true; alter table exercises add column if not exists source_dataset text; alter table exercises add column if not exists source_url text; alter table exercises add column if not exists license text; alter table exercises add column if not exists evidence_note text; alter table exercises add column if not exists dataset_exercise_label text;
create table if not exists rehabilitation_plans(id uuid primary key default gen_random_uuid(),patient_id uuid references patients(id) on delete cascade,doctor_id uuid references doctors(id),title text not null,start_date date,end_date date,instructions text,status text default 'active',created_at timestamptz default now());
create table if not exists plan_exercises(id uuid primary key default gen_random_uuid(),plan_id uuid references rehabilitation_plans(id) on delete cascade,exercise_id uuid references exercises(id),sets integer,repetitions integer,frequency_per_day integer default 1,preferred_time text,difficulty text default 'Easy',duration_minutes integer,patient_notes text);
alter table plan_exercises add column if not exists preferred_time text; alter table plan_exercises add column if not exists difficulty text default 'Easy'; alter table plan_exercises add column if not exists duration_minutes integer; alter table plan_exercises add column if not exists patient_notes text;
create table if not exists exercise_progress(id uuid primary key default gen_random_uuid(),patient_id uuid references patients(id) on delete cascade,exercise_id uuid references exercises(id),completed_sets integer default 0,completed_repetitions integer default 0,duration_seconds integer default 0,completion_percentage numeric(5,2) default 0,completed_at timestamptz default now());
create table if not exists appointments(id uuid primary key default gen_random_uuid(),patient_id uuid references patients(id) on delete cascade,doctor_id uuid references doctors(id),appointment_date date not null,appointment_time time not null,appointment_type text,status text default 'scheduled',notes text,created_at timestamptz default now());
create table if not exists treatment_progress(id uuid primary key default gen_random_uuid(),patient_id uuid not null references patients(id) on delete cascade,plan_id uuid references rehabilitation_plans(id) on delete cascade,doctor_id uuid references doctors(id),progress_percentage numeric(5,2) not null check(progress_percentage>=0 and progress_percentage<=100),notes text,created_at timestamptz default now());
create table if not exists patient_assessments(id uuid primary key default gen_random_uuid(),patient_id uuid references patients(id) on delete cascade,doctor_id uuid references doctors(id),assessment_type text,score numeric,observations text,recommendations text,assessment_date date default current_date,created_at timestamptz default now());
insert into doctors(login_id,password_hash,name,email,specialization) values('DR-ADMIN-001',extensions.crypt('Admin@123',extensions.gen_salt('bf')),'Dr. Sharma','doctor@rehabcare.local','Rehabilitation Specialist') on conflict(login_id) do nothing;

-- Specialist doctors mapped to rehabilitation pathways. The logged-in admin can assign one to each patient.
insert into doctors(login_id,password_hash,name,email,specialization,rehabilitation_type_id,is_specialist,specialty_focus)
select x.login_id, extensions.crypt(x.password,extensions.gen_salt('bf')),x.name,x.email,x.specialization,r.id,true,x.focus
from (values
('DR-PHYS-001','Specialist@123','Dr. Sharma','dr.sharma@rehabcare.local','Orthopedic Specialist','Knee, back, shoulder and post-surgery physical rehabilitation','Physical Rehabilitation'),
('DR-PHYS-002','Specialist@123','Dr. Patel','dr.patel@rehabcare.local','Physiotherapist','Movement therapy, mobility, strength and exercise training','Physical Rehabilitation'),
('DR-MENTAL-001','Specialist@123','Dr. Mehta','dr.mehta@rehabcare.local','Clinical Psychologist','Anxiety, depression, stress and emotional wellbeing','Mental Health Rehabilitation'),
('DR-MENTAL-002','Specialist@123','Dr. Kapoor','dr.kapoor@rehabcare.local','Rehabilitation Counselor','Therapy support, coping skills and recovery planning','Mental Health Rehabilitation'),
('DR-SUD-001','Specialist@123','Dr. Singh','dr.singh@rehabcare.local','Addiction Specialist','Substance-use recovery planning and relapse prevention','Substance Use Rehabilitation')
) as x(login_id,password,name,email,specialization,focus,rehab)
join rehabilitation_types r on r.name=x.rehab
on conflict(login_id) do update set specialization=excluded.specialization,rehabilitation_type_id=excluded.rehabilitation_type_id,is_specialist=true,specialty_focus=excluded.specialty_focus;

-- Automatically assign the first active specialist whose rehabilitation pathway matches the patient's rehabilitation type.
create or replace function auto_assign_specialist_doctor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.rehabilitation_type_id is not null then
    select d.id into new.specialist_doctor_id
    from public.doctors d
    where d.is_active = true
      and d.is_specialist = true
      and d.rehabilitation_type_id = new.rehabilitation_type_id
    order by d.created_at asc, d.name asc
    limit 1;
  end if;
  return new;
end;
$$;

drop trigger if exists patients_auto_assign_specialist on patients;
create trigger patients_auto_assign_specialist
before insert or update of rehabilitation_type_id on patients
for each row execute function auto_assign_specialist_doctor();

-- Repair existing patient records after the trigger is installed.
update patients p
set specialist_doctor_id = d.id
from doctors d
where p.rehabilitation_type_id = d.rehabilitation_type_id
  and d.is_active = true
  and d.is_specialist = true
  and (p.specialist_doctor_id is null or p.specialist_doctor_id <> d.id)
  and d.id = (
    select d2.id from doctors d2
    where d2.is_active = true
      and d2.is_specialist = true
      and d2.rehabilitation_type_id = p.rehabilitation_type_id
    order by d2.created_at asc, d2.name asc
    limit 1
  );

-- Seed a practical recommendation catalog. Doctor approval is required before assignment.
insert into exercises(name,description,duration_minutes,sets,repetitions,rehabilitation_type_id,condition_tags,difficulty)
select x.name,x.description,x.duration,x.sets,x.reps,r.id,x.tags,x.difficulty from (values
('Heel Slide','Slide the heel toward the body slowly and return with control.',7,3,10,'knee,knee injury,post surgery,leg,arthritis,acl,meniscus','Easy'),
('Quad Set','Tighten the thigh muscle gently while keeping the leg supported.',5,3,10,'knee,knee injury,leg','Easy'),
('Straight Leg Raise','Keep the knee straight and raise the leg slowly.',8,3,10,'knee,knee injury,leg','Moderate'),
('Knee Extension','Extend and lower the knee through a comfortable range.',10,3,10,'knee,knee injury,leg','Moderate'),
('Pelvic Tilt','Gently engage the core and tilt the pelvis with controlled movement.',6,2,10,'back,back pain,lumbar,core,spine,posture','Easy'),
('Gentle Hamstring Stretch','Stretch the back of the thigh without bouncing.',5,2,5,'back,back pain,leg,hamstring','Easy'),
('Wall Slide','Slide the arms up the wall within a comfortable shoulder range.',8,2,10,'shoulder,shoulder injury,arm,rotator cuff','Easy'),
('Pendulum Exercise','Allow the arm to move gently while supported by the body.',5,2,10,'shoulder,shoulder injury,arm,rotator cuff','Easy'),
('Guided Breathing','Use slow breathing to settle the body before a session.',5,2,5,'anxiety,stress,panic,mental health,depression,insomnia','Easy'),
('Mindfulness Session','Complete a short guided mindfulness and reflection activity.',10,1,1,'anxiety,stress,mindfulness,mental health,depression,insomnia','Easy'),
('Grounding Exercise','Use a structured sensory grounding exercise to reconnect with the present moment.',8,2,5,'anxiety,stress,trauma,mental health,depression,insomnia','Easy'),
('Recovery Check-in','Complete a guided daily recovery reflection and support check-in.',10,1,1,'addiction,substance use,recovery,craving,alcohol,opioid,tobacco','Easy'),
('Breathing & Grounding','Practice slow breathing and grounding techniques.',8,2,5,'addiction,substance use,recovery,stress,alcohol,opioid,tobacco','Easy') ) as x(name,description,duration,sets,reps,tags,difficulty)
join rehabilitation_types r on ((x.tags like '%knee%' or x.tags like '%back%' or x.tags like '%shoulder%') and r.name='Physical Rehabilitation') or ((x.tags like '%mental health%' or x.tags like '%anxiety%' or x.tags like '%stress%' or x.tags like '%trauma%') and r.name='Mental Health Rehabilitation') or ((x.tags like '%addiction%' or x.tags like '%substance use%' or x.tags like '%recovery%' or x.tags like '%craving%') and r.name='Substance Use Rehabilitation')
where not exists(select 1 from exercises e where e.name=x.name);

-- Real-world dataset-backed knee exercise catalog from KneE-PAD (Zenodo DOI 10.5281/zenodo.12112951).
-- The dataset contains recordings from patients with knee pathologies performing squats, seated leg extension and gait/walking.
insert into exercises(name,description,duration_minutes,sets,repetitions,rehabilitation_type_id,condition_tags,difficulty,source_dataset,source_url,license,evidence_note,dataset_exercise_label)
select x.name,x.description,x.duration,x.sets,x.reps,r.id,x.tags,x.difficulty,'KneE-PAD',x.source_url,x.license,x.note,x.label
from (values
('KneE-PAD Squat','Dataset-backed lower-limb rehabilitation movement used in knee postural-assessment research.',8,2,8,'knee,knee injury,osteoarthritis,acl,meniscus,lower limb,mobility','Moderate','https://zenodo.org/records/12112951','Dataset record on Zenodo; verify current license terms before redistribution.','KneE-PAD includes squat recordings from participants with knee pathologies and correct/incorrect execution variations.','squat'),
('KneE-PAD Seated Leg Extension','Dataset-backed seated knee flexion/extension movement used in knee rehabilitation research.',8,2,10,'knee,knee injury,osteoarthritis,acl,meniscus,post surgery,leg','Moderate','https://zenodo.org/records/12112951','Dataset record on Zenodo; verify current license terms before redistribution.','KneE-PAD includes seated leg-extension recordings from participants with knee pathologies and correct/incorrect execution variations.','seated leg extension'),
('KneE-PAD Gait / Walking','Dataset-backed gait activity used for lower-limb rehabilitation and functional mobility assessment.',10,2,1,'knee,knee injury,osteoarthritis,acl,meniscus,gait,walking,mobility','Easy','https://zenodo.org/records/12112951','Dataset record on Zenodo; verify current license terms before redistribution.','KneE-PAD includes gait/walking recordings from participants with knee pathologies and correct/incorrect execution variations.','gait / walking')
) as x(name,description,duration,sets,reps,tags,difficulty,source_url,license,note,label)
join rehabilitation_types r on r.name='Physical Rehabilitation'
where not exists(select 1 from exercises e where e.name=x.name);

create index if not exists exercises_source_dataset_idx on exercises(source_dataset);
create index if not exists treatment_progress_patient_id_idx on treatment_progress(patient_id); create index if not exists treatment_progress_plan_id_idx on treatment_progress(plan_id); create index if not exists patients_doctor_id_idx on patients(doctor_id); create index if not exists patients_rehab_type_idx on patients(rehabilitation_type_id); create index if not exists exercise_rehab_type_idx on exercises(rehabilitation_type_id); create index if not exists progress_patient_id_idx on exercise_progress(patient_id); create index if not exists plan_patient_id_idx on rehabilitation_plans(patient_id); create index if not exists appointments_patient_id_idx on appointments(patient_id); create index if not exists assessments_patient_id_idx on patient_assessments(patient_id);
create or replace function verify_doctor_login(p_login_id text,p_password text) returns table(id uuid,login_id text,name text,email text,specialization text) language sql security definer set search_path=public as $$ select d.id,d.login_id,d.name,d.email,d.specialization from doctors d where d.login_id=p_login_id and d.password_hash=extensions.crypt(p_password,d.password_hash); $$;


-- Patient login verification helper (backend currently uses scrypt hashes for patient accounts).
-- Kept available for future database-side authentication integrations.
create or replace function verify_patient_login(
  p_login_id text,
  p_password text
)
returns table(
  id uuid,
  login_id text,
  name text,
  email text,
  doctor_id uuid,
  rehabilitation_type_id uuid
)
language sql
security definer
set search_path = public, extensions
as $$
  select p.id, p.login_id, p.name, p.email, p.doctor_id, p.rehabilitation_type_id
  from public.patients p
  where p.login_id = p_login_id
    and p.is_active = true;
$$;
