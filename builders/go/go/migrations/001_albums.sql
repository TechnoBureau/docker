
-- +goose Up
-- +goose StatementBegin
CREATE SEQUENCE "ALBUMS_ID_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

-- Now, create the table using the sequence as the default value for the "id" column
CREATE TABLE public.albums (
    id int4 NOT NULL DEFAULT nextval('"ALBUMS_ID_seq"'::regclass),
    title varchar(100) NOT NULL,
    artist varchar(100) NOT NULL,
    price numeric(10) NOT NULL,
    CONSTRAINT "ALBUMS_pkey" PRIMARY KEY (id)
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
SELECT 'DROP TABLE public.albums';
-- +goose StatementEnd
