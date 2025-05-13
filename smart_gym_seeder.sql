-- Smart Gym Database Seeder Script
-- Generates realistic data for users, check-ins, occupancy records, and sensor data

-- To use:
-- 1. Make sure your containers are running
-- 2. Run: docker cp smart_gym_seeder.sql smartgym_postgres:/smart_gym_seeder.sql
-- 3. Run: docker exec -u postgres smartgym_postgres psql -U smartgym -d smartgym_db -f /smart_gym_seeder.sql

-- Clear existing data (optional - uncomment if needed)
-- docker-compose exec postgres bash
-- psql -U smartgym -d smartgym_db
-- \dt
-- SELECT * FROM users;
-- SELECT * FROM check_in_logs;
-- SELECT * FROM occupancy_records;
-- SELECT * FROM sensor_data;
-- TRUNCATE check_in_logs CASCADE;
-- TRUNCATE occupancy_records CASCADE;
-- TRUNCATE sensor_data CASCADE;
-- TRUNCATE users CASCADE;

-- Set variables for data generation
DO $$
DECLARE
    -- Time range for data generation (90 days of history)
    start_date TIMESTAMP := NOW() - INTERVAL '90 days';
    end_date TIMESTAMP := NOW();
    
    -- User variables
    user_id VARCHAR(255);
    user_first_name VARCHAR(100);
    user_last_name VARCHAR(100);
    user_email VARCHAR(255);
    user_phone VARCHAR(20);
    user_membership VARCHAR(50);
    membership_types VARCHAR[] := ARRAY['Basic', 'Premium', 'Student', 'Family', 'Corporate', 'Senior'];
    first_names VARCHAR[] := ARRAY['James', 'Mary', 'Robert', 'Patricia', 'John', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth', 
                              'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen',
                              'Christopher', 'Nancy', 'Daniel', 'Lisa', 'Matthew', 'Betty', 'Anthony', 'Dorothy', 'Mark', 'Sandra',
                              'Emma', 'Olivia', 'Noah', 'Liam', 'Sophia', 'Ava', 'Jackson', 'Isabella', 'Lucas', 'Mia'];
    last_names VARCHAR[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 
                             'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
                             'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
                             'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores'];
    
    -- Sensor and occupancy variables
    curr_time TIMESTAMP;
    curr_date DATE;
    hour_of_day INT;
    day_of_week INT;
    is_weekend BOOLEAN;
    is_business_hours BOOLEAN;
    is_peak_hours BOOLEAN;
    base_occupancy INT;
    sensor_temp FLOAT;
    sensor_humidity FLOAT;
    sensor_light INT;
    sensor_parking BOOLEAN;
    sensor_motion BOOLEAN;
    sensor_lighting BOOLEAN;
    sensor_ac BOOLEAN;
    sensor_gate BOOLEAN;
    occupancy_count INT;
    checkin_count INT := 0;
    checkout_count INT := 0;
    
    -- Used for creating check-in/check-out pairs
    check_in_id INT;
    check_in_records INT[];
    duration_minutes INT;
    checkout_time TIMESTAMP;
    
    -- Number of users to generate
    num_users INT := 300;
    
    -- Temporary storage for user visit patterns
    user_visit_days INT[];
    user_visit_frequency INT;
    user_avg_duration INT;
    user_preferred_hour INT;
    user_variance INT;
    
    -- For loop control
    i INT;
    j INT;
