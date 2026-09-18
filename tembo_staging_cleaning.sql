set search_path to tembo;

-- ===========================================================================================================

/* booking_id */


select distinct(booking_id), count(*) as total 
from tembo.tembo_staging ts
group by ts.booking_id 
order by total desc;

/* BK0006 appears twice */

/* viewing all rows where BK0006 appears to confirm its a duplicate */
select * 
from tembo.tembo_staging ts 
where ts.booking_id  = 'BK0006';

/* removing duplicate */

delete from tembo.tembo_staging 
where ctid not in 
	(select min(ctid) from tembo.tembo_staging ts  group by ts.booking_id );


-- ===========================================================================================================

/* guest name */

select distinct(guest_name)
from tembo.tembo_staging ts 
group by ts.guest_name 
order by ts.guest_name ;

/* case issue, whitespace issue at start of names */

select guest_name 
from tembo.tembo_staging ts 
where ts.guest_name != initcap(trim(guest_name));

update tembo.tembo_staging ts 
set guest_name = initcap(trim(guest_name))
where ts.guest_name != initcap(trim(guest_name));

-- ===========================================================================================================

/* guest phone */

select distinct(guest_phone)
from tembo.tembo_staging ts ;

/* some numbers start with +254, 
 * some numbers have (-) in them, remove dashes
 * standerdize t start with "07" */

SELECT 
    ts.guest_phone 
FROM tembo.tembo_staging ts 
-- checking phone numners satrting with "+254" or having a (-) separator.
WHERE guest_phone LIKE '+254%' OR guest_phone LIKE '%-%'; 
-- 28 phone numbers with issues

-- filtering out driver phone with a - separator

select guest_phone
from tembo.tembo_staging ts 
where guest_phone like '%-%'; -- 14 rows

update tembo.tembo_staging ts 
set guest_phone = regexp_replace(guest_phone,'[^0-9]','','g') -- replacing all non numeric characters with an empty field to remove the -
where ts.guest_phone like '%-%';


-- filtering out driver phone starting with "+254"

select guest_phone 
from tembo.tembo_staging ts 
where ts.guest_phone like '+254%';  -- 14 rows 

update tembo.tembo_staging ts 
set guest_phone = '0' || SUBSTRING(REGEXP_REPLACE(guest_phone,'[^0-9]','','g'),4)
where ts.guest_phone like '+254%';

/* removing leading whitespace */

select guest_phone 
from tembo.tembo_staging ts 
where ts.guest_phone != trim(guest_phone);

update tembo.tembo_staging ts 
set guest_phone = trim(guest_phone)
where ts.guest_phone != trim(guest_phone);


-- ===========================================================================================================

/* guest city */

select distinct(guest_city)
from tembo.tembo_staging ts 
order by ts.guest_city ;

/* case issues, spelling issues eg Thikax => Thika */

select ts.guest_city  
from tembo.tembo_staging ts 
where ts.guest_city != initcap(trim(guest_city));

/* setting all guset cities to proper case */

update tembo.tembo_staging ts 
set guest_city = initcap(trim(guest_city))
where ts.guest_city != initcap(trim(guest_city));

/* fixing splelling errors */

update tembo.tembo_staging ts 
set guest_city = case
	when guest_city in ('Thikax') then 'Thika'
	else guest_city
end;


-- ===========================================================================================================
/* guest nationality */

select distinct(guest_nationality)
from tembo.tembo_staging ts ;

/* case issue standerdize to proper case */

select guest_nationality, count(*)
from tembo.tembo_staging ts 
where ts.guest_nationality != initcap(trim(guest_nationality))
group by guest_nationality;


update tembo.tembo_staging ts 
set guest_nationality = initcap(trim(guest_nationality))
where ts.guest_nationality != initcap(trim(guest_nationality));

-- ===========================================================================================================

/* room no */

select distinct(room_no), count(*) as count
from tembo.tembo_staging ts
group by ts.room_no ;

-- ===========================================================================================================

/* room type */

select distinct(room_type)
from tembo.tembo_staging ts ;

/* Normalization issue
 * DLX, deluxe => Deluxe
 * Std, standard => Standard
 */

select ts.room_type  
from tembo.tembo_staging ts 
where ts.room_type != initcap(trim(room_type));

/* setting all guest cities to proper case */

update tembo.tembo_staging ts 
set room_type = initcap(trim(room_type))
where ts.room_type != initcap(trim(room_type));

