-- /packages/intranet-search-pg/sql/postgresql/intranet-search-pg-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- https://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Load tsearch2.sql from postgresql/share/contrib
-- This command may fail in Linux/Unix distributions
-- different from Debian Woody and SuSE 9.2.
-- In these cases please source the file manually and
-- remove the line from this file for a local install.

-- "Abbreviation" of object_type for search purposes -
-- we don't want to add a varchar(100) to the main search
-- table...
--
create table im_search_object_types (
	object_type_id	integer
			constraint im_search_object_types_pk
			primary key,
	object_type	varchar(100)
			constraint im_search_object_types_object_type_fk
			references acs_object_types
			on delete cascade,
			-- Relative weight of the object type.
			-- Highly relevant types with few objectys
			-- (companies, users) should get a very high
			-- weight (max. 10), while files should have
			-- low weights (min. 0.1)
	rel_weight	numeric(5,2) default 1
);


-- 0 | im_project	| 1
-- 1 | user		| 5
-- 2 | im_forum_topic	| 0.5
-- 3 | im_company	| 10
-- 4 | im_invoice	| 1
-- 5 | emails (in CR)	| 0.2
-- 6 | im_fs_files	| 0.1
-- 7 | content_item	| 0.5
-- 8 | im_ticket	| 0.7
-- 9 | im_conf_item	| 0.8
--10 | im_event		| 0.6
--11 | im_budget_item	| 0.9


-- Create "default" configuration
CREATE TEXT SEARCH CONFIGURATION public.default (COPY = pg_catalog.english);


-- The main search table with Full Text Index.
--
create table im_search_objects (
	object_id		integer,
				-- may include "object types" outside of OpenACS
				-- that are not in the "acs_object_types" table.
	object_type_id		integer
				constraint im_search_objects_object_type_id_fk
				references im_search_object_types
				on delete cascade,
				-- What is the topmost container for this object?
				-- Allows to speed up the elimination of objects
				-- that the current user can't access
	biz_object_id		integer
				constraint im_search_objects_biz_obj_id_fk
				references acs_objects
				on delete cascade,
				-- Owner may not need to be a "user" (in the case
				-- of a deleted user). Owners can be asked to give
				-- permissions to a document even if the document
				-- is not readable for the searching user.
	owner_id		integer
				constraint im_search_objects_owner_id_fk
				references persons
				on delete cascade,
				-- Bitset with one bit for each "profile":
				-- We use an integer instead of a "bit varying"
				-- in order to keep the set compatible with Oracle.
				-- A set bit indicates that object is readable to
				-- members of the profile independent of the 
				-- biz_object_id permissions.
	profile_permissions	integer,
				-- counter for number of accesses to this object
				-- either from the permission() proc or from
				-- reading in the server log file.
	popularity		integer,
				-- Full Text Index
	fti			tsvector,
				-- For tables that don't respect the OpenACS object 
				-- scheme we may get "object_id"s that start with 0.
	primary key (object_id, object_type_id)
);

create index im_search_objects_fti_idx on im_search_objects using gist(fti);
create index im_search_objects_object_id_idx on im_search_objects (object_id);


-- Normalize text by replacing UTF-8 encoded accents and other
-- "strange" characters by standard ASCII characters.
--
create or replace function norm_text_utf8 (varchar)
returns varchar as $$
declare
	p_str		alias for $1;
	p_str1		varchar;
	v_str		varchar;
	v_len		integer;
	v_asc		integer;
	v_char		varchar;
	v_i		integer;
	v_array		integer;
	v_found		integer;
	r		integer[77][3];
begin

