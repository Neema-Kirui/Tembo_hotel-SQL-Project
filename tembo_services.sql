set search_path to tembo;


-- ===========================================================================================================


create table if not exists tembo.services(
			service_id 			serial			primary key,
			service_used		varchar(50),
			service_price		numeric(10,2)
);


-- ===========================================================================================================


insert into tembo.services(
		service_used,
		service_price
)
select initcap(trim(service_used)) as service_used,
		max(nullif(trim(service_price), ''))::numeric(10,2) as service_price
from tembo.tembo_staging ts 
group by initcap(trim(service_used));


-- ===========================================================================================================


select * from tembo.services s