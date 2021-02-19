# ]po[ Full-Text Search Engine 
This package is part of ]project-open[, an open-source enterprise project management system.

For more information about ]project-open[ please see:
* [Documentation Wiki](https://www.project-open.com/en/)
* [V5.0 Download](https://sourceforge.net/projects/project-open/files/project-open/V5.0/)
* [Installation Instructions](https://www.project-open.com/en/list-installers)

About ]po[ Full-Text Search Engine :

<p><p>This package allows users to perform full text searches of the ]project-open[ database. All searching functions are permission sensitive and security conscious of a users rights and privileges. This package is an adapter, allowing <a href="https://www.postgresql.org">PostgreSQL<span class="external"> </span></a>&#39;s TSearch2 module to index ]project-open[ contents and then provide the search functionality for project, users, forums, files. <p><ul><li>High performance<li>Support of the same permissions as the rest of the system and<li>User friendlyness</ul><p><span class="brandsec">]</span><span class="brandfirst">project-open</span><span class="brandsec">[</span> Search is implemented using the TSearch2 full text engine that comes as a part of the <a href="https://www.postgresql.org/">PostgreSQL</a> search engine (on Oracle, <span class="brandsec">]</span><span class="brandfirst">project-open</span><span class="brandsec">[</span> supports Intermedia). <p>TSearch2 allows for a tight integration of full text indices and SQL statements, allowing to mix instructions for structured queries (in order to determine permissions and object relationships) and access to full text indices. <p>The implementation consists of the following elements: <ul><li>A centralized &quot;im_search_objects&quot; table that contains the full text index for all objects in the system that are indexed<li>A number of SQL triggers that are associated to the indexed original tables. These triggers keep im_search_objects in sync with the application tables<li>A centralized search form</ul><pre>-- The main search table with Full Text Index.
--
create table im_search_objects (
        object_id               integer,
                                -- may include &quot;object types&quot; outside of OpenACS
                                -- that are not in the &quot;acs_object_types&quot; table.
        object_type_id          integer
                                constraint im_search_objects_object_type_id_fk
                                references im_search_object_types
                                on delete cascade,
                                -- What is the topmost container for this object?
                                -- Allows to speed up the elimination of objects
                                -- that the current user can&#39;t access
        biz_object_id           integer
                                constraint im_search_objects_biz_obj_id_fk
                                references acs_objects
                                on delete cascade,
                                -- Owner may not need to be a &quot;user&quot; (in the case
                                -- of a deleted user). Owners can be asked to give
                                -- permissions to a document even if the document
                                -- is not readable for the searching user.
        owner_id                integer
                                constraint im_search_objects_owner_id_fk
                                references persons
                                on delete cascade,
                                -- Bitset with one bit for each &quot;profile&quot;:
                                -- We use an integer instead of a &quot;bit varying&quot;
                                -- in order to keep the set compatible with Oracle.
                                -- A set bit indicates that object is readable to
                                -- members of the profile independent of the
                                -- biz_object_id permissions.
        profile_permissions     integer,
                                -- counter for number of accesses to this object
                                -- either from the permission() proc or from
                                -- reading in the server log file.
        popularity              integer,
                                -- Full Text Index
        fti                     tsvector,
                                -- For tables that don&#39;t respect the OpenACS object
                                -- scheme we may get &quot;object_id&quot;s that start with 0.
        primary key (object_id, object_type_id)
);

create index im_search_objects_fti_idx on im_search_objects using gist(fti);
create index im_search_objects_object_id_idx on im_search_objects (object_id);
</pre><p>The following steps are executed during each search: <ol><li>The main search SQL query determines in a subquery the set of &quot;container objects&quot; (projects, customers, users, ...) that are accessible for a specific user. Only part of the permission rules are checked for the container objects, leading to a slighly more search results then what a user should see at the end. These cases are treated later in the algorithm.<li>The main search SQL determines all searchable objects within the &quot;container objects&quot;.<li>These searchable objects are queried using the <a href="https://www.postgresql.org/">PostgreSQL</a> TSearch2 full text index. Please note that the queried set of objects may already be greatly reduced due to step 1.<li>The results of the SQL search query are checked for security permissions via TCL code (the security system doesn&#39;t have a SQL API). This step eliminates some objects that might have slipped through the coarse grain (fast) permission check in step 1.<li>The results are displayed on the search screen, together with HTML links to the object&#39;s view pages and with a &quot;summary&quot; of the object&#39;s content (the TSearch2 full text index list of words).</ol><p>TSearch2 contains several features allowing to adapt the search process to specific languages such as dictionaries, language specific stop words etc. However, <span class="brandsec">]</span><span class="brandfirst">project-open</span><span class="brandsec">[</span> needs to be able to operate with content items of several languages at the same time. <p>However, it is not always possible to determine the language of a content item, so that we have decided not to implement these features at the moment. <p>However, the practical experiences of the use of TSearch with languages such as French, Spanish and German has required us to add a &quot;normalization&quot; feature to TSearch2 that &quot;normalized&quot; search content and queries in order to deal with accents and notational variants: <ul><li>We transform all accented characters such as &aacute;, &egrave;, &uuml;, &ntilde; etc. into the non-accented form<li>We replace &quot;@&quot;, &quot;-&quot; and &quot;.&quot; characters by a space in order to split URLs and mail adddresses into their components</ul><p>This normalization allows to search for &quot;carlos&quot; and to receive search results such as &quot;Carl&oacute;s&quot; or &quot;carlos@abc.com&quot;. <p>Actually, we had to implement this normalization ourselves, because there was no code on the <a href="https://www.postgresql.org/">PostgreSQL</a> page about it. Also, the PostgreSQL &quot;conversion&quot; functionality (UTF-8 =&gt; SQL_ASCII) did not elimiated the accents. Please check for the latest version at <a href="https://sourceforge.net/projects/project-open/">Sourceforge.net</a>. <p>Ranking is currently limited to the built-in TSearch2 ranking functionality. In the future we are going to use several types of statistics to determine the &quot;popularity&quot; of a content item. <p>

# Online Reference Documentation

## The Big Picture



## Implementation Architecture



## Search Internationalization



## Ranking



## Procedure Files

<table cellpadding="0" cellspacing="0"><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/procs-file-view?version_id=4482&amp;path=packages/intranet-search-pg/tcl/intranet-search-pg-procs.tcl">tcl/intranet-search-pg-procs.tcl</a></b></td><td></td><td>Procedures for tsearch full text enginge driver </td></tr></table>

## Procedures

<table cellpadding="0" cellspacing="0"><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=im_package_search_id">im_package_search_id</a></b></td><td></td><td>Returns the ID of the current package. </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=im_tsvector_to_headline">im_tsvector_to_headline</a></b></td><td></td><td>Converts a tsvector (or better: its string representation) into a text string, obviously without the stop words. </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::build_query">tsearch2::build_query</a></b></td><td></td><td>Convert conjunctions to query characters for tsearch2 and =&gt; &amp; not =&gt; ! or =&gt; | space =&gt; | (or) </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::driver_info">tsearch2::driver_info</a></b></td><td></td><td></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::index">tsearch2::index</a></b></td><td></td><td>add object to full text index </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::search">tsearch2::search</a></b></td><td></td><td>ftsenginedriver search operation implementation for tsearch2 </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::summary">tsearch2::summary</a></b></td><td></td><td>Highlights matching terms. </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::unindex">tsearch2::unindex</a></b></td><td></td><td>Remove item from FTS index </td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/proc-view?version_id=4482&amp;proc=tsearch2::update_index">tsearch2::update_index</a></b></td><td></td><td>update full text index </td></tr></table>

## SQL Files

<table cellpadding="0" cellspacing="0"><tr valign="top"><td><b><a href="https://www.project-open.net/api-doc/display-sql?package_key=intranet-search-pg&amp;url=postgresql/intranet-search-pg-create.sql&amp;version_id=4482">sql/postgresql/intranet-search-pg-create.sql</a></b></td><td></td><td></td></tr><tr valign="top"><td><b><a href="https://www.project-open.net/api-doc/display-sql?package_key=intranet-search-pg&amp;url=postgresql/intranet-search-pg-drop.sql&amp;version_id=4482">sql/postgresql/intranet-search-pg-drop.sql</a></b></td><td></td><td></td></tr><tr valign="top"><td><b><a href="https://www.project-open.net/api-doc/display-sql?package_key=intranet-search-pg&amp;url=postgresql/upgrade/upgrade-5.0.2.3.4-5.0.2.3.5.sql&amp;version_id=4482">sql/postgresql/upgrade/upgrade-5.0.2.3.4-5.0.2.3.5.sql</a></b></td><td></td><td></td></tr></table>

## Content Pages

<table cellpadding="0" cellspacing="0"><tr valign="top"><td><b>www/</b></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/content-page-view?version_id=4482&amp;path=packages/intranet-search-pg/www/advanced-search.adp">advanced-search.adp</a></b></td><td></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/content-page-view?version_id=4482&amp;path=packages/intranet-search-pg/www/advanced-search.tcl">advanced-search.tcl</a></b></td><td></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/content-page-view?version_id=4482&amp;path=packages/intranet-search-pg/www/index.adp">index.adp</a></b></td><td></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/content-page-view?version_id=4482&amp;path=packages/intranet-search-pg/www/index.tcl">index.tcl</a></b></td><td></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/content-page-view?version_id=4482&amp;path=packages/intranet-search-pg/www/search.adp">search.adp</a></b></td><td></td></tr><tr valign="top"><td style="width:35%"><b><a href="https://www.project-open.net/api-doc/content-page-view?version_id=4482&amp;path=packages/intranet-search-pg/www/search.tcl">search.tcl</a></b></td><td></td></tr></table>