--		{197,145,111},	-- ?
--		{197,177,117},	-- ?
--		{197,179,117},	-- ?
--		{196,159,103},	-- LATIN SMALL LETTER G WITH BREVE
--		{196,155,101},	-- LATIN SMALL LETTER E WITH CARON
--		{195,135,99},	-- LATIN CAPITAL LETTER C WITH CEDILLA
--		{195,188,117},	-- LATIN SMALL LETTER U WITH DIAERESIS
--		{195,169,101},	-- LATIN SMALL LETTER E WITH ACUTE
--		{195,162,97},	-- LATIN SMALL LETTER A WITH CIRCUMFLEX
--		{195,164,97},	-- LATIN SMALL LETTER A WITH DIAERESIS
--		{195,160,97},	-- LATIN SMALL LETTER A WITH GRAVE
--		{195,165,97},	-- LATIN SMALL LETTER A WITH RING ABOVE
--		{195,167,99},	-- LATIN SMALL LETTER C WITH CEDILLA
--		{195,170,101},	-- LATIN SMALL LETTER E WITH CIRCUMFLEX
--		{195,171,101},	-- LATIN SMALL LETTER E WITH DIAERESIS
--		{195,168,101},	-- LATIN SMALL LETTER E WITH GRAVE
--		{195,175,105},	-- LATIN SMALL LETTER I WITH DIAERESIS
--		{195,174,105},	-- LATIN SMALL LETTER I WITH CIRCUMFLEX
--		{195,172,105},	-- LATIN SMALL LETTER I WITH GRAVE
--		{195,132,97},	-- LATIN CAPITAL LETTER A WITH DIAERESIS
--		{195,133,97},	-- LATIN CAPITAL LETTER A WITH RING ABOVE
--		{195,137,101},	-- LATIN CAPITAL LETTER E WITH ACUTE
--		{195,180,111},	-- LATIN SMALL LETTER O WITH CIRCUMFLEX
--		{195,182,111},	-- LATIN SMALL LETTER O WITH DIAERESIS
--		{195,178,111},	-- LATIN SMALL LETTER O WITH GRAVE
--		{195,187,117},	-- LATIN SMALL LETTER U WITH CIRCUMFLEX
--		{195,185,117},	-- LATIN SMALL LETTER U WITH GRAVE
--		{195,191,121},	-- LATIN SMALL LETTER Y WITH DIAERESIS
--		{195,150,111},	-- LATIN CAPITAL LETTER O WITH DIAERESIS
--		{195,156,117},	-- LATIN CAPITAL LETTER U WITH DIAERESIS
--		{197,165,116},	-- LATIN SMALL LETTER T WITH CARON
--		{197,159,115},	-- LATIN SMALL LETTER S WITH CEDILLA
--		{197,175,117},	-- LATIN SMALL LETTER U WITH RING ABOVE
--		{197,174,117},	-- LATIN CAPITAL LETTER U WITH RING ABOVE
--		{195,161,97},	-- LATIN SMALL LETTER A WITH ACUTE
--		{195,173,105},	-- LATIN SMALL LETTER I WITH ACUTE
--		{195,179,111},	-- LATIN SMALL LETTER O WITH ACUTE
--		{195,186,117},	-- LATIN SMALL LETTER U WITH ACUTE
--		{195,177,110},	-- LATIN SMALL LETTER N WITH TILDE
--		{195,145,110},	-- LATIN CAPITAL LETTER N WITH TILDE
--		{196,140,99},	-- LATIN CAPITAL LETTER C WITH CARON
--		{196,141,99},	-- LATIN SMALL LETTER C WITH CARON
--		{197,153,114},	-- LATIN SMALL LETTER R WITH CARON
--		{197,152,114},	-- LATIN CAPITAL LETTER R WITH CARON
--		{197,160,115},	-- LATIN CAPITAL LETTER S WITH CARON
--		{197,161,115},	-- LATIN SMALL LETTER S WITH CARON
--		{195,189,121},	-- LATIN SMALL LETTER Y WITH ACUTE
--		{197,189,122},	-- LATIN CAPITAL LETTER Z WITH CARON
--		{197,190,122},	-- LATIN SMALL LETTER Z WITH CARON
--		{196,177,105},	-- LATIN SMALL LETTER DOTLESS I
--		{195,152,111},	-- LATIN CAPITAL LETTER O WITH STROKE
--		{206,177,97},	-- GREEK SMALL LETTER ALPHA
--		{195,159,115},	-- LATIN SMALL LETTER SHARP S
--		{206,147,103},	-- GREEK CAPITAL LETTER GAMMA
--		{207,128,112},	-- GREEK SMALL LETTER PI
--		{196,131,97},	-- LATIN SMALL LETTER A WITH BREVE
--		{207,131,115},	-- GREEK SMALL LETTER SIGMA
--		{206,179,103},	-- GREEK SMALL LETTER GAMMA
--		{196,176,105},	-- LATIN CAPITAL LETTER I WITH DOT ABOVE
--		{197,163,116},	-- LATIN SMALL LETTER T WITH CEDILLA
--		{206,180,100},	-- GREEK SMALL LETTER DELTA
--		{195,184,111},	-- LATIN SMALL LETTER O WITH STROKE
--		{196,133,97},	-- LATIN SMALL LETTER A WITH OGONEK
--		{196,153,101},	-- LATIN SMALL LETTER E WITH OGONEK
--		{196,134,99},	-- LATIN CAPITAL LETTER C WITH ACUTE
--		{196,135,99},	-- LATIN SMALL LETTER C WITH ACUTE
--		{197,129,108},	-- LATIN CAPITAL LETTER L WITH STROKE
--		{197,130,108},	-- LATIN SMALL LETTER L WITH STROKE
--		{197,131,110},	-- LATIN CAPITAL LETTER N WITH ACUTE
--		{197,132,110},	-- LATIN SMALL LETTER N WITH ACUTE
--		{195,147,111},	-- LATIN CAPITAL LETTER O WITH ACUTE
--		{197,154,115},	-- LATIN CAPITAL LETTER S WITH ACUTE
--		{197,155,115},	-- LATIN SMALL LETTER S WITH ACUTE
--		{197,185,122},	-- LATIN CAPITAL LETTER Z WITH ACUTE
--		{197,186,122},	-- LATIN SMALL LETTER Z WITH ACUTE
--		{197,187,122},	-- LATIN CAPITAL LETTER Z WITH DOT ABOVE
--		{197,188,122}	-- LATIN SMALL LETTER Z WITH DOT ABOVE


	r := '{
		{197,145,111},
		{197,177,117},
		{197,179,117},
		{196,159,103},
		{196,155,101},
		{195,135,99},
		{195,188,117},
		{195,169,101},
		{195,162,97},
		{195,164,97},
		{195,160,97},
		{195,165,97},
		{195,167,99},
		{195,170,101},
		{195,171,101},
		{195,168,101},
		{195,175,105},
		{195,174,105},
		{195,172,105},
		{195,132,97},
		{195,133,97},
		{195,137,101},
		{195,180,111},
		{195,182,111},
		{195,178,111},
		{195,187,117},
		{195,185,117},
		{195,191,121},
		{195,150,111},
		{195,156,117},
		{197,165,116},
		{197,159,115},
		{197,175,117},
		{197,174,117},
		{195,161,97},
		{195,173,105},
		{195,179,111},
		{195,186,117},
		{195,177,110},
		{195,145,110},
		{196,140,99},
		{196,141,99},
		{197,153,114},
		{197,152,114},
		{197,160,115},
		{197,161,115},
		{195,189,121},
		{197,189,122},
		{197,190,122},
		{196,177,105},
		{195,152,111},
		{206,177,97},
		{195,159,115},
		{206,147,103},
		{207,128,112},
		{196,131,97},
		{207,131,115},
		{206,179,103},
		{196,176,105},
		{197,163,116},
		{206,180,100},
		{195,184,111},
		{196,133,97},
		{196,153,101},
		{196,134,99},
		{196,135,99},
		{197,129,108},
		{197,130,108},
		{197,131,110},
		{197,132,110},
		{195,147,111},
		{197,154,115},
		{197,155,115},
		{197,185,122},
		{197,186,122},
		{197,187,122},
		{197,188,122}
	}';


	v_str := '';
	p_str1 := coalesce(p_str, '');
	v_len := char_length(p_str1);
	FOR v_i IN 1..v_len LOOP
		v_char := substr(p_str1, v_i, 1);
		v_asc := ascii(v_char);
		v_found := 0;
		FOR v_array IN 1..77 LOOP
		IF v_asc = r[v_array][1] THEN
			-- found the first character
			IF ascii(substr(p_str1, v_i+1, 1)) = r[v_array][2] THEN
			-- got the Unicode char!
			v_str := v_str || chr(r[v_array][3]);
			v_i := v_i + 1;
			v_found := 1;
			END IF;
		END IF;
		END LOOP;
		IF v_found = 0 THEN
		-- Not found - so its just a normal charcter: add it
		v_str := v_str || v_char;
		END IF;
	END LOOP;

	return v_str;
