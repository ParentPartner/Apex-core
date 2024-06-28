-- schema.sql

-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
    name VARCHAR(50) PRIMARY KEY,
    label VARCHAR(50) NOT NULL
);

-- Create users table with job, cash, and bank columns
CREATE TABLE IF NOT EXISTS users (
    identifier VARCHAR(50) PRIMARY KEY,
    posX FLOAT DEFAULT 0.0,
    posY FLOAT DEFAULT 0.0,
    posZ FLOAT DEFAULT 0.0,
    cash INT DEFAULT 0,
    bank INT DEFAULT 0,
    job VARCHAR(50),
    FOREIGN KEY (job) REFERENCES jobs(name)
);
