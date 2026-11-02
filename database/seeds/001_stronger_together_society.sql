BEGIN;

DO $$
BEGIN
    IF current_database() <> 'funeral_spaces_dev' THEN
        RAISE EXCEPTION 'The Stronger Together demo seed is restricted to funeral_spaces_dev; current database is %', current_database();
    END IF;
END;
$$;

INSERT INTO funeral_spaces.society (society_code, display_name, status)
VALUES ('STRONGER-TOGETHER-DEMO', 'Stronger Together Society', 'active')
ON CONFLICT (society_code) DO NOTHING;

INSERT INTO funeral_spaces.space
    (society_id, space_type_id, display_name, status, is_discoverable, public_description)
SELECT society.society_id, type.space_type_id, 'Stronger Together Society', 'active', true,
       'A synthetic demo Society Space for testing organization onboarding and member workflows.'
  FROM funeral_spaces.society society
  JOIN funeral_spaces.space_type type ON type.code = 'society'
 WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
ON CONFLICT (society_id, space_type_id) DO NOTHING;

INSERT INTO funeral_spaces.society_onboarding_batch
    (society_id, idempotency_key, source_type, status, received_member_count,
     active_member_count, deactivated_member_count, covered_life_count,
     office_assignment_count, rejected_row_count, committed_at)
SELECT society_id, 'stronger-together-society-demo-v1', 'synthetic_seed', 'committed',
       35, 25, 10, 250, 6, 0, now()
  FROM funeral_spaces.society
 WHERE society_code = 'STRONGER-TOGETHER-DEMO'
ON CONFLICT (idempotency_key) DO NOTHING;

WITH numbers AS (
    SELECT value AS member_index
      FROM generate_series(1, 35) AS value
), seed_context AS (
    SELECT society.society_id, batch.onboarding_batch_id
      FROM funeral_spaces.society society
      JOIN funeral_spaces.society_onboarding_batch batch USING (society_id)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
       AND batch.idempotency_key = 'stronger-together-society-demo-v1'
)
INSERT INTO funeral_spaces.society_member
    (society_id, onboarding_batch_id, member_number, given_name, surname, status,
     joined_at, deactivated_at)
SELECT context.society_id, context.onboarding_batch_id,
       'STS-' || lpad(numbers.member_index::text, 3, '0'),
       'Synthetic Member', lpad(numbers.member_index::text, 3, '0'),
       CASE WHEN numbers.member_index <= 25 THEN 'active'::funeral_spaces.society_member_status
            ELSE 'deactivated'::funeral_spaces.society_member_status END,
       (current_date - ((numbers.member_index % 48) + 1) * interval '1 month')::date,
       CASE WHEN numbers.member_index <= 25 THEN NULL
            ELSE now() - interval '90 days' END
  FROM numbers CROSS JOIN seed_context context
ON CONFLICT (society_id, member_number) DO NOTHING;

WITH lives AS (
    SELECT member.member_id,
           member.joined_at,
           member.member_number,
           member.onboarding_batch_id,
           person.person_number
      FROM funeral_spaces.society_member member
      JOIN funeral_spaces.society society USING (society_id)
      CROSS JOIN generate_series(1, 10) AS person(person_number)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
       AND member.status = 'active'
       AND member.onboarding_batch_id = (
           SELECT onboarding_batch_id
             FROM funeral_spaces.society_onboarding_batch
            WHERE idempotency_key = 'stronger-together-society-demo-v1'
       )
)
INSERT INTO funeral_spaces.covered_life
    (member_id, onboarding_batch_id, person_number, display_name,
     relationship_code, status, effective_from)
SELECT lives.member_id, lives.onboarding_batch_id, lives.person_number,
       'Synthetic Life ' || lives.member_number || '-' || lpad(lives.person_number::text, 2, '0'),
       CASE WHEN lives.person_number = 1 THEN 'member'
            WHEN lives.person_number = 2 THEN 'spouse'
            ELSE 'dependent' END,
       'active', lives.joined_at
  FROM lives
