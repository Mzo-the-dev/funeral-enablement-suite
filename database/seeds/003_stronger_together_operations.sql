BEGIN;

DO $$
BEGIN
    IF current_database() <> 'funeral_spaces_dev' THEN
        RAISE EXCEPTION 'The society operations demo seed is restricted to funeral_spaces_dev; current database is %', current_database();
    END IF;
END;
$$;

WITH current_period AS (
    SELECT date_trunc('month', current_date - interval '1 month')::date AS period_start
), demo_members AS (
    SELECT member.member_id, member.society_id, member.member_number,
           current_period.period_start
      FROM funeral_spaces.society_member member
      JOIN funeral_spaces.society society USING (society_id)
      CROSS JOIN current_period
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
       AND member.status = 'active'
)
INSERT INTO funeral_spaces.society_contribution
    (society_id, member_id, period_start, due_date, amount_due, amount_paid,
     status, paid_at, receipt_reference)
SELECT demo_members.society_id, demo_members.member_id, demo_members.period_start,
       demo_members.period_start + 24,
       250.00,
       CASE WHEN demo_members.member_number IN ('STS-007', 'STS-012') THEN 0.00 ELSE 250.00 END,
       CASE WHEN demo_members.member_number IN ('STS-007', 'STS-012')
            THEN 'unpaid'::funeral_spaces.society_contribution_status
            ELSE 'paid'::funeral_spaces.society_contribution_status END,
       CASE WHEN demo_members.member_number IN ('STS-007', 'STS-012') THEN NULL
            ELSE (demo_members.period_start + 24)::timestamptz + interval '10 hours' END,
       CASE WHEN demo_members.member_number IN ('STS-007', 'STS-012') THEN NULL
            ELSE 'DEMO-' || demo_members.member_number || '-' || to_char(demo_members.period_start, 'YYYYMM') END
  FROM demo_members
ON CONFLICT (member_id, period_start) DO NOTHING;

WITH demo_cases(member_number, case_reference, status, summary) AS (
    VALUES
        ('STS-004', 'STS-FC-001', 'approved'::funeral_spaces.funeral_case_status, 'Synthetic funeral notification approved for demo review.'),
        ('STS-007', 'STS-FC-002', 'pending'::funeral_spaces.funeral_case_status, 'Synthetic funeral notification awaiting approver review.'),
        ('STS-012', 'STS-FC-003', 'pending'::funeral_spaces.funeral_case_status, 'Synthetic funeral notification awaiting supporting information.')
)
INSERT INTO funeral_spaces.funeral_case
    (society_id, member_id, case_reference, status, summary, reported_at,
     approved_at, approved_by_member_id)
SELECT member.society_id, member.member_id, demo_cases.case_reference,
       demo_cases.status, demo_cases.summary,
       (current_date - 8)::timestamptz + interval '9 hours',
       CASE WHEN demo_cases.status = 'approved'
            THEN (current_date - 5)::timestamptz + interval '11 hours' END,
       CASE WHEN demo_cases.status = 'approved' THEN approver.member_id END
  FROM demo_cases
  JOIN funeral_spaces.society_member member USING (member_number)
  JOIN funeral_spaces.society society USING (society_id)
  LEFT JOIN funeral_spaces.society_member approver
    ON approver.society_id = member.society_id AND approver.member_number = 'STS-006'
 WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
ON CONFLICT (society_id, case_reference) DO NOTHING;

DO $$
DECLARE
    contribution_count integer;
    paid_count integer;
    arrears_count integer;
    pending_case_count integer;
    approved_case_count integer;
BEGIN
        SELECT count(*), count(*) FILTER (WHERE contribution.status = 'paid'),
            count(*) FILTER (WHERE contribution.status = 'unpaid' AND contribution.due_date < current_date)
      INTO contribution_count, paid_count, arrears_count
      FROM funeral_spaces.society_contribution contribution
      JOIN funeral_spaces.society society USING (society_id)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
       AND contribution.period_start = date_trunc('month', current_date - interval '1 month')::date;

    SELECT count(*) FILTER (WHERE case_record.status = 'pending'),
           count(*) FILTER (WHERE case_record.status = 'approved')
      INTO pending_case_count, approved_case_count
      FROM funeral_spaces.funeral_case case_record
      JOIN funeral_spaces.society society USING (society_id)
     WHERE society.society_code = 'STRONGER-TOGETHER-DEMO'
       AND case_record.case_reference LIKE 'STS-FC-%';

    IF contribution_count <> 26 OR paid_count <> 24 OR arrears_count <> 2
       OR pending_case_count <> 2 OR approved_case_count <> 1 THEN
        RAISE EXCEPTION 'Operations demo check failed: contributions %, paid %, arrears %, pending cases %, approved cases %',
            contribution_count, paid_count, arrears_count, pending_case_count, approved_case_count;
    END IF;
END;
$$;

COMMIT;