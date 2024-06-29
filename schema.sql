CREATE TABLE IF NOT EXISTS users (
    identifier VARCHAR(50) PRIMARY KEY,
    cash INT DEFAULT 0,
    bank INT DEFAULT 0,
    posX FLOAT DEFAULT 0,
    posY FLOAT DEFAULT 0,
    posZ FLOAT DEFAULT 0,
    job VARCHAR(50) DEFAULT NULL,
    inventory JSON DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS jobs (
    name VARCHAR(50) PRIMARY KEY,
    label VARCHAR(50) NOT NULL
);