end;$$ language 'plpgsql';


create or replace function norm_text (varchar)
returns varchar as $$
declare
	p_str	alias for $1;
	v_str	varchar;
begin
	select translate(p_str, '@.-_', '    ')
	into v_str;

	return norm_text_utf8(v_str);
end;$$ language 'plpgsql';


create or replace function im_search_update (integer, varchar, integer, varchar)
returns integer as $$
declare
	p_object_id	alias for $1;
	p_object_type	alias for $2;
	p_biz_object_id	alias for $3;
	p_text		alias for $4;

	v_object_type_id	integer;
	v_exists_p		integer;
	v_text		varchar;
begin
	select	object_type_id
	into	v_object_type_id
	from	im_search_object_types
	where	object_type = p_object_type;

	-- Add the name for the business object to the search string
	v_text := acs_object__name(p_biz_object_id) || ' ' || p_text;

	select	count(*)
	into	v_exists_p
	from	im_search_objects
	where	object_id = p_object_id
		and object_type_id = v_object_type_id;

	if v_exists_p = 1 then
		update im_search_objects set
			object_type_id	= v_object_type_id,
			biz_object_id	= p_biz_object_id,
			fti		= to_tsvector('default'::regconfig, norm_text(v_text))
		where
			object_id	= p_object_id
			and object_type_id = v_object_type_id;
	else
		select	count(*)
			into	v_exists_p
		from	acs_objects
		where	object_id = p_object_id;
	
		if v_exists_p = 1 then 
			insert into im_search_objects (
				object_id,
				object_type_id,
				biz_object_id,
				fti
			) values (
				p_object_id,
				v_object_type_id,
				p_biz_object_id,
				to_tsvector('default'::regconfig, norm_text(v_text))
			);
		end if;
	end if;

	return 0;
