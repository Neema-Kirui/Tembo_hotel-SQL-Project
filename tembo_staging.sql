set search_path to tembo;

create table if not exists tembo.tembo_staging
(
	booking_id text,
	guest_name text,
	guest_phone text,
	guest_city text,
	guest_nationality text,
	room_no text,
	room_type text,
	room_rate_per_night text,
	check_in_date text,
	check_out_date text,
	nights_stayed text,
	staff_name text,
	staff_department text,
	staff_salary text,
	payment_method text,
	booking_status text,
	total_amount text,
	service_used text,
	service_price text,
	guest_rating text
);


-- ===========================================================================================================

/* analysing the data to identify issues */

/* booking_id */


select distinct(booking_id), count(*) as total 
from tembo.tembo_staging ts
group by ts.booking_id 
order by total desc;

/* BK006 appears twice */

-- ===========================================================================================================

/* guest name */

select distinct(guest_name)
from tembo.tembo_staging ts 
group by ts.guest_name 
order by ts.guest_name ;

/* case issue, whitespace issue at start of names */

-- ===========================================================================================================

/* guest phone */

select distinct(guest_phone)
from tembo.tembo_staging ts ;

/* some numbers start with +254, 
 * some numbers have (-) in them, remove dashes
 * standerdize t start with "07" */

-- ===========================================================================================================

/* guest city */

select distinct(guest_city)
from tembo.tembo_staging ts 
order by ts.guest_city ;

/* case issues, spelling issues eg Thikax => Thika */

-- ===========================================================================================================
/* guest nationality */

select distinct(guest_nationality)
from tembo.tembo_staging ts ;

/* case issue standerdize to proper case */


-- ===========================================================================================================

/* room no */

select distinct(room_no)
from tembo.tembo_staging ts ;

-- ===========================================================================================================

/* room type */

select distinct(room_type)
from tembo.tembo_staging ts ;

/* Normalization issue
 * DLX, deluxe => Deluxe
 * Std, standard => Standard
 */

-- ===========================================================================================================

/* room rate per night */

select distinct(room_rate_per_night)
from tembo.tembo_staging ts ;

-- ===========================================================================================================

/* check in date */

select distinct(check_in_date)
from tembo.tembo_staging ts ;

/* some dates in format 
 * dd-mm-yyyy
 * mm-dd-yyyy
 * dd-mm-yy
 * dd/mm/yyyy
 * should be in yyyy-mm-dd
 */

-- ===========================================================================================================

/* check out date */

select distinct(check_out_date)
from tembo.tembo_staging ts;

/* some dates in format 
 * dd-mm-yyyy
 * mm-dd-yyyy
 * dd-mm-yy
 * dd/mm/yyyy
 * should be in yyyy-mm-dd
 */


-- ===========================================================================================================

/* nights stayed */

select distinct(nights_stayed),
		count(*) as total_count, 
from tembo.tembo_staging ts 
group by ts.nights_stayed ;

/* -3 nights stayed in one column */

select *
from tembo.tembo_staging ts 
where ts.nights_stayed  = '-3';
/* viewing row where nights tayed is -3 to figure best way to reslve it. 
 * check in on 2024-10-05 
 * check out date is 2024-10-02
 * 
 */

-- ===========================================================================================================

/* staff name */

select distinct(staff_name)
from tembo.tembo_staging ts
order by ts.staff_name ;

-- ===========================================================================================================

/* staff department */

select distinct (staff_department)
from tembo.tembo_staging ts
order by ts.staff_department ;

-- ===========================================================================================================

/* staff salary */

select distinct (staff_salary)
from tembo.tembo_staging ts ;

/* some rows have "KES , " should be empty */

-- ===========================================================================================================

/* payment method */

select distinct(payment_method), count(*)
from tembo.tembo_staging ts
group by ts.payment_method ;

/* M-Pesa => mpesa */

-- ===========================================================================================================

/* booking status */

select distinct(booking_status)
from tembo.tembo_staging ts;

/* case issue, stabderdize to proper case */

-- ===========================================================================================================

/* total amount */

select distinct(total_amount), 
count(*) as total_count
from tembo.tembo_staging ts
group by ts.total_amount ; 

/* some rows have KES prefix => remove it,
 * blank rows 
 * some rows have a thousands operatot (,), remove it
 */

-- ===========================================================================================================

/* service used */

select distinct(service_used)
from tembo.tembo_staging ts 
order by ts.service_used ;


-- ===========================================================================================================

/* service price */

select distinct(service_price), count(*) as total_count
from tembo.tembo_staging ts 
group by ts.service_price ;

-- ===========================================================================================================

/* guest rating */

select distinct(guest_rating), count(*) as total_count
from tembo.tembo_staging ts 
group by guest_rating
order by ts.guest_rating ;

/* whitesapce issue,
 *  ratings above 5 ie 8 rows have a rating of 6
 * ratings below 1, ie 6 rows have a rating of 0
 * blank ratings, 