/* fixing splelling errors */

update tembo.tembo_staging ts 
set room_type = case
	when room_type in ('Dlx') then 'Deluxe'
	when room_type in ('Std') then 'Standard'
	else room_type
end;


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

/* viewing dates not in the format yyyy-mm-dd */
SELECT 
    check_in_date 
FROM tembo.tembo_staging ts 
WHERE check_in_date NOT SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}';


-- fixing dates in format dd/mm/yyyy

select check_in_date
from tembo.tembo_staging ts 
where check_in_date like '%/%'; 

UPDATE tembo.tembo_staging ts 
SET check_in_date = TO_DATE(check_in_date,'DD/MM/YYYY')::TEXT
WHERE check_in_date LIKE '%/%';


/*  checking dates with - separator */

select check_in_date
from tembo.tembo_staging ts 
where check_in_date like '%-%' and ts.check_in_date SIMILAR to '[0-9]{2}-[0-9]{2}-[0-9]{4}';

/* some dates in dd-mm-yyyy
 * some days in mm-dd-yyyy
 */

-- filtering out dates in  mm-dd-yyyy format

SELECT check_in_date
FROM tembo.tembo_staging ts 
WHERE check_in_date LIKE '%-%'
  AND LENGTH(check_in_date) = 10
  AND SPLIT_PART(check_in_date,'-',1)::INTEGER <= 12;
  

UPDATE tembo.tembo_staging ts 
SET check_in_date = TO_DATE(check_in_date,'MM-DD-YYYY')::TEXT
WHERE check_in_date LIKE '%-%'
  AND LENGTH(check_in_date) = 10
  AND SPLIT_PART(check_in_date,'-',1)::INTEGER <= 12; 


/* filtering out dates in dd-mm-yyyy */

SELECT check_in_date
FROM tembo.tembo_staging ts 
WHERE check_in_date LIKE '%-%'
  AND LENGTH(check_in_date) = 10
  AND SPLIT_PART(check_in_date,'-',1)::INTEGER > 12 
	and check_in_date SIMILAR to '[0-9]{2}-[0-9]{2}-[0-9]{4}';


UPDATE tembo.tembo_staging ts 
SET check_in_date = TO_DATE(check_in_date,'DD-MM-YYYY')::TEXT
WHERE check_in_date LIKE '%-%'
  AND LENGTH(check_in_date) = 10
  AND SPLIT_PART(check_in_date,'-',1)::INTEGER > 12
	and check_in_date SIMILAR to '[0-9]{2}-[0-9]{2}-[0-9]{4}';


/* fixing dates in dd-mm-yy */

select check_in_date
from tembo.tembo_staging ts 
where check_in_date like '%-%' and LENGTH(check_in_date) = 8; -- 13 dates in this format

UPDATE tembo.tembo_staging ts 
SET check_in_date = TO_DATE(check_in_date,'DD-MM-YY')::TEXT
WHERE check_in_date LIKE '%-%' AND LENGTH(check_in_date) = 8;


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

/* viewing dates not in the format yyyy-mm-dd */
SELECT 
    check_out_date 
FROM tembo.tembo_staging ts 
WHERE check_out_date NOT SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}';  -- 43 dates


-- fixing dates in format dd/mm/yyyy

select check_out_date
from tembo.tembo_staging ts 
where check_out_date like '%/%'; 

UPDATE tembo.tembo_staging ts 
SET check_out_date = TO_DATE(check_out_date,'DD/MM/YYYY')::TEXT
WHERE check_out_date LIKE '%/%';


/*  checking dates with - separator */

select check_out_date
from tembo.tembo_staging ts 
where check_out_date like '%-%' and ts.check_out_date SIMILAR to '[0-9]{2}-[0-9]{2}-[0-9]{4}';  -- 15 dates

/* some dates in format dd-mm-yyyy
 * some in format mm-dd-yyyy */


-- filtering out dates in  mm-dd-yyyy format

SELECT check_out_date
FROM tembo.tembo_staging ts 
WHERE check_out_date LIKE '%-%'
  AND LENGTH(check_out_date) = 10
  AND SPLIT_PART(check_out_date,'-',1)::INTEGER <= 12; -- 14 dates
  