end;$$ language 'plpgsql';



-----------------------------------------------------------
-- Trigram conversion

create or replace function im_tsvector_to_trigram (tsvector)
returns integer[] as $body$
declare
        p_tsquery		alias for $1;

        v_text                  varchar;
        v_exists_p              integer;
        i                       integer;
        v_trigram_string        varchar;
        v_trigram_hash          bigint;
        v_array                 integer[];
begin
        select  trim(regexp_replace(strip(p_tsquery)::text, '[^a-z ]', '', 'g')) into v_text;
        select  regexp_replace(v_text, ' ', '_', 'g') into v_text;
        v_array := '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}';
	IF v_text is null THEN return v_array; END IF;

        FOR i IN 1 .. length(v_text) -2 LOOP
            v_trigram_string := substring(v_text from i for 3);
            v_trigram_hash := (
                        (ascii(substring(v_text from i for 1)) - 94) * 1681 +
                        (ascii(substring(v_text from i+1 for 1)) - 94) * 41 +
                        (ascii(substring(v_text from i+2 for 1)) - 94) * 1
            ) % 17 + 1;
            v_array[v_trigram_hash] := v_array[v_trigram_hash] + 1;
        END LOOP;

	return v_array;
end;$body$ language 'plpgsql';



-----------------------------------------------------------
-- im_project

insert into im_search_object_types values (0,'im_project',1);

create or replace function im_projects_tsearch ()
returns trigger as $$
declare
	v_string	varchar;
	v_string2	varchar;
	v_object_type	varchar;
