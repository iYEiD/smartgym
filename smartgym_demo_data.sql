-- INSTRUCTIONS
-- docker cp ./smartgym_demo_data.sql smartgym_postgres:/tmp/
-- docker exec -it smartgym_postgres psql -U smartgym -d smartgym_db -f /tmp/smartgym_demo_data.sql


-- TO check if worked
-- docker exec -it smartgym_postgres bash
-- psql -U smartgym -d smartgym_db


BEGIN;

-- Users
INSERT INTO users (id, first_name, last_name, email, phone, membership_type, last_check_in, last_checkout, notes)
VALUES 
('u001', 'Alice', 'Smith', 'alice@smartgym.com', '1234567890', 'Standard', NOW() - interval '3 days', NOW() - interval '2 days', 'Morning workouts'),
('u002', 'Bob', 'Johnson', 'bob@smartgym.com', '1234567891', 'Premium', NULL, NULL, 'Prefers weekends'),
('u003', 'Charlie', 'Lee', 'charlie@smartgym.com', '1234567892', 'VIP', NOW() - interval '1 hour', NULL, 'On elite plan'),
('u004', 'Diana', 'King', 'diana@smartgym.com', '1234567893', 'Standard', NULL, NULL, 'Inactive'),
('u005', 'Evan', 'Wright', 'evan@smartgym.com', '1234567894', 'Premium', NULL, NULL, NULL);

-- Check-in logs
INSERT INTO check_in_logs (user_id, check_in_time, check_out_time)
VALUES
('u001', NOW() - interval '30 days', NOW() - interval '30 days' + interval '1 hour'),
('u002', NOW() - interval '20 days', NOW() - interval '20 days' + interval '1.5 hours'),
('u003', NOW() - interval '10 days', NOW() - interval '10 days' + interval '45 minutes'),
('u001', NOW() - interval '5 days', NOW() - interval '5 days' + interval '90 minutes'),
('u003', NOW() - interval '1 hour', NULL);

-- Occupancy records (1 per day for 90 days)
DO $$
DECLARE
  i INTEGER := 0;
  base TIMESTAMP := NOW() - interval '90 days';
BEGIN
  WHILE i < 90 LOOP
    INSERT INTO occupancy_records (timestamp, count, sensor_readings)
    VALUES (
      base + (i || ' days')::interval,
      5 + FLOOR(random() * 20)::int,
      jsonb_build_object(
        'motion', (random() > 0.1),
        'temp', round((22 + random() * 6)::numeric, 1)::float
      )
    );
    i := i + 1;
  END LOOP;
END$$;

-- Sensor data (1 per day for 90 days)
DO $$
DECLARE
  i INTEGER := 0;
  base TIMESTAMP := NOW() - interval '90 days';
BEGIN
  WHILE i < 90 LOOP
    INSERT INTO sensor_data (timestamp, light, temperature, humidity, parking, motion, lighting, ac, gate)
    VALUES (
      base + (i || ' days')::interval,
      300 + FLOOR(random() * 100)::int,
      round((22 + random() * 6)::numeric, 1)::float,
      round((30 + random() * 20)::numeric, 1)::float,
      (random() > 0.3),
      (random() > 0.1),
      (random() > 0.2),
      (random() > 0.2),
      (random() > 0.8)
    );
    i := i + 1;
  END LOOP;
END$$;

COMMIT;