BEGIN
    -- Generate Users
    FOR i IN 1..num_users LOOP
        user_id := 'USR' || LPAD(i::TEXT, 6, '0');
        user_first_name := first_names[1 + floor(random() * array_length(first_names, 1))];
        user_last_name := last_names[1 + floor(random() * array_length(last_names, 1))];
        user_email := LOWER(user_first_name || '.' || user_last_name || floor(random()*100)::TEXT || '@example.com');
        user_phone := '+1' || LPAD(floor(random() * 1000)::TEXT, 3, '0') || LPAD(floor(random() * 10000)::TEXT, 4, '0') || LPAD(floor(random() * 10000)::TEXT, 4, '0');
        user_membership := membership_types[1 + floor(random() * array_length(membership_types, 1))];
        
        -- Registration date between 1 year ago and now
        INSERT INTO users (id, first_name, last_name, email, phone, membership_type, registration_date)
        VALUES (
            user_id,
            user_first_name,
            user_last_name,
            user_email,
            user_phone,
            user_membership,
            start_date - (random() * INTERVAL '275 days')
        );
        
        -- Determine user's gym habits (which will be used later)
        -- Frequency: 1-7 (days per week they visit)
        user_visit_frequency := 1 + floor(random() * 5);
        -- Visit days preference (1=Monday, 7=Sunday)
        user_visit_days := ARRAY[]::INT[];
        WHILE array_length(user_visit_days, 1) IS NULL OR array_length(user_visit_days, 1) < user_visit_frequency LOOP
            j := 1 + floor(random() * 7);
            IF NOT (j = ANY(user_visit_days)) THEN
                user_visit_days := array_append(user_visit_days, j);
            END IF;
        END LOOP;
        
        -- Average duration (30-120 minutes)
        user_avg_duration := 30 + floor(random() * 90);
        -- Preferred hour (5-22, gym hours 5am-11pm)
        user_preferred_hour := 5 + floor(random() * 17);
        -- Variance (how much they stick to schedule, 1-3)
        user_variance := 1 + floor(random() * 3);
        
        -- Now create visit history for this user
        curr_date := start_date::DATE;
        WHILE curr_date <= end_date::DATE LOOP
            day_of_week := EXTRACT(DOW FROM curr_date) + 1; -- Postgres DOW is 0-6, convert to 1-7
            
            -- Check if user typically visits on this day
            IF day_of_week = ANY(user_visit_days) AND random() < 0.85 THEN -- 85% chance they follow their routine
                -- Determine check-in time based on preferred hour with variance
                hour_of_day := user_preferred_hour + (floor(random() * (2*user_variance)) - user_variance);
                -- Keep hour in reasonable range
                hour_of_day := GREATEST(5, LEAST(22, hour_of_day));
                
                -- Actual check-in time
                curr_time := curr_date + (hour_of_day * INTERVAL '1 hour') + (floor(random() * 60) * INTERVAL '1 minute');
                
                -- If check-in is in the future, skip
                CONTINUE WHEN curr_time > end_date;
                
                -- Check-in duration with variance
                duration_minutes := GREATEST(10, user_avg_duration + floor(random() * 40) - 20);
                checkout_time := curr_time + (duration_minutes * INTERVAL '1 minute');
                
                -- Only add completed visits for past days
                IF checkout_time <= end_date THEN
                    INSERT INTO check_in_logs (user_id, check_in_time, check_out_time, duration_minutes)
                    VALUES (user_id, curr_time, checkout_time, duration_minutes);
                    checkin_count := checkin_count + 1;
                -- For current day, some visits might be in progress (no checkout)
                ELSIF curr_time <= end_date AND checkout_time > end_date THEN
                    INSERT INTO check_in_logs (user_id, check_in_time)
                    VALUES (user_id, curr_time);
                    checkin_count := checkin_count + 1;
                END IF;
            END IF;
            
            -- Move to next day
            curr_date := curr_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    
    -- Update last_check_in and last_checkout in users table
    UPDATE users u
    SET last_check_in = (
        SELECT MAX(check_in_time) 
        FROM check_in_logs 
        WHERE check_in_logs.user_id = u.id
    ),
    last_checkout = (
        SELECT MAX(check_out_time) 
        FROM check_in_logs 
        WHERE check_in_logs.user_id = u.id AND check_out_time IS NOT NULL
    );
    
    -- Generate sensor data and occupancy records every 15 minutes for the period
    curr_time := start_date;
    
    WHILE curr_time <= end_date LOOP
        -- Extract time components
        hour_of_day := EXTRACT(HOUR FROM curr_time);
        day_of_week := EXTRACT(DOW FROM curr_time);
        is_weekend := day_of_week = 0 OR day_of_week = 6; -- 0=Sunday, 6=Saturday
        is_business_hours := hour_of_day BETWEEN 7 AND 21;
        is_peak_hours := (hour_of_day BETWEEN 6 AND 8) OR (hour_of_day BETWEEN 17 AND 19);
        
        -- Generate realistic sensor data based on time of day and day of week
        
        -- Light: Higher during daylight hours, lower at night
        -- Business hours: well-lit gym
        IF hour_of_day BETWEEN 7 AND 19 THEN 
            sensor_light := 400 + floor(random() * 200); -- 400-600 (bright)
        -- Dawn/dusk
        ELSIF hour_of_day BETWEEN 5 AND 6 OR hour_of_day BETWEEN 20 AND 21 THEN
            sensor_light := 200 + floor(random() * 200); -- 200-400 (medium)
        -- Night
        ELSE
            sensor_light := 50 + floor(random() * 150); -- 50-200 (low)
        END IF;
        
        -- Temperature: Higher during busy hours, lower at night
        -- Base temperature based on time of day
        IF hour_of_day BETWEEN 12 AND 18 THEN
            -- Afternoon peak temperature
            sensor_temp := 22.5 + (random() * 3.0); -- 22.5-25.5°C
        ELSIF hour_of_day BETWEEN 6 AND 11 OR hour_of_day BETWEEN 19 AND 22 THEN
            -- Morning and evening temperature
            sensor_temp := 21.0 + (random() * 2.5); -- 21.0-23.5°C
        ELSE
            -- Night temperature (lower setting when less occupied)
            sensor_temp := 19.0 + (random() * 2.0); -- 19.0-21.0°C
        END IF;
        
        -- Humidity: Varies with gym activity and time of day
        IF is_peak_hours THEN
            -- More people = higher humidity
            sensor_humidity := 50.0 + (random() * 15.0); -- 50-65%
        ELSIF is_business_hours THEN
            -- Regular operation hours
            sensor_humidity := 45.0 + (random() * 10.0); -- 45-55%
        ELSE
            -- Lower overnight
            sensor_humidity := 40.0 + (random() * 8.0); -- 40-48%
        END IF;
        
        -- Boolean sensors
        -- Parking sensor more likely to detect cars during business hours and peak times
        IF is_business_hours THEN
            sensor_parking := random() < (CASE WHEN is_peak_hours AND NOT is_weekend THEN 0.9 ELSE 0.7 END);
        ELSE
            sensor_parking := random() < 0.2; -- Few cars at night
        END IF;
        
        -- Motion depends on occupancy
        sensor_motion := random() < (CASE WHEN is_business_hours THEN 0.85 ELSE 0.15 END);
        
        -- Lighting follows opening hours and motion
        sensor_lighting := (hour_of_day BETWEEN 5 AND 23) OR (sensor_motion AND random() < 0.7);
        
        -- AC likely on during business hours, might be off or lower overnight
        sensor_ac := is_business_hours OR random() < 0.3;
        
        -- Gate: Open during business hours, closed at night
        sensor_gate := hour_of_day BETWEEN 5 AND 23;
        
        -- Insert sensor data
        INSERT INTO sensor_data (
            timestamp, 
            light, 
            temperature, 
            humidity, 
            parking, 
            motion, 
            lighting, 
            ac, 
            gate
        ) VALUES (
            curr_time,
            sensor_light,
            sensor_temp,
            sensor_humidity,
            sensor_parking,
            sensor_motion,
            sensor_lighting,
            sensor_ac,
            sensor_gate
        );
        
        -- Calculate occupancy based on time patterns
        -- Base occupancy pattern depends on time
        IF is_peak_hours THEN
            base_occupancy := 30 + floor(random() * 40); -- 30-70 people during peak
        ELSIF is_business_hours THEN
            base_occupancy := 15 + floor(random() * 25); -- 15-40 during regular hours
        ELSE
            base_occupancy := floor(random() * 10); -- 0-10 overnight
        END IF;
        
        -- Add weekday/weekend variation
        IF is_weekend THEN
            -- Weekends are about 70% as busy as weekdays
            base_occupancy := floor(base_occupancy * 0.7);
        END IF;
        
        -- Add some randomness
        occupancy_count := GREATEST(0, base_occupancy + floor(random() * 10) - 5);
        
        -- Create sensor readings JSON
        INSERT INTO occupancy_records (
            timestamp,
            count,
            sensor_readings
        ) VALUES (
            curr_time,
            occupancy_count,
            json_build_object(
                'temperature', sensor_temp,
                'humidity', sensor_humidity,
                'light', sensor_light,
                'motion_detected', sensor_motion,
                'parking_status', sensor_parking
            )
        );
        
        -- Advance time by 15 minutes
        curr_time := curr_time + INTERVAL '15 minutes';
    END LOOP;
    
    -- Output summary
    RAISE NOTICE 'Data generation complete:';
    RAISE NOTICE '- % users created', num_users;
    RAISE NOTICE '- % check-in records created', checkin_count;
    RAISE NOTICE '- % sensor readings created', (EXTRACT(EPOCH FROM (end_date - start_date)) / 60 / 15)::INT;
    RAISE NOTICE '- % occupancy records created', (EXTRACT(EPOCH FROM (end_date - start_date)) / 60 / 15)::INT;
    
