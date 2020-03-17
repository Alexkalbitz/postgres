-- Create Tables
CREATE TABLE "user"
(
    "id"         SERIAL PRIMARY KEY,
    "email"      TEXT NOT NULL,
    "first_name" TEXT NOT NULL,
    "last_name"  TEXT NOT NULL
);

CREATE TABLE "address"
(
    "id"           SERIAL PRIMARY KEY,
    "street"       TEXT NOT NULL,
    "house_number" TEXT NOT NULL,
    "user_id"      INT  NOT NULL
);

-- Inserting data
INSERT INTO "user"
    ("email", "first_name", "last_name")
    VALUES
    ('pascal.ludwig@mantro.net', 'Pascal', 'Ludwig'),
    ('atot@mantro.net', 'Alexander', 'Tot'),
    ('bschuedzig@mantro.net', 'Benjamin', 'Schüdzig');

INSERT INTO "address"
    ("street", "house_number", "user_id")
    VALUES
    ('Zielstattstraße', '19', 1),
    ('Marienplatz', '1', 2),
    ('Marienplatz', '19', 2);

-- Reading data
SELECT * FROM "user";

SELECT * FROM "address";

-- Reading data with conditionals
SELECT
    "street",
    "house_number"
FROM "address"
WHERE "street" = 'Marienplatz'
    AND "house_number" = '19';

-- Sorting data
SELECT *
FROM "address"
ORDER BY "street" ASC, "house_number" DESC;

-- Limit & Offset
SELECT *
FROM "address"
ORDER BY "street" ASC, "house_number" DESC
LIMIT 1 OFFSET 2;

-- Functions
SELECT
    LOWER("u"."email") "email",
    UPPER("u"."first_name") "first_name",
    UPPER("u"."last_name") "last_name"
FROM "user" AS "u";

-- Joining Tables (INNER JOIN)
SELECT "u"."email", "a".*
FROM "user" AS "u"
INNER JOIN "address" AS "a" ON "a"."user_id" = "u"."id";

-- Joining Tables (LEFT JOIN)
SELECT "u"."email", "a".*
FROM "user" AS "u"
LEFT JOIN "address" AS "a" ON "a"."user_id" = "u"."id";

-- Aggregating data
SELECT "u"."email", count("a"."id") AS "address_count"
FROM "user" AS "u"
LEFT JOIN "address" AS "a" ON "a"."user_id" = "u"."id"
GROUP BY "u"."id"
ORDER BY count("a"."id") ASC;

-- Updating data
UPDATE "user" SET "email" = 'bschuedzig@mantro.net'
WHERE "email" = 'benjamin.schuedzig@mantro.net';

SELECT "email" FROM "user";

-- Deleting data
DELETE FROM "user" WHERE "email" = 'pascal.ludwig@mantro.net';

DROP TABLE "user";
DROP TABLE "address";

-- Foreign key constraint
ALTER TABLE "address"
    ADD CONSTRAINT "fk_address_user"
    FOREIGN KEY ("user_id") REFERENCES "user" ("id");

-- Foreign key violation on insert row
INSERT INTO "address" ("street", "house_number", "user_id") VALUES ('a', 'b', 99)

-- Foreign key violation on delete row
DELETE FROM "user" WHERE "email" = 'pascal.ludwig@mantro.net';

-- Foreign key violation on drop table
DROP TABLE "user";

-- Cascading Foreign Key Constraint (DELETE)
ALTER TABLE "address"
    ADD CONSTRAINT "fk_address_user" FOREIGN KEY ("user_id")
    REFERENCES "user" ("id") ON DELETE CASCADE;

SELECT * FROM "address";
DELETE FROM "user" WHERE "id" = 1;
SELECT * FROM "address";

-- Cascading Foreign Key Constraint (UPDATE)
ALTER TABLE "address"
    ADD CONSTRAINT "fk_address_user" FOREIGN KEY ("user_id")
    REFERENCES "user" ("id") ON UPDATE CASCADE;

SELECT * FROM "address";
UPDATE "user" SET "id" = 123 WHERE "id" = 1;
SELECT * FROM "address";

-- Unique Index
CREATE UNIQUE INDEX "uq_user_email" ON "user" (TRIM(LOWER("email")));

-- Unique index violation
INSERT INTO "user" ("email", "first_name", "last_name")
    VALUES ('PASCAL.LUDWIG@mantro.NeT', 'a', 'b');

-- Check constraint
ALTER TABLE "user"
    ADD CONSTRAINT "ck_user_email"
    CHECK ( "email" ILIKE '%@%.%' );