begin
	select	coalesce(project_name, '') || ' ' ||
		coalesce(project_nr, '') || ' ' ||
		coalesce(project_path, '') || ' ' ||
		coalesce(description, '') || ' ' ||
		coalesce(note, ''),
		o.object_type
	into	v_string, v_object_type
	from	im_projects p,
		acs_objects o
	where	p.project_id = new.project_id and
		p.project_id = o.object_id;

	-- Skip if this is a ticket. There is a special trigger for tickets.
	-- im_timesheet_task is still handled as a project.
	IF 'im_ticket' = v_object_type THEN return new; END IF;

	v_string2 := '';
	IF column_exists('im_projects', 'company_project_nr') THEN
		select	coalesce(company_project_nr, '')
		into	v_string2
		from	im_projects
		where	project_id = new.project_id;
		v_string := v_string || ' ' || v_string2;
	END IF;

	perform im_search_update(new.project_id, 'im_project', new.project_id, v_string);

	return new;
end;$$ language 'plpgsql';


create or replace function im_projects_tsearch_too_slow () 
returns trigger as $$
declare
	v_string	varchar;	v_string2	varchar;
	v_select	varchar;	v_value		varchar;
	v_sql		varchar;	row		record;		v_rec	record;
begin
	select 	coalesce(project_name, '') || ' ' || coalesce(project_nr, '') || ' ' ||
		coalesce(project_path, '') || ' ' || coalesce(description, '') || ' ' ||
		coalesce(note, '')
	into	v_string
	from	im_projects where project_id = new.project_id;

	v_string2 := '';
	if column_exists('im_projects', 'company_project_nr') then
		select 	coalesce(company_project_nr, '')
		into	v_string2
		from	im_projects where project_id = new.project_id;
		v_string := v_string || ' ' || v_string2;
	end if;

	-- Concat the indexable DynField fields...
	v_sql := ' '' '' ';
	FOR row IN
		select	w.deref_plpgsql_function, 
			aa.attribute_name
		from	im_dynfield_widgets w,
			im_dynfield_attributes a,
			acs_attributes aa
		where	a.widget_name = w.widget_name and
			a.acs_attribute_id = aa.attribute_id and
			aa.object_type = 'im_project' and
			a.include_in_search_p = 't'
	LOOP
		v_sql := v_sql||' || '' '' ||coalesce('||row.deref_plpgsql_function||'('||row.attribute_name||'),0::varchar) ';
	END LOOP;

	v_sql := 'select ' || v_sql || ' as value from im_projects where project_id = ' || new.project_id;
	RAISE NOTICE 'im_projects_tsearch: sql=% ', v_sql;
	
	-- Workaround - execute doesnt work yet with select_into, so we execute as part of a loop..
	FOR v_rec IN EXECUTE v_sql LOOP v_string := v_string || ' ' || v_rec.value; END LOOP;

	PERFORM im_search_update(new.project_id, 'im_project', new.project_id, v_string);
	return new;
end;$$ language 'plpgsql';


CREATE TRIGGER im_projects_tsearch_tr 
AFTER INSERT or UPDATE ON im_projects
FOR EACH ROW EXECUTE PROCEDURE im_projects_tsearch();


-- update im_projects set project_type_id = project_type_id;
create or replace function inline_0 ()
returns integer as $body$
declare
	row		RECORD;
begin
	FOR row IN select project_id from im_projects order by project_id
	LOOP update im_projects set project_nr = project_nr where project_id = row.project_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-----------------------------------------------------------
-- im_company

insert into im_search_object_types values (3,'im_company',10);

create or replace function im_companies_tsearch () 
returns trigger as $$
begin
	perform im_search_update(
		new.company_id, 
		'im_company', 
		new.company_id, 
		coalesce(new.company_name, '') || ' ' ||
		coalesce(new.company_path, '') || ' ' ||
		coalesce(new.note, '') || ' ' ||
		coalesce(new.referral_source, '') || ' ' ||
		coalesce(new.site_concept, '') || ' ' ||
		coalesce(new.vat_number, '')
	);
	return new;
