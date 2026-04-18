CREATE TABLE IF NOT EXISTS demo_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS demo_users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS poems (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL CHECK (LENGTH(content) <= 2000),
  normalized_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,
  publish_day TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_poems_publish_day ON poems(publish_day);
CREATE INDEX IF NOT EXISTS idx_poems_created_at ON poems(created_at);
CREATE INDEX IF NOT EXISTS idx_poems_normalized_hash ON poems(normalized_hash);
