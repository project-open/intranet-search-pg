-- upgrade-4.0.5.0.1-4.0.5.0.2.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-4.0.5.0.1-4.0.5.0.2.sql','');


create or replace function norm_text (varchar)
returns varchar as $$
declare
	p_str		alias for $1;
	v_str		varchar;
	v_result	varchar;
	v_len		integer;
	v_i		integer;
	v_char		varchar;
	v_char_trans	varchar;
	v_asc_trans	integer;
	v_asc_last	integer;
	v_asc		integer;
	v_index		integer;
	map		integer[];
begin
	--   0 -  16 -  32 -  48 -  64 -  80 -  96 - 112
	-- 128 - 144 - 160 - 176 - 192 - 208 - 224 - 240
	map := '{
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  32,  32,  32,  32,  32,  32, 
		 32,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 
		112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,  32,  32,  32,  32,  32, 
		 32,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 
		112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,  32,  32,  32,  32,  32, 
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32,  32, 
		 97,  97,  97,  97,  97,  97,  97,  99, 101, 101, 101, 101, 105, 105, 105, 105, 
		100, 110, 111, 111, 111, 111, 111, 111, 111, 117, 117, 117, 117, 121,NULL, 115, 
		 97,  97,  97,  97,  97,  97,  97,  99, 101, 101, 101, 101, 105, 105, 105, 105, 
		101, 110, 111, 111, 111, 111, 111, 111, 111, 117, 117, 117, 117, 121,NULL, 121,
		 97,  97,  97,  97,  97,  97,  99,  99,  99,  99,  99,  99,  99,  99, 100, 100,
		100, 100, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 103, 103, 103, 103
	}';

	-- Map Latin1 characters into ASCII
	v_result := '';
	v_str := coalesce(p_str, '');
	v_len := char_length(v_str);
	v_asc_last := 0;
	-- RAISE NOTICE 'norm_text: v_len=%', v_len;
	FOR v_i IN 1..v_len LOOP
		v_char := substr(v_str, v_i, 1);
		v_asc := ascii(v_char);
		v_index := 1 + v_asc;
		-- Coalesce to Unicode for search in Chinese etc.
		v_asc_trans := coalesce(map[v_index], v_asc);
		v_char_trans := coalesce(chr(v_asc_trans), '');

		IF 32 = v_asc_trans AND 32 = v_asc_last THEN
		      	-- Do nothing - avoid duplicate spaces
		ELSE 
			v_result := v_result || v_char_trans;
		END IF;
		v_asc_last := v_asc_trans;

	END LOOP;

	RETURN v_result;
end;$$ language 'plpgsql';





create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	person_id
		from	persons
		order by person_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update persons
		set first_names = first_names
		where person_id = row.person_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_1 (0);
select inline_1 (5000);
select inline_1 (10000);
select inline_1 (15000);
select inline_1 (20000);
select inline_1 (25000);
select inline_1 (30000);
select inline_1 (35000);
select inline_1 (40000);
select inline_1 (45000);
select inline_1 (50000);
select inline_1 (55000);
select inline_1 (60000);
select inline_1 (65000);
select inline_1 (70000);
select inline_1 (75000);
select inline_1 (80000);
select inline_1 (85000);
select inline_1 (90000);
select inline_1 (95000);
drop function inline_1 (integer);



create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	project_id
		from	im_projects
		order by project_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update im_projects
		set project_nr = project_nr
		where project_id = row.project_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_1 (0);
select inline_1 (5000);
select inline_1 (10000);
select inline_1 (15000);
select inline_1 (20000);
select inline_1 (25000);
select inline_1 (30000);
select inline_1 (35000);
select inline_1 (40000);
select inline_1 (45000);
select inline_1 (50000);
select inline_1 (55000);
select inline_1 (60000);
select inline_1 (65000);
select inline_1 (70000);
select inline_1 (75000);
select inline_1 (80000);
select inline_1 (85000);
select inline_1 (90000);
select inline_1 (95000);
drop function inline_1 (integer);



create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	ticket_id
		from	im_tickets
		order by ticket_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update im_tickets
		set ticket_note = ticket_note
		where ticket_id = row.ticket_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';