ON CONFLICT (member_id, person_number) DO NOTHING;

INSERT INTO funeral_spaces.society_fee_schedule
    (society_id, onboarding_batch_id, version_number,
     monthly_contribution_amount, joining_fee_amount, currency_code,
     effective_from)
SELECT society.society_id, batch.onboarding_batch_id, 1, 250.00, 1000.00, 'ZAR', current_date
  FROM funeral_spaces.society society
  JOIN funeral_spaces.society_onboarding_batch batch USING (society_id)
 WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
   AND batch.idempotency_key = 'stronger-together-society-demo-v1'
ON CONFLICT (society_id, version_number) DO NOTHING;

WITH office_holders(member_number, role_code) AS (
    VALUES
        ('STS-001', 'chairperson'),
        ('STS-002', 'vice_chairperson'),
        ('STS-003', 'secretary'),
        ('STS-004', 'treasurer'),
        ('STS-005', 'claim_assessor'),
        ('STS-006', 'funeral_approver')
)
INSERT INTO funeral_spaces.society_office_assignment
    (society_id, member_id, role_code, onboarding_batch_id, effective_from)
SELECT member.society_id, member.member_id, office_holders.role_code,
       member.onboarding_batch_id, member.joined_at
  FROM office_holders
  JOIN funeral_spaces.society_member member USING (member_number)
  JOIN funeral_spaces.society society USING (society_id)
 WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
   AND member.status = 'active'
ON CONFLICT DO NOTHING;

DO $$
DECLARE
    active_members integer;
    deactivated_members integer;
    active_lives integer;
    active_offices integer;
    monthly_fee numeric(12, 2);
    joining_fee numeric(12, 2);
BEGIN
    SELECT count(*) FILTER (WHERE member.status = 'active'),
           count(*) FILTER (WHERE member.status = 'deactivated')
      INTO active_members, deactivated_members
      FROM funeral_spaces.society_member member
      JOIN funeral_spaces.society society USING (society_id)
       WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
         AND member.onboarding_batch_id = (
             SELECT onboarding_batch_id
               FROM funeral_spaces.society_onboarding_batch
              WHERE idempotency_key = 'stronger-together-society-demo-v1'
         );

    SELECT count(*)
      INTO active_lives
      FROM funeral_spaces.covered_life life
      JOIN funeral_spaces.society_member member USING (member_id)
      JOIN funeral_spaces.society society USING (society_id)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
         AND member.onboarding_batch_id = (
             SELECT onboarding_batch_id
               FROM funeral_spaces.society_onboarding_batch
              WHERE idempotency_key = 'stronger-together-society-demo-v1'
         )
       AND life.status = 'active';

    SELECT count(*)
      INTO active_offices
      FROM funeral_spaces.society_office_assignment assignment
      JOIN funeral_spaces.society society USING (society_id)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
         AND assignment.onboarding_batch_id = (
             SELECT onboarding_batch_id
               FROM funeral_spaces.society_onboarding_batch
              WHERE idempotency_key = 'stronger-together-society-demo-v1'
         )
       AND assignment.ended_at IS NULL;

    SELECT schedule.monthly_contribution_amount, schedule.joining_fee_amount
      INTO monthly_fee, joining_fee
      FROM funeral_spaces.society_fee_schedule schedule
      JOIN funeral_spaces.society society USING (society_id)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
       AND schedule.effective_to IS NULL;

    IF active_members <> 25 OR deactivated_members <> 10 OR active_lives <> 250
       OR active_offices <> 6 OR monthly_fee <> 250.00 OR joining_fee <> 1000.00 THEN
        RAISE EXCEPTION 'Demo seed count/rule check failed: active members %, deactivated members %, active covered lives %, active offices %, monthly fee %, joining fee %',
            active_members, deactivated_members, active_lives, active_offices, monthly_fee, joining_fee;
    END IF;
END;
$$;

COMMIT;