END $$;

-- Create function to get current gym occupancy
CREATE OR REPLACE FUNCTION get_current_occupancy()
RETURNS TABLE (current_count INTEGER, capacity INTEGER, percentage NUMERIC) AS $$
DECLARE
    max_capacity INTEGER := 100; -- Set your gym's maximum capacity
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE((SELECT count FROM occupancy_records ORDER BY timestamp DESC LIMIT 1), 0) as current_count,
        max_capacity as capacity,
        COALESCE((SELECT count FROM occupancy_records ORDER BY timestamp DESC LIMIT 1), 0)::NUMERIC / max_capacity * 100 as percentage;
END;
$$ LANGUAGE plpgsql;

-- Create function to get daily occupancy patterns
CREATE OR REPLACE FUNCTION get_daily_occupancy_patterns()
RETURNS TABLE (hour_of_day INTEGER, avg_occupancy NUMERIC, day_type TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(HOUR FROM timestamp)::INTEGER AS hour_of_day,
        AVG(count)::NUMERIC AS avg_occupancy,
        CASE 
            WHEN EXTRACT(DOW FROM timestamp) IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM 
        occupancy_records
    WHERE 
        timestamp >= NOW() - INTERVAL '30 days'
    GROUP BY 
        EXTRACT(HOUR FROM timestamp),
        CASE 
            WHEN EXTRACT(DOW FROM timestamp) IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END
    ORDER BY 
        hour_of_day;
END;
$$ LANGUAGE plpgsql;