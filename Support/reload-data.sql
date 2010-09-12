-- create persitent, common namespaces
xml_set_ns_decl( 'f', 'http://linktegration.com/virtuosomate/func/', 2);
xml_set_ns_decl( 'v', 'http://linktegration.com/virtuosomate/vocab/', 2);
xml_set_ns_decl( 'rss', 'http://purl.org/rss/1.0/', 2);
xml_set_ns_decl( 'dc', 'http://purl.org/dc/elements/1.1/', 2);

-- enable execution on webroot
DB.DBA.VHOST_REMOVE (
	 lhost=>'*ini*',
	 vhost=>'*ini*',
	 lpath=>'/'
);

DB.DBA.VHOST_DEFINE (
	 lhost=>'*ini*',
	 vhost=>'*ini*',
	 lpath=>'/',
	 ppath=>'/',
	 is_dav=>0,
	 vsp_user=>'dba',
	 ses_vars=>0,
	 is_default_host=>NULL
);

-- define some stored procedures we will be using later on to generate data

create procedure uri_from_title( in title varchar ) returns varchar {
	return 'http://linktegration.com/virtuosomate/func/' || id_from_title( title );
};	

create procedure id_from_title( in title varchar ) returns varchar {
	title := lcase( trim( title ) );
	title := replace( title, '(', '' );
	title := replace( title, ')', '' );
	title := replace( title, 'db.dba.', '' );
	return substring( title, 11, length(title) - 9 );	
};

create procedure id_from_docurl( in docurl varchar ) returns varchar {
	docurl := lcase( trim( docurl ) );
	return substring( docurl, 40, length(docurl) - 44 );	
};

checkpoint;

-- (re)load local data

sparql clear graph <http://linktegration.com/virtuosomate/graph/> ;
ttlp( file_to_string_output('./data/functions.ttl'), '', 'http://linktegration.com/virtuosomate/graph/' );
sparql select count(*) as ?inserted_triples from <http://linktegration.com/virtuosomate/graph/> where { ?s ?p ?o };


-- (re)load functions.rss from openlinksw.com
sparql clear graph <http://docs.openlinksw.com/virtuoso/functions.rdf> ;

sparql
define get:soft "soft"
select count(*) from <http://docs.openlinksw.com/virtuoso/functions.rdf> where { ?s ?p ?o }
;


-- from the loaded RSS data, generate some v:Function instances
-- the feed does not have a 1 to 1 mapping with actual functions
-- but still, we can extract some functions/docs from it
-- a good heuristic to avoid false positives is to compare the doc uri
-- fn_blob_to_string_output.html
-- with the function name
-- if they match, then this is most probably a "regular" function
-- this list will have to be manually curated later on

checkpoint;

sparql
insert into graph <urn:temp:foo>
{
	`iri(?uri)` 
		a v:Function ;
		v:id ?id ;
		v:item `iri(?item)`
		.
} 
where
{
	{
		select 
			( bif:uri_from_title( ?title ) ) as ?uri
			( bif:id_from_title( ?title ) ) as ?id			
			?item
		where 
		{
			?item a rss:item ; rss:title ?title .
			filter( bif:id_from_title( ?title ) = bif:id_from_docurl( ?item ) )			
		}
	}
}
;


