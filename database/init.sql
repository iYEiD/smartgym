-- Initialize database schema for Smart Gym AI application

-- Users table for storing gym members
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    rfid_id VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    membership_type VARCHAR(50) NOT NULL,
    last_check_in TIMESTAMP,
    last_check_out TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Check-in logs for tracking gym entry/exit
CREATE TABLE IF NOT EXISTS check_in_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_in_time TIMESTAMP NOT NULL,
    check_out_time TIMESTAMP,
    duration_minutes INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Occupancy records for monitoring gym capacity
CREATE TABLE IF NOT EXISTS occupancy_records (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    current_count INTEGER NOT NULL,
    max_capacity INTEGER NOT NULL,
    occupancy_percentage DECIMAL(5,2) NOT NULL
);

-- Sensor data for environmental monitoring
CREATE TABLE IF NOT EXISTS sensor_data (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(100) NOT NULL,
    sensor_type VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Parking spots availability
CREATE TABLE IF NOT EXISTS parking_spots (
    id SERIAL PRIMARY KEY,
    spot_id VARCHAR(50) NOT NULL,
    is_occupied BOOLEAN NOT NULL DEFAULT FALSE,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_rfid ON users(rfid_id);
CREATE INDEX IF NOT EXISTS idx_check_in_logs_user_id ON check_in_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_check_in_logs_time ON check_in_logs(check_in_time, check_out_time);
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_sensor_data_type ON sensor_data(sensor_type);
CREATE INDEX IF NOT EXISTS idx_occupancy_timestamp ON occupancy_records(timestamp);

-- Insert sample data for testing
INSERT INTO users (rfid_id, first_name, last_name, email, phone, membership_type)
VALUES 
    ('A12345', 'John', 'Doe', 'john.doe@example.com', '555-123-4567', 'Premium'),
    ('B67890', 'Jane', 'Smith', 'jane.smith@example.com', '555-987-6543', 'Standard'),
    ('C13579', 'Mike', 'Johnson', 'mike.j@example.com', '555-246-8024', 'Basic'),
    ('D24680', 'Sarah', 'Williams', 'sarah.w@example.com', '555-369-1470', 'Premium'),
    ('E35791', 'Robert', 'Brown', 'robert.b@example.com', '555-159-7531', 'Standard');

-- Insert sample occupancy records
INSERT INTO occupancy_records (timestamp, current_count, max_capacity, occupancy_percentage)
VALUES 
    (NOW() - INTERVAL '3 HOUR', 15, 50, 30.00),
    (NOW() - INTERVAL '2 HOUR', 25, 50, 50.00),
    (NOW() - INTERVAL '1 HOUR', 35, 50, 70.00),
    (NOW(), 20, 50, 40.00);

-- Insert sample sensor data
INSERT INTO sensor_data (sensor_id, sensor_type, value, unit, timestamp)
VALUES
    ('temp_sensor_1', 'temperature', 23.5, '°C', NOW() - INTERVAL '30 MINUTE'),
    ('temp_sensor_1', 'temperature', 24.0, '°C', NOW() - INTERVAL '15 MINUTE'),
    ('temp_sensor_1', 'temperature', 24.2, '°C', NOW()),
    ('humidity_sensor_1', 'humidity', 45.0, '%', NOW() - INTERVAL '30 MINUTE'),
    ('humidity_sensor_1', 'humidity', 46.5, '%', NOW() - INTERVAL '15 MINUTE'),
    ('humidity_sensor_1', 'humidity', 47.0, '%', NOW()),
    ('light_sensor_1', 'light', 450, 'lux', NOW() - INTERVAL '30 MINUTE'),
    ('light_sensor_1', 'light', 470, 'lux', NOW() - INTERVAL '15 MINUTE'),
    ('light_sensor_1', 'light', 485, 'lux', NOW()),
    ('motion_sensor_1', 'motion', 1, 'boolean', NOW() - INTERVAL '25 MINUTE'),
    ('motion_sensor_1', 'motion', 0, 'boolean', NOW() - INTERVAL '10 MINUTE'),
    ('motion_sensor_1', 'motion', 1, 'boolean', NOW() - INTERVAL '5 MINUTE');

-- Insert sample parking data
INSERT INTO parking_spots (spot_id, is_occupied, last_updated)
VALUES
    ('P001', true, NOW() - INTERVAL '45 MINUTE'),
    ('P002', false, NOW() - INTERVAL '30 MINUTE'),
    ('P003', true, NOW() - INTERVAL '20 MINUTE'),
    ('P004', true, NOW() - INTERVAL '15 MINUTE'),
    ('P005', false, NOW() - INTERVAL '10 MINUTE'),
    ('P006', false, NOW() - INTERVAL '5 MINUTE'),
    ('P007', true, NOW() - INTERVAL '2 MINUTE'),
    ('P008', false, NOW()); 