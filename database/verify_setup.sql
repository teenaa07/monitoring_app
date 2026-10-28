-- RehabCare database verification

-- 1. Every rehabilitation pathway should have at least one active specialist.
select rt.name as rehabilitation_type, count(d.id) as specialist_count
from rehabilitation_types rt
left join doctors d
  on d.rehabilitation_type_id = rt.id
 and d.is_specialist = true
 and d.is_active = true
group by rt.name
order by rt.name;

-- 2. Patient -> rehabilitation -> automatically assigned specialist.
select
  p.login_id,
  p.name,
  rt.name as rehabilitation_type,
  sd.login_id as specialist_login_id,
  sd.name as assigned_specialist,
  sd.specialization
from patients p
left join rehabilitation_types rt on rt.id = p.rehabilitation_type_id
left join doctors sd on sd.id = p.specialist_doctor_id
order by p.created_at desc;

-- 3. Exercise catalog.
select count(*) as active_exercise_count
from exercises
where is_active = true;

-- 4. Dataset-backed exercises.
select name, source_dataset, dataset_exercise_label
from exercises
where is_active = true and source_dataset is not null
order by name;

-- 5. Active plans and assignments.
select count(*) as active_plan_count
from rehabilitation_plans
where status = 'active';

select count(*) as assigned_exercise_count
from plan_exercises;

-- 6. Verify that a doctor's assignment is visible to the patient-facing My Exercises query.
select
  p.login_id as patient_id,
  p.name as patient,
  rp.title as plan,
  e.name as exercise,
  pe.sets,
  pe.repetitions,
  pe.frequency_per_day,
  pe.preferred_time,
  pe.difficulty,
  pe.duration_minutes
from patients p
join rehabilitation_plans rp
  on rp.patient_id = p.id
 and rp.status = 'active'
join plan_exercises pe on pe.plan_id = rp.id
join exercises e on e.id = pe.exercise_id
order by rp.created_at desc, e.name;

-- 7. Doctor treatment progress history.
select
  tp.created_at,
  p.login_id as patient_id,
  p.name as patient,
  tp.progress_percentage,
  tp.notes,
  d.name as doctor
from treatment_progress tp
join patients p on p.id = tp.patient_id
left join doctors d on d.id = tp.doctor_id
order by tp.created_at desc;
