
DROP TABLE pg_catalog.pg_ts_dict;
DROP TABLE pg_ts_cfg;
DROP TABLE pg_ts_cfgmap;
DROP TABLE pg_ts_parser;

DROP TYPE gtsq;
DROP TYPE gtsvector;
DROP TYPE statinfo;
DROP TYPE tokenout;
DROP TYPE tokentype;
DROP TYPE tsquery;
DROP TYPE tsvector;




DROP FUNCTION lexize(oid, text);
DROP FUNCTION lexize(text, text);
DROP FUNCTION lexize(text);
DROP FUNCTION set_curdict(int);
DROP FUNCTION set_curdict(text);
DROP FUNCTION dex_init(internal);
DROP FUNCTION dex_lexize(internal,internal,int4);
DROP FUNCTION _get_parser_from_curcfg();
DROP FUNCTION concat(tsvector,tsvector);
DROP FUNCTION exectsq(tsvector, tsquery);
DROP FUNCTION get_covers(tsvector,tsquery);
DROP FUNCTION gin_extract_tsquery(tsquery,internal,internal);
DROP FUNCTION gin_extract_tsvector(tsvector,internal);
DROP FUNCTION gin_ts_consistent(internal,internal,tsquery);
DROP FUNCTION gtsq_compress(internal);
DROP FUNCTION gtsq_consistent(gtsq,internal,int4);
DROP FUNCTION gtsq_decompress(internal);
DROP FUNCTION gtsq_in(cstring);
DROP FUNCTION gtsq_out(gtsq);
DROP FUNCTION gtsq_penalty(internal,internal,internal);
DROP FUNCTION gtsq_picksplit(internal, internal);
DROP FUNCTION gtsq_same(gtsq, gtsq, internal);
DROP FUNCTION gtsq_union(bytea, internal);
DROP FUNCTION gtsvector_compress(internal);
DROP FUNCTION gtsvector_consistent(gtsvector,internal,int4);
DROP FUNCTION gtsvector_decompress(internal);
DROP FUNCTION gtsvector_in(cstring);
DROP FUNCTION gtsvector_out(gtsvector);
DROP FUNCTION gtsvector_penalty(internal,internal,internal);
DROP FUNCTION gtsvector_picksplit(internal, internal);
DROP FUNCTION gtsvector_same(gtsvector, gtsvector, internal);
DROP FUNCTION gtsvector_union(internal, internal);
DROP FUNCTION headline(oid, text, tsquery);
DROP FUNCTION headline(oid, text, tsquery, text);
DROP FUNCTION headline(text, text, tsquery);
DROP FUNCTION headline(text, text, tsquery, text);
DROP FUNCTION headline(text, tsquery);
DROP FUNCTION headline(text, tsquery, text);
DROP FUNCTION length(tsvector);
DROP FUNCTION parse(oid,text);
DROP FUNCTION parse(text);
DROP FUNCTION parse(text,text);
DROP FUNCTION plainto_tsquery(oid, text);
DROP FUNCTION plainto_tsquery(text);
DROP FUNCTION plainto_tsquery(text, text);
DROP FUNCTION prsd_end(internal);
DROP FUNCTION prsd_getlexeme(internal,internal,internal);
DROP FUNCTION prsd_headline(internal,internal,internal);
DROP FUNCTION prsd_lextype(internal);
DROP FUNCTION prsd_start(internal,int4);
DROP FUNCTION querytree(tsquery);
DROP FUNCTION rank(float4[], tsvector, tsquery);
DROP FUNCTION rank(float4[], tsvector, tsquery, int4);
DROP FUNCTION rank(tsvector, tsquery);
DROP FUNCTION rank(tsvector, tsquery, int4);
DROP FUNCTION rank_cd(float4[], tsvector, tsquery);
DROP FUNCTION rank_cd(float4[], tsvector, tsquery, int4);
DROP FUNCTION rank_cd(tsvector, tsquery);
DROP FUNCTION rank_cd(tsvector, tsquery, int4);
DROP FUNCTION reset_tsearch();
DROP FUNCTION rexectsq(tsquery, tsvector);
DROP FUNCTION set_curcfg(int);
DROP FUNCTION set_curcfg(text);
DROP FUNCTION set_curprs(int);
DROP FUNCTION set_curprs(text);
DROP FUNCTION setweight(tsvector,"char");
DROP FUNCTION show_curcfg();
DROP FUNCTION snb_en_init(internal);
DROP FUNCTION snb_lexize(internal,internal,int4);
DROP FUNCTION snb_ru_init_koi8(internal);
DROP FUNCTION snb_ru_init_utf8(internal);
DROP FUNCTION spell_init(internal);
DROP FUNCTION spell_lexize(internal,internal,int4);
DROP FUNCTION stat(text);
DROP FUNCTION stat(text,text);
DROP FUNCTION strip(tsvector);
DROP FUNCTION syn_init(internal);
DROP FUNCTION syn_lexize(internal,internal,int4);
DROP FUNCTION thesaurus_init(internal);
DROP FUNCTION thesaurus_lexize(internal,internal,int4,internal);
DROP FUNCTION to_tsquery(oid, text);
DROP FUNCTION to_tsquery(text);
DROP FUNCTION to_tsquery(text, text);
DROP FUNCTION to_tsvector(oid, text);
DROP FUNCTION to_tsvector(text);
DROP FUNCTION to_tsvector(text, text);
DROP FUNCTION token_type();
DROP FUNCTION token_type(int4);
DROP FUNCTION token_type(text);
DROP FUNCTION ts_debug(text);
DROP FUNCTION tsearch2();
DROP FUNCTION tsquery_in(cstring);
DROP FUNCTION tsquery_out(tsquery);
DROP FUNCTION tsvector_cmp(tsvector,tsvector);
DROP FUNCTION tsvector_eq(tsvector,tsvector);
DROP FUNCTION tsvector_ge(tsvector,tsvector);
DROP FUNCTION tsvector_gt(tsvector,tsvector);
DROP FUNCTION tsvector_in(cstring);
DROP FUNCTION tsvector_le(tsvector,tsvector);
DROP FUNCTION tsvector_lt(tsvector,tsvector);
DROP FUNCTION tsvector_ne(tsvector,tsvector);
DROP FUNCTION tsvector_out(tsvector);