UPDATE tembo.tembo_staging ts 
SET check_out_date = TO_DATE(check_out_date,'MM-DD-YYYY')::TEXT
WHERE check_out_date LIKE '%-%'
  AND LENGTH(check_out_date) = 10
  AND SPLIT_PART(check_out_date,'-',1)::INTEGER <= 12; 


/* filtering out dates in dd-mm-yyyy */

SELECT check_out_date
FROM tembo.tembo_staging ts 
WHERE check_out_date LIKE '%-%'
  AND LENGTH(check_out_date) = 10
  AND SPLIT_PART(check_out_date,'-',1)::INTEGER > 12 
	and check_out_date SIMILAR to '[0-9]{2}-[0-9]{2}-[0-9]{4}'; -- 1 date


UPDATE tembo.tembo_staging ts 
SET check_out_date = TO_DATE(check_out_date,'DD-MM-YYYY')::TEXT
WHERE check_out_date LIKE '%-%'
  AND LENGTH(check_out_date) = 10
  AND SPLIT_PART(check_out_date,'-',1)::INTEGER > 12
	and check_out_date SIMILAR to '[0-9]{2}-[0-9]{2}-[0-9]{4}';


-- ===========================================================================================================

/* nights stayed */

select distinct(nights_stayed),
		count(*) as total_count 
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

select nights_stayed
from tembo.tembo_staging ts  
where nights_stayed like '-%'; 		-- selecting row starting with - prefix 


UPDATE tembo.tembo_staging ts 
SET nights_stayed = REGEXP_REPLACE(nights_stayed,'[^0-9.]','','g') -- replacing all characters not in range 0-9 with empty value to remove them.
WHERE nights_stayed SIMILAR TO '%[^0-9.]%';


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

select staff_salary
from tembo.tembo_staging ts  
where staff_salary like 'KES%'; 		-- selecting rows starting with KES prefix - 14 rows


UPDATE tembo.tembo_staging ts 
SET staff_salary = REGEXP_REPLACE(staff_salary,'[^0-9.]','','g') -- replacing all characters not in range 0-9 with empty value to remove them.
WHERE staff_salary SIMILAR TO '%[^0-9.]%';

-- ===========================================================================================================

/* payment method */

select distinct(payment_method), count(*)
from tembo.tembo_staging ts
group by ts.payment_method ;

/*  mpesa => M-Pesa  */

update tembo.tembo_staging ts 
set payment_method = initcap(trim(payment_method))
where ts.payment_method != initcap(trim(payment_method));

/* fixing splelling errors */

update tembo.tembo_staging ts 
set payment_method = case
	when payment_method in ('Mpesa') then 'M-Pesa'
	else payment_method
end;

-- ===========================================================================================================

/* booking status */

select distinct(booking_status)
from tembo.tembo_staging ts;

/* case issue, stabderdize to proper case */

select ts.booking_status  
from tembo.tembo_staging ts 
where ts.booking_status != initcap(trim(booking_status));

/* setting all booking status to proper case */

update tembo.tembo_staging ts 
set booking_status = initcap(trim(booking_status))
where ts.booking_status != initcap(trim(booking_status));



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

select total_amount
from tembo.tembo_staging ts  
where total_amount like 'KES%'; 		-- selecting rows starting with KES prefix - 14 rows


UPDATE tembo.tembo_staging ts 
SET total_amount = REGEXP_REPLACE(total_amount,'[^0-9.]','','g') -- replacing all characters not in range 0-9 with empty value to remove them.
WHERE total_amount SIMILAR TO '%[^0-9.]%';


-- ===========================================================================================================

/* service used */

select distinct(service_used), count(*) as total_count
from tembo.tembo_staging ts 
group by ts.service_used 
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
 * blank ratings, */

select ts.guest_rating, count(*) as count
from tembo.tembo_staging ts 
where ts.guest_rating != trim(guest_rating)
group by guest_rating ;

/* setting all guest cities to proper case */

update tembo.tembo_staging ts 
set guest_rating = trim(guest_rating)
where ts.guest_rating != trim(guest_rating);

/* fixing ratings beyond the scope */

SELECT count(*) as invalid_rating_count
FROM tembo.tembo_staging ts 
WHERE guest_rating NOT IN ('1','2','3','4','5',''); -- 14 rows/records counted

UPDATE tembo.tembo_staging ts 
SET guest_rating = NULL
WHERE TRIM(guest_rating) NOT IN ('1','2','3','4','5','');

-- ===========================================================================================================

select * from tembo.tembo_staging ts;



