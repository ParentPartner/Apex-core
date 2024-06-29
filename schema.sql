-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL UNIQUE,
    posX FLOAT DEFAULT 0.0,
    posY FLOAT DEFAULT 0.0,
    posZ FLOAT DEFAULT 0.0,
    cash FLOAT DEFAULT 0.0,
    bank FLOAT DEFAULT 0.0,
    job VARCHAR(50),
    inventory JSON DEFAULT NULL,
    isAdmin BOOLEAN DEFAULT FALSE
);

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    label VARCHAR(50) NOT NULL
);

-- Initial job entries
INSERT INTO jobs (name, label) VALUES 
('unemployed', 'Unemployed'),
('police', 'Police Officer'),
('ambulance', 'EMS'),
('mechanic', 'Mechanic'),
('taxi', 'Taxi Driver');

-- Add admin field to users table if not exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS isAdmin BOOLEAN DEFAULT FALSE;