DROP FUNCTION numnode(tsquery);
DROP FUNCTION rewrite(tsquery, text);
DROP FUNCTION rewrite(tsquery, tsquery, tsquery);
DROP FUNCTION rewrite_accum(tsquery,tsquery[]);
DROP FUNCTION rewrite_finish(tsquery);
DROP FUNCTION tsq_mcontained(tsquery, tsquery);
DROP FUNCTION tsq_mcontains(tsquery, tsquery);
DROP FUNCTION tsquery_and(tsquery,tsquery);
DROP FUNCTION tsquery_cmp(tsquery,tsquery);
DROP FUNCTION tsquery_eq(tsquery,tsquery);
DROP FUNCTION tsquery_ge(tsquery,tsquery);
DROP FUNCTION tsquery_gt(tsquery,tsquery);
DROP FUNCTION tsquery_le(tsquery,tsquery);
DROP FUNCTION tsquery_lt(tsquery,tsquery);
DROP FUNCTION tsquery_ne(tsquery,tsquery);
DROP FUNCTION tsquery_not(tsquery);
DROP FUNCTION tsquery_or(tsquery,tsquery);








DROP AGGREGATE rewrite (
DROP OPERATOR !! (
DROP OPERATOR && (
DROP OPERATOR < (
DROP OPERATOR < (
DROP OPERATOR <= (
DROP OPERATOR <= (
DROP OPERATOR <> (
DROP OPERATOR <> (
DROP OPERATOR <@ (
DROP OPERATOR = (
DROP OPERATOR = (
DROP OPERATOR > (
DROP OPERATOR > (
DROP OPERATOR >= (
DROP OPERATOR >= (
DROP OPERATOR @ (
DROP OPERATOR @> (
DROP OPERATOR @@ (
DROP OPERATOR @@ (
DROP OPERATOR @@@ (
DROP OPERATOR @@@ (
DROP OPERATOR CLASS gin_tsvector_ops
DROP OPERATOR CLASS gist_tp_tsquery_ops
DROP OPERATOR CLASS gist_tsvector_ops
DROP OPERATOR CLASS tsquery_ops
DROP OPERATOR CLASS tsvector_ops
DROP OPERATOR || (
DROP OPERATOR || (
DROP OPERATOR ~ (