end;$$ language 'plpgsql';

CREATE TRIGGER im_companies_tsearch_tr 
AFTER INSERT or UPDATE ON im_companies
FOR EACH ROW EXECUTE PROCEDURE im_companies_tsearch();

-- re-index companies
create or replace function inline_0 ()
returns integer as $body$
declare
	row		RECORD;
begin
	FOR row IN select company_id from im_companies order by company_id
	LOOP update im_companies set company_path = company_path where company_id = row.company_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------
-- person and im_employee
--
create or replace function persons_tsearch () 
returns trigger as $$
declare
	v_string	varchar;
begin
	select	coalesce(pa.email, '') || ' ' ||
		coalesce(pa.url, '') || ' ' ||
		coalesce(pe.first_names, '') || ' ' ||
		coalesce(pe.last_name, '') || ' ' ||
		coalesce(u.username, '') || ' ' ||
		coalesce(u.screen_name, '') || ' ' ||

		coalesce(home_phone, '') || ' ' ||
		coalesce(work_phone, '') || ' ' ||
		coalesce(cell_phone, '') || ' ' ||
		coalesce(pager, '') || ' ' ||
		coalesce(fax, '') || ' ' ||
		coalesce(aim_screen_name, '') || ' ' ||
		coalesce(msn_screen_name, '') || ' ' ||
		coalesce(icq_number, '') || ' ' ||

		coalesce(ha_line1, '') || ' ' ||
		coalesce(ha_line2, '') || ' ' ||
		coalesce(ha_city, '') || ' ' ||
		coalesce(ha_state, '') || ' ' ||
		coalesce(ha_postal_code, '') || ' ' ||

		coalesce(wa_line1, '') || ' ' ||
		coalesce(wa_line2, '') || ' ' ||
		coalesce(wa_city, '') || ' ' ||
		coalesce(wa_state, '') || ' ' ||
		coalesce(wa_postal_code, '') || ' ' ||

		coalesce(note, '') || ' ' ||
		coalesce(current_information, '') || ' ' ||

		coalesce(ha_cc.country_name, '') || ' ' ||
		coalesce(wa_cc.country_name, '') || ' ' ||

		coalesce(im_cost_center_name_from_id(department_id), '') || ' ' ||
		coalesce(job_title, '') || ' ' ||
		coalesce(job_description, '') || ' ' ||
		coalesce(skills, '') || ' ' ||
		coalesce(educational_history, '') || ' ' ||
		coalesce(last_degree_completed, '') || ' ' ||
		coalesce(termination_reason, '')

	into	v_string
	from
		parties pa,
		persons pe
		LEFT OUTER JOIN users u ON (pe.person_id = u.user_id)
		LEFT OUTER JOIN users_contact uc ON (pe.person_id = uc.user_id)
		LEFT OUTER JOIN im_employees e ON (pe.person_id = e.employee_id)
		LEFT OUTER JOIN country_codes ha_cc ON (uc.ha_country_code = ha_cc.iso)
		LEFT OUTER JOIN country_codes wa_cc ON (uc.wa_country_code = wa_cc.iso)
	where
		pe.person_id	= new.person_id
		and pe.person_id = pa.party_id
	;

	perform im_search_update(new.person_id, 'user', new.person_id, v_string);
	return new;
end;$$ language 'plpgsql';



create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
	row		RECORD;
begin
	-- Check if the table exists
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_employees';
	if v_count = 0 then return 1; end if;

	insert into im_search_object_types values (1,'user',5);

	CREATE TRIGGER persons_tsearch_tr 
	AFTER INSERT or UPDATE ON persons
	FOR EACH ROW EXECUTE PROCEDURE persons_tsearch();

	FOR row IN select person_id from persons order by person_id
	LOOP update persons set first_names = first_names where person_id = row.person_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-----------------------------------------------------------
-- im_forum_topics


create or replace function im_forum_topics_tsearch () 
returns trigger as $$
declare
	v_string	varchar;
