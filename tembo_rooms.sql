set search_path to tembo;

-- ===========================================================================================================


create table if not exists tembo.rooms(
		room_no					varchar(50) 	primary key,
		room_type				varchar(50),
		room_rate_per_night		numeric(10,2)
);


-- ===========================================================================================================


insert into tembo.rooms(
		room_no,
		room_type,
		room_rate_per_night
)
select initcap(trim(room_no)) as room_no,
		max(nullif(trim(room_type), '')) as room_type,
		max(nullif(trim(room_rate_per_night), ''))::NUMERIC(10,2) as room_rate_per_night
from tembo.tembo_staging ts 
group by initcap(trim(room_no));


-- ===========================================================================================================


select * from tembo.rooms r;