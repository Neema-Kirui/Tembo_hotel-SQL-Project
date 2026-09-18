set search_path to tembo;


-- ===========================================================================================================

create table if not exists tembo.bookings(
		booking_id				varchar(50)			primary key,
		guest_id				integer,
		room_no					varchar(50),
		check_in_date			date,
		check_out_date			date,
		nights_stayed			integer,
		staff_id				integer,
		payment_method			varchar(50),
		booking_status			varchar(50),
		total_amount			numeric(10,2),
		service_id				integer,
		guest_rating			integer,
		constraint fk_guest
			foreign key (guest_id)
			references	tembo.guests(guest_id),
		constraint fk_room
			foreign key (room_no)
			references tembo.rooms(room_no),
		constraint fk_staff
			foreign key (staff_id)
			references tembo.staff (staff_id),
		constraint fk_service
			foreign key (service_id)
			references tembo.services (service_id)
);


-- ===========================================================================================================

insert into tembo.bookings (
		booking_id,
		guest_id,
		room_no,
		check_in_date,
		check_out_date,
		nights_stayed,
		staff_id,
		payment_method,
		booking_status,
		total_amount,
		service_id,
		guest_rating
)
select 
	ts.booking_id,
	g.guest_id,
	r.room_no,
	TO_DATE(ts.check_in_date, 'YYYY-MM-DD'),
	TO_DATE(ts.check_out_date, 'YYYY-MM-DD'),
	nullif(trim(ts.nights_stayed), '')::integer as nights_stayed,
	s.staff_id,
	ts.payment_method,
	ts.booking_status,
	nullif(ts.total_amount, '')::numeric(10,2),
	service_id,
	nullif(ts.guest_rating, '')::integer as guest_rating
from tembo.tembo_staging ts 
join tembo.guests g 
	on trim(lower(ts.guest_name)) = trim(lower(g.guest_name))
join tembo.rooms r 
	on ts.room_no = r.room_no 
join tembo.staff s 
	on trim(lower(ts.staff_name)) = trim(lower(s.staff_name))
join tembo.services s2 
	on trim(lower(ts.service_used)) = trim(lower(s2.service_used));


-- ===========================================================================================================


select * from tembo.bookings b;