begin
	select	coalesce(topic_name, '') || ' ' ||
		coalesce(subject, '') || ' ' ||
		coalesce(message, '')
	into	v_string
	from	im_forum_topics
	where	topic_id = new.topic_id;

	RAISE NOTICE 'TSearch2: Updating forum_topic % of %: %', new.topic_id, new.object_id, v_string;

	perform im_search_update(
		new.topic_id, 
		'im_forum_topic', 
		new.object_id, 
		v_string
	);
	return new;
end;$$ language 'plpgsql';


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
	row		RECORD;
begin
	-- Check if the table exists
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_forum_topics';
	if v_count = 0 then return 1; end if;

	insert into im_search_object_types values (2,'im_forum_topic',0.5);

	CREATE TRIGGER im_forum_topics_tsearch_tr 
	AFTER INSERT or UPDATE ON im_forum_topics
	FOR EACH ROW EXECUTE PROCEDURE im_forum_topics_tsearch();

	-- Update existing objects
	FOR row IN select topic_id from im_forum_topics order by topic_id
	LOOP update im_forum_topics set scope = scope where topic_id = row.topic_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------
-- invoices

-- We are going for Invoice instead of im_costs, because of
-- performance reasons. There many be many cost items, but
-- they don't usually interest us very much.

create or replace function im_invoice_tsearch ()
returns trigger as $$
declare
	v_string	varchar;
begin
	select	coalesce(i.invoice_nr, '') || ' ' ||
		coalesce(c.cost_nr, '') || ' ' ||
		coalesce(c.cost_name, '') || ' ' ||
		coalesce(c.description, '') || ' ' ||
		coalesce(c.note, '')
	into
		v_string
	from
		im_invoices i,
		im_costs c
	where	
		i.invoice_id = c.cost_id
		and i.invoice_id = new.invoice_id;

	perform im_search_update(new.invoice_id, 'im_invoice', new.invoice_id, v_string);
	return new;
end;$$ language 'plpgsql';


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
	row		RECORD;
begin
	-- Check if the table exists
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_invoices';
	if v_count = 0 then return 1; end if;

	insert into im_search_object_types values (4,'im_invoice',1);

	CREATE TRIGGER im_invoices_tsearch_tr
	AFTER INSERT or UPDATE ON im_invoices
	FOR EACH ROW EXECUTE PROCEDURE im_invoice_tsearch();

	FOR row IN select invoice_id from im_invoices order by invoice_id
	LOOP update im_invoices set invoice_nr = invoice_nr where invoice_id = row.invoice_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-----------------------------------------------------------
-- Tickets


create or replace function im_tickets_tsearch ()
returns trigger as $$
declare
	v_string	varchar;
begin
	select	coalesce(p.project_name, '') || ' ' ||
		coalesce(p.project_nr, '') || ' ' ||
		coalesce(p.project_path, '') || ' ' ||
		coalesce(p.description, '') || ' ' ||
		coalesce(p.note, '') || ' ' ||
		coalesce(t.ticket_note, '') || ' ' ||
		coalesce(t.ticket_description, '')
	into	v_string
	from	im_tickets t,
		im_projects p
	where	p.project_id = new.ticket_id and
		t.ticket_id = p.project_id;

	perform im_search_update(new.ticket_id, 'im_ticket', new.ticket_id, v_string);

	return new;
end;$$ language 'plpgsql';


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
	row		RECORD;
begin
	-- Check if the table exists
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_employees';
	if v_count = 0 then return 1; end if;

	insert into im_search_object_types values (8,'im_ticket',0.7);

	CREATE TRIGGER im_tickets_tsearch_tr
	AFTER INSERT or UPDATE ON im_tickets
	FOR EACH ROW EXECUTE PROCEDURE im_tickets_tsearch();

	FOR row IN select ticket_id from im_tickets order by ticket_id
	LOOP update im_tickets set ticket_type_id = ticket_type_id where ticket_id = row.ticket_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------
-- Conf_Items


