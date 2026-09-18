set search_path to tembo;

-- ===========================================================================================================

create table if not exists tembo.guests(
		guest_id				SERIAL		primary key,
		guest_name				Varchar(50),
		guest_phone				varchar(50),
		guest_city				varchar(50),
		guest_nationality		varchar(50)	
);


-- ===========================================================================================================

insert into tembo.guests (
		guest_name,
		guest_phone,
		guest_city,
		guest_nationality
)
select initcap(trim(guest_name)) as guest_name,
		max(
			nullif(
				regexp_replace(TRIM(guest_phone), '[^0-9+]', '', 'g'),'')
			) as guest_phone,
		max(nullif(trim(guest_city), '')) as guest_city,
		max(nullif(trim(guest_nationality), '')) as guest_nationality 
from tembo.tembo_staging ts 
group by INITCAP(TRIM(guest_name));
	

-- ===========================================================================================================

/* viewing guests table */

select * from tembo.guests;
		
