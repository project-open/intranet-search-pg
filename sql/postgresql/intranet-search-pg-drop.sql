-- /packages/intranet-forum/sql/oracle/intranet-forum-sc-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author pepels@gmail.com

-----------------------------------------------------------
-- Tasks, Incidents, News and Discussions (TIND)
--
-- ftscontenprovider support for projects in intranet-forum
-----------------------------------------------------------
-- Topics
--

select acs_sc_impl__delete(
           'FtsContentProvider',                -- impl_contract_name
           'im_project'
      );

drop trigger projects__utrg on im_projects;
drop trigger projects__dtrg on im_projects;
drop trigger projects__itrg on im_projects;

drop function projects__utrg();
drop function projects__dtrg();
drop function projects__itrg();