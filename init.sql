-- Initialize database schema for Smart Gym Occupancy Monitoring app

-- Create Users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    membership_type VARCHAR(50) NOT NULL,
    last_check_in TIMESTAMP,
    last_checkout TIMESTAMP,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Create CheckInLogs table
CREATE TABLE IF NOT EXISTS check_in_logs (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) REFERENCES users(id),
    check_in_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_time TIMESTAMP,
    duration_minutes INT,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create OccupancyRecords table
CREATE TABLE IF NOT EXISTS occupancy_records (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    count INTEGER NOT NULL,
    sensor_readings JSONB
);

-- Create SensorData table
CREATE TABLE IF NOT EXISTS sensor_data (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    light INTEGER,
    temperature FLOAT,
    humidity FLOAT,
    parking BOOLEAN,
    motion BOOLEAN,
    lighting BOOLEAN,
    ac BOOLEAN,
    gate BOOLEAN
);

-- Create index for timestamp-based queries
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_occupancy_timestamp ON occupancy_records(timestamp);
CREATE INDEX IF NOT EXISTS idx_check_in_timestamps ON check_in_logs(check_in_time, check_out_time);

-- Create view for occupancy analytics
CREATE OR REPLACE VIEW occupancy_analytics AS
SELECT 
    date_trunc('hour', timestamp) AS hour,
    AVG(count) AS avg_occupancy,
    MAX(count) AS max_occupancy,
    MIN(count) AS min_occupancy,
    COUNT(*) AS data_points
FROM 
    occupancy_records
GROUP BY 
    date_trunc('hour', timestamp)
ORDER BY 
    hour DESC;

-- Create view for user attendance patterns
CREATE OR REPLACE VIEW user_attendance_patterns AS
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.membership_type,
    COUNT(cl.id) AS visit_count,
    AVG(cl.duration_minutes) AS avg_duration_minutes,
    MAX(cl.check_in_time) AS last_visit
FROM 
    users u
LEFT JOIN 
    check_in_logs cl ON u.id = cl.user_id
GROUP BY 
    u.id, u.first_name, u.last_name, u.membership_type
ORDER BY 
    last_visit DESC NULLS LAST;

-- Create function to automatically calculate duration upon checkout
CREATE OR REPLACE FUNCTION update_duration_on_checkout()
RETURNS TRIGGER AS $$
BEGIN
    NEW.duration_minutes = EXTRACT(EPOCH FROM (NEW.check_out_time - NEW.check_in_time))/60;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update duration
CREATE TRIGGER set_duration_on_checkout
BEFORE UPDATE ON check_in_logs
FOR EACH ROW
WHEN (OLD.check_out_time IS NULL AND NEW.check_out_time IS NOT NULL)
EXECUTE FUNCTION update_duration_on_checkout(); 