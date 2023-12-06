

-- +goose Up
-- +goose StatementBegin
-- CREATE SEQUENCE "worklogs_ID_seq"
--     INCREMENT 1
--     START 1
--     MINVALUE 1
--     MAXVALUE 2147483647
--     CACHE 1;


CREATE TABLE IF NOT EXISTS worklogs (
    Date         DATE,
    TicketID     TEXT,
    summary      TEXT,
    assignee     TEXT,
    timespent    INT,
    status       TEXT,
    components   TEXT,
    fixversions  TEXT,
    PRIMARY KEY  (Date,TicketID)
);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
SELECT 'DROP TABLE public.worklogs';
-- +goose StatementEnd