create or replace function im_conf_items_tsearch ()
returns trigger as $$
declare
	v_string	varchar;
begin
	select	coalesce(c.conf_item_code, '') || ' ' ||
		coalesce(c.conf_item_name, '') || ' ' ||
		coalesce(c.conf_item_nr, '') || ' ' ||
		coalesce(c.conf_item_version, '') || ' ' ||
		coalesce(c.description, '') || ' ' ||
		coalesce(c.ip_address, '') || ' ' ||
		coalesce(c.note, '') || ' ' ||
		coalesce(c.ocs_deviceid, '') || ' ' ||
		coalesce(c.ocs_id, '') || ' ' ||
		coalesce(c.ocs_username, '') || ' ' ||
		coalesce(c.os_comments, '') || ' ' ||
		coalesce(c.os_name, '') || ' ' ||
		coalesce(c.os_version, '') || ' ' ||
		coalesce(c.processor_text, '') || ' ' ||
		coalesce(c.win_company, '') || ' ' ||
		coalesce(c.win_owner, '') || ' ' ||
		coalesce(c.win_product_id, '') || ' ' ||
		coalesce(c.win_product_key, '') || ' ' ||
		coalesce(c.win_userdomain, '') || ' ' ||
		coalesce(c.win_workgroup, '')
	into	v_string
	from	im_conf_items c
	where   c.conf_item_id = new.conf_item_id;

	perform im_search_update(new.conf_item_id, 'im_conf_item', new.conf_item_id, v_string);

	return new;
end;$$ language 'plpgsql';




create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
	row		RECORD;
begin
	-- Check if the table exists
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_conf_items';
	if v_count = 0 then return 1; end if;

	insert into im_search_object_types values (9, 'im_conf_item', 0.8);

	-- Check if the trigger exists
	select	count(*) into v_count from pg_trigger where tgname = 'im_conf_items_tsearch_tr';
	IF v_count > 0 THEN drop trigger im_conf_items_tsearch_tr on im_conf_items; END IF;

	CREATE TRIGGER im_conf_items_tsearch_tr
	AFTER INSERT or UPDATE ON im_conf_items
	FOR EACH ROW EXECUTE PROCEDURE im_conf_items_tsearch();

	FOR row IN select conf_item_id from im_conf_items order by conf_item_id
	LOOP update im_conf_items set conf_item_nr = conf_item_nr where conf_item_id = row.conf_item_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------
-- wiki etc.

insert into im_search_object_types values (7,'content_item',0.5);

create or replace function content_item_tsearch ()
returns trigger as $$
declare
	v_string varchar;
	v_string2 varchar;
begin
	select	coalesce(name, '') || ' ' || coalesce(content, '')
	into	v_string
	from	cr_items,cr_revisions 
	where	cr_items.latest_revision=cr_revisions.revision_id
		and cr_items.item_id=new.item_id;

	perform im_search_update(new.item_id, 'content_item', new.item_id, v_string);

	return new;
end;$$ language 'plpgsql';


CREATE TRIGGER cr_items_tsearch_tr
AFTER INSERT or UPDATE
ON cr_items
FOR EACH ROW 
EXECUTE PROCEDURE content_item_tsearch();


create or replace function content_item__name (integer) returns varchar as $$
DECLARE
	v_content_item_id alias for $1;
	v_name varchar;
BEGIN
	select	name into v_name from cr_items 
	where	item_id = v_content_item_id;

	return v_name;
end;$$ language 'plpgsql';



-- update cr_items set locale = locale;
create or replace function inline_0 ()
returns integer as $body$
declare
	v_count		integer;
	v_ctr		integer;
	row		RECORD;
begin
	select count(*) into v_count from cr_items;
	v_ctr := 0;
	FOR row IN
		select item_id from cr_items order by item_id
	LOOP
		RAISE NOTICE 'TSearch2: Updating cr_item % of %: item_id=%', v_ctr, v_count, row.item_id;
		update cr_items set locale = locale where item_id = row.item_id;
		v_ctr := v_ctr + 1;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


