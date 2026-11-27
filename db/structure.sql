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

--
-- Name: ledger_entries_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ledger_entries_append_only() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'ledger_entries es solo inserción: use un movimiento de reverso';
END;
$$;


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
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id bigint NOT NULL,
    date date NOT NULL,
    name character varying NOT NULL,
    scope character varying DEFAULT 'national'::character varying NOT NULL,
    region character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;


--
-- Name: leave_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leave_grants (
    id bigint NOT NULL,
    employee_id bigint NOT NULL,
    leave_type_id bigint NOT NULL,
    grant_batch_id bigint,
    period character varying,
    granted_days numeric(6,2) NOT NULL,
    remaining_days numeric(6,2) NOT NULL,
    granted_on date NOT NULL,
    expires_on date,
    source character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT leave_grants_granted_positive CHECK ((granted_days > (0)::numeric)),
    CONSTRAINT leave_grants_remaining_lte_granted CHECK ((remaining_days <= granted_days)),
    CONSTRAINT leave_grants_remaining_non_negative CHECK ((remaining_days >= (0)::numeric))
);


--
-- Name: leave_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leave_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leave_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leave_grants_id_seq OWNED BY public.leave_grants.id;


--
-- Name: leave_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leave_periods (
    id bigint NOT NULL,
    employee_id bigint NOT NULL,
    approver_id bigint NOT NULL,
    pool character varying DEFAULT 'vacation'::character varying NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    business_days numeric(6,2) NOT NULL,
    approved_at timestamp(6) without time zone NOT NULL,
    status character varying DEFAULT 'requested'::character varying NOT NULL,
    note character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT leave_periods_dates_check CHECK ((end_date >= start_date)),
    CONSTRAINT leave_periods_status_check CHECK (((status)::text = ANY ((ARRAY['requested'::character varying, 'taken'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: leave_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leave_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leave_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leave_periods_id_seq OWNED BY public.leave_periods.id;


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
-- Name: ledger_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_entries (
    id bigint NOT NULL,
    leave_grant_id bigint NOT NULL,
    leave_period_id bigint,
    reverses_entry_id bigint,
    actor_id bigint,
    kind character varying NOT NULL,
    days numeric(6,2) NOT NULL,
    effective_on date NOT NULL,
    reason text NOT NULL,
    source character varying NOT NULL,
    idempotency_key character varying NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ledger_entries_days_non_zero CHECK ((days <> (0)::numeric)),
    CONSTRAINT ledger_entries_kind_check CHECK (((kind)::text = ANY ((ARRAY['grant'::character varying, 'usage'::character varying, 'expiration'::character varying, 'adjustment'::character varying, 'reversal'::character varying])::text[]))),
    CONSTRAINT ledger_entries_reversal_link CHECK ((((kind)::text = 'reversal'::text) = (reverses_entry_id IS NOT NULL)))
);


--
-- Name: ledger_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ledger_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ledger_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ledger_entries_id_seq OWNED BY public.ledger_entries.id;


--
-- Name: opening_balance_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opening_balance_imports (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    uploaded_by_id bigint NOT NULL,
    approved_by_id bigint,
    filename character varying NOT NULL,
    checksum character varying NOT NULL,
    cutoff_on date NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    approved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: opening_balance_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.opening_balance_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opening_balance_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.opening_balance_imports_id_seq OWNED BY public.opening_balance_imports.id;


--
-- Name: opening_balance_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opening_balance_rows (
    id bigint NOT NULL,
    opening_balance_import_id bigint NOT NULL,
    employee_id bigint,
    row_number integer NOT NULL,
    rut character varying NOT NULL,
    employee_name character varying,
    legal_days numeric(6,2) DEFAULT 0.0 NOT NULL,
    progressive_days numeric(6,2) DEFAULT 0.0 NOT NULL,
    administrative_days numeric(6,2) DEFAULT 0.0 NOT NULL,
    excel_total numeric(6,2),
    status character varying NOT NULL,
    messages text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: opening_balance_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.opening_balance_rows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opening_balance_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.opening_balance_rows_id_seq OWNED BY public.opening_balance_rows.id;


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_views (
    id bigint NOT NULL,
    visitor_id character varying NOT NULL,
    actor_id bigint,
    actor_role character varying,
    request_method character varying NOT NULL,
    path character varying NOT NULL,
    controller_action character varying NOT NULL,
    status integer NOT NULL,
    external boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: page_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.page_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.page_views_id_seq OWNED BY public.page_views.id;


--
-- Name: rule_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rule_versions (
    id bigint NOT NULL,
    country character varying DEFAULT 'CL'::character varying NOT NULL,
    rule_key character varying NOT NULL,
    strategy character varying NOT NULL,
    effective_from date NOT NULL,
    notes character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rule_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rule_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rule_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rule_versions_id_seq OWNED BY public.rule_versions.id;


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
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);


--
-- Name: leave_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_grants ALTER COLUMN id SET DEFAULT nextval('public.leave_grants_id_seq'::regclass);


--
-- Name: leave_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_periods ALTER COLUMN id SET DEFAULT nextval('public.leave_periods_id_seq'::regclass);


--
-- Name: leave_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types ALTER COLUMN id SET DEFAULT nextval('public.leave_types_id_seq'::regclass);


--
-- Name: ledger_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries ALTER COLUMN id SET DEFAULT nextval('public.ledger_entries_id_seq'::regclass);


--
-- Name: opening_balance_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_imports ALTER COLUMN id SET DEFAULT nextval('public.opening_balance_imports_id_seq'::regclass);


--
-- Name: opening_balance_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_rows ALTER COLUMN id SET DEFAULT nextval('public.opening_balance_rows_id_seq'::regclass);


--
-- Name: page_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views ALTER COLUMN id SET DEFAULT nextval('public.page_views_id_seq'::regclass);


--
-- Name: rule_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_versions ALTER COLUMN id SET DEFAULT nextval('public.rule_versions_id_seq'::regclass);


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
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: leave_grants leave_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_grants
    ADD CONSTRAINT leave_grants_pkey PRIMARY KEY (id);


--
-- Name: leave_periods leave_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_periods
    ADD CONSTRAINT leave_periods_pkey PRIMARY KEY (id);


--
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (id);


--
-- Name: ledger_entries ledger_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_pkey PRIMARY KEY (id);


--
-- Name: opening_balance_imports opening_balance_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_imports
    ADD CONSTRAINT opening_balance_imports_pkey PRIMARY KEY (id);


--
-- Name: opening_balance_rows opening_balance_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_rows
    ADD CONSTRAINT opening_balance_rows_pkey PRIMARY KEY (id);


--
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (id);


--
-- Name: rule_versions rule_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rule_versions
    ADD CONSTRAINT rule_versions_pkey PRIMARY KEY (id);


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
-- Name: index_holidays_on_date_and_scope_and_region; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_holidays_on_date_and_scope_and_region ON public.holidays USING btree (date, scope, region);


--
-- Name: index_leave_grants_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_grants_on_employee_id ON public.leave_grants USING btree (employee_id);


--
-- Name: index_leave_grants_on_employee_id_and_expires_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_grants_on_employee_id_and_expires_on ON public.leave_grants USING btree (employee_id, expires_on);


--
-- Name: index_leave_grants_on_grant_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_grants_on_grant_batch_id ON public.leave_grants USING btree (grant_batch_id);


--
-- Name: index_leave_grants_on_leave_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_grants_on_leave_type_id ON public.leave_grants USING btree (leave_type_id);


--
-- Name: index_leave_periods_on_approver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_periods_on_approver_id ON public.leave_periods USING btree (approver_id);


--
-- Name: index_leave_periods_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_periods_on_employee_id ON public.leave_periods USING btree (employee_id);


--
-- Name: index_leave_periods_on_employee_id_and_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_periods_on_employee_id_and_start_date ON public.leave_periods USING btree (employee_id, start_date);


--
-- Name: index_leave_types_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_leave_types_on_company_id ON public.leave_types USING btree (company_id);


--
-- Name: index_leave_types_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_leave_types_on_company_id_and_code ON public.leave_types USING btree (company_id, code);


--
-- Name: index_ledger_entries_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_actor_id ON public.ledger_entries USING btree (actor_id);


--
-- Name: index_ledger_entries_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ledger_entries_on_idempotency_key ON public.ledger_entries USING btree (idempotency_key);


--
-- Name: index_ledger_entries_on_leave_grant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_leave_grant_id ON public.ledger_entries USING btree (leave_grant_id);


--
-- Name: index_ledger_entries_on_leave_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_leave_period_id ON public.ledger_entries USING btree (leave_period_id);


--
-- Name: index_ledger_entries_on_reverses_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ledger_entries_on_reverses_entry_id ON public.ledger_entries USING btree (reverses_entry_id) WHERE (reverses_entry_id IS NOT NULL);


--
-- Name: index_opening_balance_imports_on_approved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opening_balance_imports_on_approved_by_id ON public.opening_balance_imports USING btree (approved_by_id);


--
-- Name: index_opening_balance_imports_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opening_balance_imports_on_company_id ON public.opening_balance_imports USING btree (company_id);


--
-- Name: index_opening_balance_imports_on_company_id_and_checksum; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_opening_balance_imports_on_company_id_and_checksum ON public.opening_balance_imports USING btree (company_id, checksum);


--
-- Name: index_opening_balance_imports_on_uploaded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opening_balance_imports_on_uploaded_by_id ON public.opening_balance_imports USING btree (uploaded_by_id);


--
-- Name: index_opening_balance_rows_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opening_balance_rows_on_employee_id ON public.opening_balance_rows USING btree (employee_id);


--
-- Name: index_opening_balance_rows_on_opening_balance_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opening_balance_rows_on_opening_balance_import_id ON public.opening_balance_rows USING btree (opening_balance_import_id);


--
-- Name: index_page_views_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_actor_id ON public.page_views USING btree (actor_id);


--
-- Name: index_page_views_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_created_at ON public.page_views USING btree (created_at);


--
-- Name: index_page_views_on_visitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_visitor_id ON public.page_views USING btree (visitor_id);


--
-- Name: index_rule_versions_on_country_and_rule_key_and_effective_from; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rule_versions_on_country_and_rule_key_and_effective_from ON public.rule_versions USING btree (country, rule_key, effective_from);


--
-- Name: ledger_entries ledger_entries_no_update_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ledger_entries_no_update_delete BEFORE DELETE OR UPDATE ON public.ledger_entries FOR EACH ROW EXECUTE FUNCTION public.ledger_entries_append_only();


--
-- Name: page_views fk_rails_044f66cba4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT fk_rails_044f66cba4 FOREIGN KEY (actor_id) REFERENCES public.employees(id);


--
-- Name: employees fk_rails_0fe1519b79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_rails_0fe1519b79 FOREIGN KEY (manager_id) REFERENCES public.employees(id);


--
-- Name: leave_grants fk_rails_141c6749ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_grants
    ADD CONSTRAINT fk_rails_141c6749ef FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(id);


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
-- Name: leave_grants fk_rails_38b49743f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_grants
    ADD CONSTRAINT fk_rails_38b49743f7 FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: leave_grants fk_rails_4150e73b2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_grants
    ADD CONSTRAINT fk_rails_4150e73b2d FOREIGN KEY (grant_batch_id) REFERENCES public.grant_batches(id);


--
-- Name: opening_balance_rows fk_rails_4f59997452; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_rows
    ADD CONSTRAINT fk_rails_4f59997452 FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: ledger_entries fk_rails_6048a9a2ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_6048a9a2ae FOREIGN KEY (leave_period_id) REFERENCES public.leave_periods(id);


--
-- Name: opening_balance_imports fk_rails_685b225e9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_imports
    ADD CONSTRAINT fk_rails_685b225e9c FOREIGN KEY (uploaded_by_id) REFERENCES public.employees(id);


--
-- Name: ledger_entries fk_rails_88500c2d56; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_88500c2d56 FOREIGN KEY (leave_grant_id) REFERENCES public.leave_grants(id);


--
-- Name: leave_periods fk_rails_8f6f730b5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_periods
    ADD CONSTRAINT fk_rails_8f6f730b5c FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: grant_batches fk_rails_b80b84412e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grant_batches
    ADD CONSTRAINT fk_rails_b80b84412e FOREIGN KEY (created_by_id) REFERENCES public.employees(id);


--
-- Name: ledger_entries fk_rails_c6647df8e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_c6647df8e2 FOREIGN KEY (reverses_entry_id) REFERENCES public.ledger_entries(id);


--
-- Name: opening_balance_imports fk_rails_ca9fb18f0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_imports
    ADD CONSTRAINT fk_rails_ca9fb18f0b FOREIGN KEY (company_id) REFERENCES public.companies(id);


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
-- Name: opening_balance_rows fk_rails_e286f69262; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_rows
    ADD CONSTRAINT fk_rails_e286f69262 FOREIGN KEY (opening_balance_import_id) REFERENCES public.opening_balance_imports(id);


--
-- Name: ledger_entries fk_rails_e6ab26e796; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_e6ab26e796 FOREIGN KEY (actor_id) REFERENCES public.employees(id);


--
-- Name: opening_balance_imports fk_rails_e9cbf12428; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opening_balance_imports
    ADD CONSTRAINT fk_rails_e9cbf12428 FOREIGN KEY (approved_by_id) REFERENCES public.employees(id);


--
-- Name: leave_periods fk_rails_ef6e1fa0ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_periods
    ADD CONSTRAINT fk_rails_ef6e1fa0ca FOREIGN KEY (approver_id) REFERENCES public.employees(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261127000001'),
('20261126000006'),
('20261126000005'),
('20261126000004'),
('20261126000003'),
('20261126000002'),
('20261126000001');

