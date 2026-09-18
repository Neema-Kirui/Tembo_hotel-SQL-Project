set search_path to tembo;

-- ===========================================================================================================

create table if not exists tembo.staff(
		staff_id			serial		primary key,
		staff_name			varchar(50),
		staff_department	varchar(50),
		staff_salary		numeric(10,2)
);


-- ===========================================================================================================

insert into tembo.staff(
		staff_name,
		staff_department,
		staff_salary
)
select initcap(trim(staff_name)) as staff_name,
		max(nullif(trim(staff_department), '')) as staff_department,
		max(nullif(trim(staff_salary), ''))::NUMERIC(10,2) as staff_salary
from tembo.tembo_staging ts 
group by initcap(trim(staff_name));


-- ===========================================================================================================


select * from tembo.staff s;
