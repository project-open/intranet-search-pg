ad_page_contract {
    @author Neophytos Demetriou <k2pts@cytanet.com.cy>
    @author Frank Bergmann <frank.bergmann@project-open.com>
    @creation-date May 20th, 2005
    @cvs-id $Id$

    This search page uses the "TSearch2" full text index (FTI)
    and the P/O permission system to locate suitable business
    objects for a search query.<p>

    The main problem of searching in P/O is it's relatively
    strict permission system with object specific permissions
    that can only be tested via a (relatively slow) TCL routine.
    For example: Project are readable for the "key account"
    managers of the project's customer.<p>

    So this search page contains several performance optimizations:
    <ul>
    <li>Rapid exclusion of non-allowed objects:<br>
	A search query can return millions of object_id's in
	the worst case. Testing each of these objects for permission
	would take minutes or even hours.
	However, we can (frequently!) discard a large number of
	these objects when they are located in projects (or 
	companies, offices, ...) that are outside of the permission
	scope of the current user. This is why the "im_search_objects"
	table explicitely carries the "business_object_id".

    <li>Explicit permissions for specific "profiles":<br>
	Explicit permissions are given for certain user groups,
	most notably "Registered Users". So documents in a project
	folder that are marked as publicly readable can be found
	even if the project may not be readable at all.
    </ul>

} {
    q:notnull,trim
    {t:trim ""}
    {offset:integer 0}
    {results_per_page:integer 0}
    {type:multiple "all"}
} -errors {
    q:notnull {[_ search.lt_You_must_specify_some].}
}

# -----------------------------------------------------------
# Default & Security
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "Search Results for \"$q\""
set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set package_url_with_extras $package_url
set context [list]
set context_base_url $package_url

if { $results_per_page <= 0} {
    set results_per_page [ad_parameter -package_id $package_id SearchResultsPerPage]
} else {
    set results_per_page $results_per_page
}


set q [string tolower $q]
set urlencoded_query [ad_urlencode $q]
if { $offset < 0 } { set offset 0 }
set t0 [clock clicks -milliseconds]


# -----------------------------------------------------------
# Prepare the list of searchable object types
# -----------------------------------------------------------

set sql "
	select
		sot.object_type_id,
		aot.object_type,
		aot.pretty_name as object_type_pretty_name,
		aot.pretty_plural as object_type_pretty_plural
	from
		im_search_object_types sot,
		acs_object_types aot
	where
		sot.object_type = aot.object_type
"

set objects_html ""
db_foreach object_type $sql {
    set checked ""
    if {[string equal $type "all"] || [lsearch $type $object_type] >= 0} {
	set checked " checked"
    }
    append objects_html "
	<tr>
	  <td>
	    <input type=checkbox name=type value='$object_type' $checked>
	  </td>
	  <td>
	    $object_type_pretty_plural
	  </td>
	</tr>
"
}


# -----------------------------------------------------------
# Permissions for different types of business objects
# -----------------------------------------------------------

set project_perm_sql "
			and p.project_id in (
			        select
			                p.project_id
			        from
			                im_projects p,
			                acs_rels r
			        where
			                r.object_id_one = p.project_id
			                and r.object_id_two = :user_id
			)"

if {[im_permission $user_id "view_projects_all"]} {
        set project_perm_sql ""
}

set company_perm_sql "
			and c.company_id in (
			        select
			                c.company_id
			        from
			                im_companies c,
			                acs_rels r
			        where
			                r.object_id_one = c.company_id
			                and r.object_id_two = :user_id
			)"

if {[im_permission $user_id "view_companies_all"]} {
        set company_perm_sql ""
}


# The list of prohibited users: They belong 
# to a group which the current user should not see
set user_perm_sql "
			and person_id not in (
select distinct
        cc.user_id
from
        cc_users cc,
        (
                select  group_id
                from    groups
                where   group_id > 0
                        and 'f' = im_object_permission_p(group_id,8849,'read')
        ) forbidden_groups,
        group_approved_member_map gamm
where
        cc.user_id = gamm.member_id
        and gamm.group_id = forbidden_groups.group_id
			)"

