-- PostgreSQL Production Schema Migration Script for Nashik Kumbh Mela System
-- Execution Target: AWS RDS / Neon / Supabase / CockroachDB

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'PUBLIC',
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS places (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    opening_hours VARCHAR(100),
    image_url TEXT,
    crowd_level VARCHAR(50) DEFAULT 'LOW',
    is_verified INTEGER DEFAULT 1,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    organizer VARCHAR(255),
    is_verified INTEGER DEFAULT 1,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    priority VARCHAR(50) DEFAULT 'NORMAL',
    category VARCHAR(100) DEFAULT 'GENERAL',
    target_group VARCHAR(100) DEFAULT 'ALL',
    published_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by INTEGER REFERENCES users(id),
    source_name VARCHAR(255) DEFAULT 'Kumbh Disaster Control Command',
    version INTEGER DEFAULT 1,
    status VARCHAR(50) DEFAULT 'PUBLISHED'
);

CREATE TABLE IF NOT EXISTS sync_changes (
    version BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(100) NOT NULL,
    entity_id INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    payload JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS external_sources (
    id SERIAL PRIMARY KEY,
    source_url TEXT NOT NULL,
    source_name VARCHAR(255) NOT NULL,
    trust_category VARCHAR(100) NOT NULL,
    content_hash VARCHAR(64),
    fetched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_verified_at TIMESTAMP WITH TIME ZONE,
    provenance_metadata JSONB,
    verification_status VARCHAR(50) DEFAULT 'PENDING_HUMAN_APPROVAL'
);

CREATE TABLE IF NOT EXISTS sos_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    device_id VARCHAR(255) NOT NULL,
    contact_name VARCHAR(150),
    contact_phone VARCHAR(20) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_address TEXT,
    status VARCHAR(50) DEFAULT 'CREATED',
    emergency_type VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    remarks TEXT,
    assigned_to_user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    token TEXT UNIQUE NOT NULL,
    platform VARCHAR(20) DEFAULT 'ANDROID',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parking_facilities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    total_capacity INTEGER NOT NULL,
    live_available_spaces INTEGER,
    availability_status VARCHAR(50) DEFAULT 'LIVE_UNAVAILABLE',
    vehicle_type VARCHAR(50) DEFAULT 'ALL',
    operating_hours VARCHAR(100) DEFAULT '24/7',
    is_accessible INTEGER DEFAULT 1,
    source_name VARCHAR(255) DEFAULT 'Nashik Municipal Transport',
    is_verified INTEGER DEFAULT 1,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexing Strategy for High-Performance Queries & Incremental Sync
CREATE INDEX IF NOT EXISTS idx_sync_changes_version ON sync_changes(version);
CREATE INDEX IF NOT EXISTS idx_announcements_status_priority ON announcements(status, priority, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_requests_status ON sos_requests(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_places_category ON places(category);
