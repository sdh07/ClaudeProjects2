#!/bin/bash
# Update context database with new tables for Day 3

set -e

CONTEXT_DB=".cpdm/context/contexts.db"

echo "Updating context database schema..."

# Add new tables and fields
sqlite3 "$CONTEXT_DB" <<'EOF'
-- Add compressed field to contexts
ALTER TABLE contexts ADD COLUMN compressed INTEGER DEFAULT 0;

-- Create context versions table
CREATE TABLE IF NOT EXISTS context_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    state TEXT NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id),
    UNIQUE(context_id, version)
);

-- Create index for versions
CREATE INDEX IF NOT EXISTS idx_versions_context ON context_versions(context_id);
CREATE INDEX IF NOT EXISTS idx_versions_created ON context_versions(created_at);

-- Add fields for better tracking  
ALTER TABLE contexts ADD COLUMN compressed_size INTEGER DEFAULT 0;
ALTER TABLE contexts ADD COLUMN last_accessed TIMESTAMP;
ALTER TABLE contexts ADD COLUMN access_count INTEGER DEFAULT 0;

-- Update existing rows
UPDATE contexts SET last_accessed = CURRENT_TIMESTAMP WHERE last_accessed IS NULL;

-- Create context relationships table
CREATE TABLE IF NOT EXISTS context_relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_context_id TEXT NOT NULL,
    child_context_id TEXT NOT NULL,
    relationship_type TEXT DEFAULT 'parent-child',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_context_id) REFERENCES contexts(id),
    FOREIGN KEY (child_context_id) REFERENCES contexts(id),
    UNIQUE(parent_context_id, child_context_id)
);

-- Create context locks table for concurrency
CREATE TABLE IF NOT EXISTS context_locks (
    context_id TEXT PRIMARY KEY,
    locked_by TEXT NOT NULL,
    locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id)
);

-- Update trigger for last_accessed
CREATE TRIGGER IF NOT EXISTS update_context_access
    AFTER UPDATE ON contexts
    FOR EACH ROW
    WHEN OLD.state != NEW.state
    BEGIN
        UPDATE contexts 
        SET last_accessed = CURRENT_TIMESTAMP,
            access_count = access_count + 1
        WHERE id = NEW.id;
    END;

-- Verify new schema
SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;
EOF

echo "Database schema updated successfully!"