if {[im_permission $user_id "view_users_all"]} {
        set user_perm_sql ""
}


# -----------------------------------------------------------
# Build a suitable select for object types
# -----------------------------------------------------------

foreach t $type { lappend types "'$t'"} 
set object_type_where "object_type in ([join $types ","])"
if {[string equal "all" $type]} {
    set object_type_where "1=1"
}

# ad_return_complaint 1 $object_type_where


# -----------------------------------------------------------
# Main SQL
# -----------------------------------------------------------

set sql "
	select
		'asfdasfsadf' as name,
		rank(so.fti, :q::tsquery) as rank,
		fti as full_text_index,
		'asfdasdfasfd' as url,
		so.object_id,
		'im_forum_topic' as object_type,
		'Forum' as object_type_pretty_name,
		so.biz_object_id,
		so.hit_count
	from
		im_search_objects so,
		acs_object_types aot,
		im_search_object_types sot
		left outer join (
			select	*
			from	im_biz_object_urls
			where	url_type = 'view'
		) bou on (sot.object_type = bou.object_type)
	where
		so.object_type_id = sot.object_type_id
		and sot.object_type = aot.object_type
		and so.fti @@ :q::tsquery
	order by
		rank DESC
"

set sql "
	select
		acs_object__name(so.object_id) as name,
		rank(so.fti, :q::tsquery) as rank,
		fti as full_text_index,
		bou.url,
		so.object_id,
		sot.object_type,
		aot.pretty_name as object_type_pretty_name,
		so.biz_object_id,
		so.hit_count
	from
		im_search_objects so,
		acs_object_types aot,
		(	select	*
			from	im_search_object_types 
			where	$object_type_where
		) sot
		left outer join (
			select	*
			from	im_biz_object_urls
			where	url_type = 'view'
		) bou on (sot.object_type = bou.object_type),
		(
			select	project_id as object_id
			from	im_projects p
			where	1=1
				$project_perm_sql
		    UNION
			select	company_id as object_id
			from	im_companies c
			where	1=1
				$company_perm_sql
		    UNION
			select	person_id as object_id
			from	persons p
			where	1=1
				$user_perm_sql
		) readable_biz_objs
	where
		so.object_type_id = sot.object_type_id
		and sot.object_type = aot.object_type
		and so.biz_object_id = readable_biz_objs.object_id
		and so.fti @@ :q::tsquery
	order by
		rank DESC
"

set low 0
set high 0

set count 0
set result_html ""
db_foreach full_text_query $sql {

    set name_link $name
    if {"" != $url} {
	set name_link "<a href=\"$url$object_id\">$name</a>\n"
    }
    
    set text [im_tsvector_to_headline $full_text_index]
    set headline [db_string headline "select headline(:text, :q::tsquery)" -default ""]

    append result_html "
      <tr>
	<td>
	  <font size=\"+1\">$object_type_pretty_name: $name_link</font><br>
          $headline
	  <br>&nbsp;
	</td>
      </tr>
"
    incr count
}



set url_advanced_search ""
append url_advanced_search "advanced-search?q=${urlencoded_query}"
if { $results_per_page > 0 } { 
    append url_advanced_search "&results_per_page=${results_per_page}" 
}


set tend [clock clicks -milliseconds]
set elapsed [format "%.02f" [expr double(abs($tend - $t0)) / 1000.0]]

set and_queries_notice_p 0
set nstopwords 0
set query $q
set nquery [llength $q]


set from_result_page 1
set current_result_page [expr ($offset / $results_per_page) + 1]
set to_result_page [expr ceil(double($count) / double($results_per_page))]

set url_previous ""
set url_next ""
append url_previous "search?q=${urlencoded_query}"
append url_next "search?q=${urlencoded_query}"
if { [expr $current_result_page - 1] > $from_result_page } { 
    append url_previous "&offset=[expr ($current_result_page - 2) * $limit]"
}
if { $current_result_page < $to_result_page } { 
    append url_next "&offset=[expr $current_result_page * $limit]"
}
if { $results_per_page > 0 } {
    append url_previous "&results_per_page=$results_per_page"
    append url_next "&results_per_page=$results_per_page"
}


