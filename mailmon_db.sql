--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 9.6.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: mailbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mailbox (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    address character varying(100) NOT NULL,
    password character varying(100) NOT NULL,
    server character varying(100) NOT NULL,
    port integer DEFAULT 143 NOT NULL,
    use_tls boolean DEFAULT false NOT NULL,
    last_uid integer DEFAULT 0 NOT NULL
);


--
-- Name: schedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schedule (
    id integer NOT NULL,
    run_from time without time zone NOT NULL,
    run_to time without time zone NOT NULL,
    sender_regex character varying(100),
    subject_regex character varying(100),
    mailbox_id integer NOT NULL,
    sound_id integer NOT NULL,
    CONSTRAINT ck_schedule_times CHECK ((run_to > run_from))
);


--
-- Name: sound; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sound (
    id integer NOT NULL,
    type character varying(10) NOT NULL,
    text character varying(1000) NOT NULL,
    CONSTRAINT sound_type_check CHECK ((lower((type)::text) = ANY (ARRAY['file'::text, 'speech'::text])))
);


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE system_config (
    name character varying(50) NOT NULL,
    string_value character varying(1000),
    int_value integer,
    timestamp_value timestamp without time zone
);


--
-- Name: mailbox pk_mailbox; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mailbox
    ADD CONSTRAINT pk_mailbox PRIMARY KEY (id);


--
-- Name: schedule pk_schedule; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT pk_schedule PRIMARY KEY (id);


--
-- Name: sound pk_sound; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sound
    ADD CONSTRAINT pk_sound PRIMARY KEY (id);


--
-- Name: system_config pk_system_config; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY system_config
    ADD CONSTRAINT pk_system_config PRIMARY KEY (name);


--
-- Name: ak_mailbox; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ak_mailbox ON mailbox USING btree (lower((name)::text));


--
-- Name: schedule fk_schedule_mailbox; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT fk_schedule_mailbox FOREIGN KEY (mailbox_id) REFERENCES mailbox(id);


--
-- Name: schedule fk_schedule_sound; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT fk_schedule_sound FOREIGN KEY (sound_id) REFERENCES sound(id);


--
-- Name: mailbox; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,UPDATE ON TABLE mailbox TO PUBLIC;


--
-- Name: schedule; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE schedule TO PUBLIC;


--
-- Name: sound; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE sound TO PUBLIC;


--
-- Name: system_config; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE system_config TO PUBLIC;


--
-- PostgreSQL database dump complete
--

