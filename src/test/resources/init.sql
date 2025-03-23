ALTER SYSTEM SET max_replication_slots = 5;
ALTER SYSTEM SET max_wal_senders = 5;
SELECT pg_reload_conf();

create table employee
(
    id    integer
        constraint employee_pk
            primary key,
    name  text,
    email text
);