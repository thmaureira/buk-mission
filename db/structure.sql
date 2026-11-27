SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name character varying NOT NULL,
    country character varying DEFAULT 'CL'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employees (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    manager_id bigint,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    rut character varying NOT NULL,
    email character varying,
    area character varying,
    job_title character varying,
    role character varying DEFAULT 'employee'::character varying NOT NULL,
    hire_date date NOT NULL,
    prior_service_months integer DEFAULT 0 NOT NULL,
    prior_service_document_ref character varying,
    ledger_opened_on date,
    terminated_on date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT employees_prior_service_check CHECK ((prior_service_months >= 0)),
    CONSTRAINT employees_role_check CHECK (((role)::text = ANY ((ARRAY['hr'::character varying, 'manager'::character varying, 'employee'::character varying])::text[])))
);


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- Name: grant_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grant_batches (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    leave_type_id bigint NOT NULL,
    created_by_id bigint NOT NULL,
    days numeric(6,2) NOT NULL,
    granted_on date NOT NULL,
    reason text NOT NULL,
    target_description character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: grant_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grant_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grant_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grant_batches_id_seq OWNED BY public.grant_batches.id;


--
-- Name: leave_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leave_types (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    pool character varying NOT NULL,
    grant_mode character varying DEFAULT 'manual'::character varying NOT NULL,
    expiration_policy character varying DEFAULT 'none'::character varying NOT NULL,
    expiration_value character varying,
    system boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 100 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT leave_types_expiration_policy_check CHECK (((expiration_policy)::text = ANY ((ARRAY['none'::character varying, 'fixed_date'::character varying, 'relative'::character varying])::text[]))),
    CONSTRAINT leave_types_grant_mode_check CHECK (((grant_mode)::text = ANY ((ARRAY['rule'::character varying, 'manual'::character varying])::text[])))
);


--
-- Name: leave_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leave_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leave_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leave_types_id_seq OWNED BY public.leave_types.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- Name: grant_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grant_batches ALTER COLUMN id SET DEFAULT nextval('public.grant_batches_id_seq'::regclass);


--
-- Name: leave_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types ALTER COLUMN id SET DEFAULT nextval('public.leave_types_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: grant_batches grant_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grant_batches
    ADD CONSTRAINT grant_batches_pkey PRIMARY KEY (id);


--
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_employees_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_company_id ON public.employees USING btree (company_id);


--
-- Name: index_employees_on_company_id_and_rut; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_employees_on_company_id_and_rut ON public.employees USING btree (company_id, rut);


--
-- Name: index_employees_on_manager_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_manager_id ON public.employees USING btree (manager_id);


--
-- Name: index_grant_batches_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grant_batches_on_company_id ON public.grant_batches USING btree (company_id);


--
-- Name: index_grant_batches_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grant_batches_on_created_by_id ON public.grant_batches USING btree (created_by_id);


--
-- Name: index_grant_batches_on_leave_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grant_batches_on_leave_type_id ON public.grant_batches USING btree (leave_type_id);


--
-- Name: index_leave_types_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_types_on_company_id ON public.leave_types USING btree (company_id);


--
-- Name: index_leave_types_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_leave_types_on_company_id_and_code ON public.leave_types USING btree (company_id, code);


--
-- Name: employees fk_rails_0fe1519b79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_rails_0fe1519b79 FOREIGN KEY (manager_id) REFERENCES public.employees(id);


--
-- Name: employees fk_rails_15ca1438d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_rails_15ca1438d5 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: grant_batches fk_rails_29d5d292ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grant_batches
    ADD CONSTRAINT fk_rails_29d5d292ee FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: grant_batches fk_rails_b80b84412e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grant_batches
    ADD CONSTRAINT fk_rails_b80b84412e FOREIGN KEY (created_by_id) REFERENCES public.employees(id);


--
-- Name: leave_types fk_rails_d0481bcf44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT fk_rails_d0481bcf44 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: grant_batches fk_rails_d4494317b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grant_batches
    ADD CONSTRAINT fk_rails_d4494317b7 FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261126000002'),
('20261126000001');

