--
-- PostgreSQL database dump
--

-- Dumped from database version 14.6 (Debian 14.6-1.pgdg110+1)
-- Dumped by pg_dump version 15.2 (Ubuntu 15.2-1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: university_test; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE university_test WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE university_test OWNER TO postgres;

\connect university_test

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: users_book(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.users_book(end_date timestamp without time zone DEFAULT now()) RETURNS TABLE(user_id integer, user_name character varying, book_id integer, books_cnt integer)
    LANGUAGE sql
    AS $$
    SELECT
        users.id AS user_id
        , users.name AS user_name
        , library_history.book_id
        , sum(case when status = 'received' then 1 else 0 end) - sum(case when status = 'returned' then 1 else 0 end) AS books_cnt
    FROM library_history
    INNER JOIN books ON book_id = books.id
    RIGHT JOIN users ON users.id = library_history.user_id
    WHERE dt <= end_date OR dt IS NULL
    GROUP BY
        users.id, library_history.book_id
$$;


ALTER FUNCTION public.users_book(end_date timestamp without time zone) OWNER TO postgres;

--
-- Name: FUNCTION users_book(end_date timestamp without time zone); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.users_book(end_date timestamp without time zone) IS 'Список книг у пользователей';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: authors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authors (
    id integer NOT NULL,
    name character varying(100)
);


ALTER TABLE public.authors OWNER TO postgres;

--
-- Name: TABLE authors; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.authors IS 'Список авторов';


--
-- Name: authors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.authors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.authors_id_seq OWNER TO postgres;

--
-- Name: authors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.authors_id_seq OWNED BY public.authors.id;


--
-- Name: books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.books (
    id integer NOT NULL,
    author_id integer NOT NULL,
    name character varying(100),
    cnt integer DEFAULT 0 NOT NULL,
    CONSTRAINT books_cnt_check CHECK ((cnt >= 0))
);


ALTER TABLE public.books OWNER TO postgres;

--
-- Name: TABLE books; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.books IS 'Список книг';


--
-- Name: books_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.books_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.books_id_seq OWNER TO postgres;

--
-- Name: books_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.books_id_seq OWNED BY public.books.id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- Name: TABLE genres; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.genres IS 'Список жанров';


--
-- Name: genres_books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres_books (
    book_id integer NOT NULL,
    genre_id integer NOT NULL
);


ALTER TABLE public.genres_books OWNER TO postgres;

--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genres_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.genres_id_seq OWNER TO postgres;

--
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genres_id_seq OWNED BY public.genres.id;


--
-- Name: library_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.library_history (
    user_id integer NOT NULL,
    book_id integer NOT NULL,
    status character varying(100) NOT NULL,
    dt timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.library_history OWNER TO postgres;

--
-- Name: TABLE library_history; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.library_history IS 'История получений-возвратов книг';


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'Список пользователей';


--
-- Name: users_genres; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.users_genres AS
 SELECT users_book.user_name,
    genres.name AS genre_name,
    count(genres.id) FILTER (WHERE (genres_books.book_id IS NOT NULL)) AS books_cnt
   FROM ((public.users_book() users_book(user_id, user_name, book_id, books_cnt)
     CROSS JOIN public.genres)
     LEFT JOIN public.genres_books ON (((users_book.book_id = genres_books.book_id) AND (genres.id = genres_books.genre_id))))
  GROUP BY users_book.user_name, genres.name;


ALTER TABLE public.users_genres OWNER TO postgres;

--
-- Name: VIEW users_genres; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.users_genres IS 'Список жанров, которые читает пользователь';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: authors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors ALTER COLUMN id SET DEFAULT nextval('public.authors_id_seq'::regclass);


--
-- Name: books id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books ALTER COLUMN id SET DEFAULT nextval('public.books_id_seq'::regclass);


--
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genres_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: authors authors_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_name_key UNIQUE (name);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (id);


--
-- Name: genres_books genres_books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres_books
    ADD CONSTRAINT genres_books_pkey PRIMARY KEY (book_id, genre_id);


--
-- Name: genres genres_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: books books_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(id);


--
-- Name: genres_books genres_books_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres_books
    ADD CONSTRAINT genres_books_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(id);


--
-- Name: genres_books genres_books_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres_books
    ADD CONSTRAINT genres_books_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: library_history library_history_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library_history
    ADD CONSTRAINT library_history_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(id);


--
-- Name: library_history library_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library_history
    ADD CONSTRAINT library_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

