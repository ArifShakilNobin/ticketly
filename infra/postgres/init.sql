-- Ticketly platform databases.
-- Mounted into /docker-entrypoint-initdb.d of the postgres container, so it only
-- runs on the very first start (empty data volume).
--
-- The `ticketly` role itself is created by POSTGRES_USER, so only the databases
-- are created here — and only when they do not exist yet.

\set ON_ERROR_STOP on

SELECT format('CREATE DATABASE %I OWNER ticketly', d.name)
FROM (VALUES
        ('ticketly'),
        ('ticketly_user'),
        ('ticketly_booking'),
        ('ticketly_offers')
     ) AS d(name)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = d.name
)
\gexec

-- Hibernate (ddl-auto=update) creates the schema itself. The owner of each
-- database is `ticketly`, so it is allowed to create tables directly.
