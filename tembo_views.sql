set search_path to tembo;

-- ===========================================================================================================
drop view v_tembo_clean_bookings;

create or replace view v_tembo_clean_bookings as 
	select 
		b.booking_id,
		b.guest_id,
		b.room_no,
		b.check_in_date,
		b.check_out_date,
		b.nights_stayed,
		b.staff_id,
		b.payment_method,
		b.booking_status,
		b.total_amount,
		b.service_id,
		b.guest_rating,
		COALESCE(s.service_price, 0) as service_price,
		TO_CHAR(b.check_in_date, 'YYYY-MM') AS month,
		b.total_amount + COALESCE(s.service_price, 0) as total_revenue
	from tembo.bookings b
	join tembo.services s on b.service_id = s.service_id ;

-- ===========================================================================================================

create or replace view v_tembo_clean_guests as 
	select *
	from tembo.guests;

-- ===========================================================================================================

create or replace view v_tembo_clean_rooms as 
	select *
	from tembo.rooms;

-- ===========================================================================================================

create or replace view v_tembo_clean_services as 
	select *
	from tembo.services;

-- ===========================================================================================================

create or replace view v_tembo_clean_staff as 
	select *
	from tembo.staff;
-- ===========================================================================================================


create or replace view v_tembo_revenue_by_month as 
	WITH monthly_revenue AS (
	    SELECT
	        TO_CHAR(b.check_in_date, 'YYYY-MM') AS month,
	        sum(total_amount) as room_revenue,
			coalesce(sum(s.service_price), 0) as service_revenue,
			sum(total_amount) + coalesce(sum(s.service_price), 0) as total_revenue
	    FROM tembo.bookings b
	    join services s on b.service_id = s.service_id 
	    WHERE b.booking_status = 'Checked Out'
	    GROUP BY TO_CHAR(b.check_in_date, 'YYYY-MM')
	)
	SELECT
	    month,
	    total_revenue,
	    LAG(total_revenue) OVER (ORDER BY month) AS previous_month_revenue,
	    total_revenue - LAG(total_revenue) OVER (ORDER BY month) AS revenue_change,
	    ROUND(
		        (
		            (total_revenue - LAG(total_revenue) OVER (ORDER BY month))
		           		 / NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0)
		        ) * 100,
		        2
		    ) AS revenue_growth_percentage
	FROM monthly_revenue
	ORDER BY month;


-- ===========================================================================================================


create or replace view v_tembo_revenue_by_room_type as
	select
			b.room_no,
			r.room_type,
			sum(b.total_amount) + coalesce(sum(s.service_price), 0) as total_revenue
	from tembo.bookings b 
	join tembo.rooms r on b.room_no = r.room_no 
	join services s on b.service_id = s.service_id 
	group by b.room_no, r.room_type 
	order by total_revenue desc ;


-- ===========================================================================================================


create or replace view v_tembo_room_occupancy as 
	SELECT
	    b.room_no,
	    r.room_type,
	    COUNT(*) AS bookings_count,
	    SUM(b.nights_stayed) AS occupied_nights,
	    ROUND(AVG(b.nights_stayed), 2) AS avg_nights
	FROM tembo.bookings b
	JOIN tembo.rooms r
	    ON b.room_no = r.room_no
	WHERE b.booking_status = 'Checked Out'
	GROUP BY
	    b.room_no,
	    r.room_type
	ORDER BY occupied_nights DESC;

-- ===========================================================================================================


create or replace view v_tembo_revenue_loss as 
	select b.room_no,
			r.room_type,
			sum(b.total_amount) as room_revenue_lost,
			coalesce(sum(s.service_price), 0) as servive_rev_lost,
			sum(b.total_amount) + coalesce(SUM(s.service_price ), 0) as total_rev_loss
	from tembo.bookings b 
	join services s on b.service_id = s.service_id 
	join tembo.rooms r on b.room_no = r.room_no 
	where b.booking_status != 'Checked Out'
	group by b.room_no, r.room_type
	order by total_rev_loss desc;

-- ===========================================================================================================


create or replace view v_tembo_guest_insights as 
	select 
		b.guest_id,
		g.guest_name,
		g.guest_city,
		count(*) as total_bookings,
		sum(b.nights_stayed ) as total_nights,
		round(avg(b.guest_rating ), 2) as avg__guest_rating
from tembo.bookings b 
join tembo.guests g on b.guest_id = g.guest_id 
group by b.guest_id, g.guest_name , g.guest_city 
order by total_bookings desc;


-- ===========================================================================================================


create or replace view v_tembo_cancellations_by_month as 
	SELECT
	    TO_CHAR(b.check_in_date, 'YYYY-MM') AS month,
	    COUNT(*) AS total_bookings,
	    COUNT(*) FILTER (
	        WHERE booking_status = 'Cancelled'
	    ) AS cancelled_bookings,
	    COUNT(*) FILTER (
	        WHERE booking_status = 'No Show'
	    ) AS no_show_bookings,
	    ROUND(
	        COUNT(*) FILTER (
	            WHERE booking_status = 'Cancelled'
	        ) * 100.0 / COUNT(*),
	        2
	    ) AS cancellation_rate,
	    ROUND(
	        COUNT(*) FILTER (
	            WHERE booking_status = 'No Show'
	        ) * 100.0 / COUNT(*),
	        2
	    ) AS no_show_rate
	FROM tembo.bookings b
	GROUP BY TO_CHAR(b.check_in_date, 'YYYY-MM')
	ORDER BY month;
	
