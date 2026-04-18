INSERT INTO demo_notes(title)
SELECT 'hello-sqlite'
WHERE NOT EXISTS (SELECT 1 FROM demo_notes WHERE title = 'hello-sqlite');

INSERT INTO demo_notes(title)
SELECT 'second-note'
WHERE NOT EXISTS (SELECT 1 FROM demo_notes WHERE title = 'second-note');

INSERT INTO demo_users(name)
SELECT 'sam'
WHERE NOT EXISTS (SELECT 1 FROM demo_users WHERE name = 'sam');

INSERT INTO demo_users(name)
SELECT 'poe'
WHERE NOT EXISTS (SELECT 1 FROM demo_users WHERE name = 'poe');