-- Check violation on insert
INSERT INTO "user" ("email", "first_name", "last_name")
VALUES ('invalid', 'a','b');

-- Transactions (Adding "balance" to user)
ALTER TABLE "user"
    ADD COLUMN "balance" INT DEFAULT 0;

UPDATE "user"
SET "balance" = 1000;

-- Transaction
BEGIN;
SELECT "balance" >= 100 AS "has_balance" FROM "user" WHERE "id" = 1;
-- Application aborts if "has_balance" is false or null
UPDATE "user" SET "balance" = "balance" - 100 WHERE "id" = 1;
UPDATE "user" SET "balance" = "balance" + 100 WHERE "id" = 2;
COMMIT;

-- Transaction with explicit locking
SELECT "balance" >= 100 AS "has_balance" FROM "user" WHERE "id" = 1 FOR UPDATE;
-- Application aborts if "has_balance" is false or null
SELECT FROM "user" WHERE "id" = 2 FOR UPDATE;
UPDATE "user" SET "balance" = "balance" - 100 WHERE "id" = 1;
UPDATE "user" SET "balance" = "balance" + 100 WHERE "id" = 2;

-- Subquery in WHERE clause
SELECT *
FROM "actor" "a"
WHERE (
    SELECT count(*)
    FROM "film_actor" "fa"
    WHERE "fa"."actor_id" = "a"."actor_id"
) > 40;

-- Subquery in SELECT clause
SELECT
    (SELECT count(*) FROM "actor") AS "num_actors",
    (SELECT count(*) FROM "film") AS "num_films",
    (SELECT count(*) FROM "film")
        / (SELECT count(*) FROM "actor") AS "avg_films_per_actor";

-- Subquery in FROM clause
SELECT *
FROM (
     SELECT *
     FROM "customer"
     ORDER BY "create_date" ASC
     LIMIT 3
) AS "top_customers"
ORDER BY "top_customers"."last_name" ASC, "top_customers"."first_name" ASC;

-- Analyzing Queries
EXPLAIN ANALYZE
SELECT * FROM "film"
WHERE "title" ILIKE '%karate%';

-- Analyzing Queries with an index
EXPLAIN ANALYZE
SELECT * FROM "film"
WHERE "film_id" = 201;

-- Adding a full-text index

CREATE EXTENSION pg_trgm;
CREATE INDEX idx_trgm_film_title ON "film" USING gin ("title" gin_trgm_ops);

EXPLAIN ANALYZE
SELECT * FROM "film"
WHERE "title" ILIKE '%karate%';

-- Using an index for sorting
EXPLAIN ANALYZE SELECT * FROM "film" ORDER BY "release_year";

CREATE INDEX "idx_film_relese_year" ON "film" ("release_year");

-- Stored Procedures / Functions / Routines
CREATE FUNCTION is_film_available_in_german(
    "_film_id" INT
) RETURNS BOOLEAN AS $$
DECLARE
    "_film" RECORD;
BEGIN
    SELECT *
    INTO STRICT "_film"
    FROM "film"
    WHERE "film_id" = "_film_id";

    IF "_film"."length" > 100 THEN
        RAISE WARNING 'Film is pretty long!';
    END IF;

    IF "_film"."length" > 130 THEN
        RAISE EXCEPTION 'Film is too long!';
    END IF;

    RETURN "_film"."language_id" = (
        SELECT "language_id"
        FROM "language"
        WHERE "name" = 'German'
    );
END;
$$ LANGUAGE PLPGSQL;

-- Print Warning
SELECT "is_film_available_in_german"(5);

-- Throw Error
SELECT "is_film_available_in_german"(5);

-- Triggers

CREATE OR REPLACE FUNCTION "tfn_before_customer_upsert"()
   RETURNS trigger AS $$
BEGIN
    NEW."email" = LOWER(TRIM(NEW."email"));
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER "trg_before_customer_insert"
    BEFORE INSERT ON "customer"
    FOR EACH ROW EXECUTE PROCEDURE "tfn_before_customer_upsert"();

CREATE TRIGGER "trg_before_customer_update"
    BEFORE UPDATE ON "customer"
    FOR EACH ROW EXECUTE PROCEDURE "tfn_before_customer_upsert"();

INSERT INTO "customer"
    ("store_id", "first_name", "last_name", "email", "address_id", "activebool", "create_date")
    VALUES
    (1, 'a', 'b', 'PASCAL.LUDWIG@manTRO.NeT', 1, true, NOW());

SELECT "email" FROM "customer" ORDER BY "create_date" DESC LIMIT 1;
