-- upgrade-5.0.0.0.0-5.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-5.0.0.0.0-5.0.0.0.1.sql','');

-- Fix all TSEARCH2 triggers to be AFTER updates or inserts

DROP TRIGGER IF EXISTS cr_items_tsearch_tr ON public.cr_items;
DROP TRIGGER IF EXISTS im_companies_tsearch_tr ON public.im_companies;
DROP TRIGGER IF EXISTS im_conf_items_tsearch_tr ON public.im_conf_items;
DROP TRIGGER IF EXISTS im_forum_topics_tsearch_tr ON public.im_forum_topics;
DROP TRIGGER IF EXISTS im_fs_files_tsearch_tr ON public.im_fs_files;
DROP TRIGGER IF EXISTS im_invoices_tsearch_tr ON public.im_invoices;
DROP TRIGGER IF EXISTS im_projects_tsearch_tr ON public.im_projects;
DROP TRIGGER IF EXISTS im_tickets_tsearch_tr ON public.im_tickets;
DROP TRIGGER IF EXISTS persons_tsearch_tr ON public.persons;


CREATE TRIGGER cr_items_tsearch_tr AFTER INSERT OR UPDATE ON cr_items FOR EACH ROW EXECUTE PROCEDURE content_item_tsearch();
CREATE TRIGGER im_companies_tsearch_tr AFTER INSERT or UPDATE ON im_companies FOR EACH ROW EXECUTE PROCEDURE im_companies_tsearch();
CREATE TRIGGER im_conf_items_tsearch_tr AFTER INSERT or UPDATE ON im_conf_items FOR EACH ROW EXECUTE PROCEDURE im_conf_items_tsearch();
CREATE TRIGGER im_forum_topics_tsearch_tr AFTER INSERT OR UPDATE ON im_forum_topics FOR EACH ROW EXECUTE PROCEDURE im_forum_topics_tsearch();
CREATE TRIGGER im_fs_files_tsearch_tr AFTER INSERT OR UPDATE ON im_fs_files FOR EACH ROW EXECUTE PROCEDURE im_fs_files_tsearch();
CREATE TRIGGER im_invoices_tsearch_tr AFTER INSERT or UPDATE ON im_invoices FOR EACH ROW EXECUTE PROCEDURE im_invoice_tsearch();
CREATE TRIGGER im_projects_tsearch_tr AFTER INSERT OR UPDATE ON im_projects FOR EACH ROW EXECUTE PROCEDURE im_projects_tsearch();
CREATE TRIGGER im_tickets_tsearch_tr AFTER INSERT or UPDATE ON im_tickets FOR EACH ROW EXECUTE PROCEDURE im_tickets_tsearch();
CREATE TRIGGER persons_tsearch_tr AFTER INSERT OR UPDATE ON persons FOR EACH ROW EXECUTE PROCEDURE persons_tsearch();