create or replace function inline_2 ()
returns integer as $body$
declare
        v_helpdesk_installed_p             integer;
begin

	select count(*) into v_helpdesk_installed_p from apm_packages where package_key = 'intranet-helpdesk';
	IF v_helpdesk_installed_p != 0 THEN 
	   select inline_1 (0);
	   select inline_1 (5000);
	   select inline_1 (10000);
	   select inline_1 (15000);
	   select inline_1 (20000);
	   select inline_1 (25000);
	   select inline_1 (30000);
	   select inline_1 (35000);
	   select inline_1 (40000);
	   select inline_1 (45000);
	   select inline_1 (50000);
	   select inline_1 (55000);
	   select inline_1 (60000);
	   select inline_1 (65000);
	   select inline_1 (70000);
	   select inline_1 (75000);
	   select inline_1 (80000);
	   select inline_1 (85000);
	   select inline_1 (90000);
	   select inline_1 (95000);
	END IF;  

        return 0;
end;$body$ language 'plpgsql';


drop function inline_1 (integer);
drop function inline_2 ();


create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	company_id
		from	im_companies
		order by company_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update im_companies
		set company_path = company_path
		where company_id = row.company_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_1 (0);
select inline_1 (5000);
select inline_1 (10000);
select inline_1 (15000);
select inline_1 (20000);
select inline_1 (25000);
select inline_1 (30000);
select inline_1 (35000);
select inline_1 (40000);
select inline_1 (45000);
select inline_1 (50000);
select inline_1 (55000);
select inline_1 (60000);
select inline_1 (65000);
select inline_1 (70000);
select inline_1 (75000);
select inline_1 (80000);
select inline_1 (85000);
select inline_1 (90000);
select inline_1 (95000);
drop function inline_1 (integer);






create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	invoice_id
		from	im_invoices
		order by invoice_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update im_invoices
		set invoice_nr = invoice_nr
		where invoice_id = row.invoice_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_1 (0);
select inline_1 (5000);
select inline_1 (10000);
select inline_1 (15000);
select inline_1 (20000);
select inline_1 (25000);
select inline_1 (30000);
select inline_1 (35000);
select inline_1 (40000);
select inline_1 (45000);
select inline_1 (50000);
select inline_1 (55000);
select inline_1 (60000);
select inline_1 (65000);
select inline_1 (70000);
select inline_1 (75000);
select inline_1 (80000);
select inline_1 (85000);
select inline_1 (90000);
select inline_1 (95000);
drop function inline_1 (integer);






create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	conf_item_id
		from	im_conf_items
		order by conf_item_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update im_conf_items
		set conf_item_nr = conf_item_nr
		where conf_item_id = row.conf_item_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_1 (0);
select inline_1 (5000);
select inline_1 (10000);
select inline_1 (15000);
select inline_1 (20000);
select inline_1 (25000);
select inline_1 (30000);
select inline_1 (35000);
select inline_1 (40000);
select inline_1 (45000);
select inline_1 (50000);
select inline_1 (55000);
select inline_1 (60000);
select inline_1 (65000);
select inline_1 (70000);
select inline_1 (75000);
select inline_1 (80000);
select inline_1 (85000);
select inline_1 (90000);
select inline_1 (95000);
drop function inline_1 (integer);





create or replace function inline_1 (integer)
returns integer as $body$
declare
	p_offset	alias for $1;
	row		record;
begin
	FOR row IN
		select	topic_id
		from	im_forum_topics
		order by topic_id
		OFFSET p_offset
		LIMIT 5000
	LOOP
		update im_forum_topics
		set topic_name = topic_name
		where topic_id = row.topic_id;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_1 (0);
select inline_1 (5000);
select inline_1 (10000);
select inline_1 (15000);
select inline_1 (20000);
select inline_1 (25000);
select inline_1 (30000);
select inline_1 (35000);
select inline_1 (40000);
select inline_1 (45000);
select inline_1 (50000);
select inline_1 (55000);
select inline_1 (60000);
select inline_1 (65000);
select inline_1 (70000);
select inline_1 (75000);
select inline_1 (80000);
select inline_1 (85000);
select inline_1 (90000);
select inline_1 (95000);
drop function inline_1 (integer);


