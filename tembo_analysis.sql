set search_path to tembo;

-- ===========================================================================================================

/* 					TEMBO ANALYSIS					*/

/*					 REVENUE ANALYSIS				 */

-- 1.	Revenue analysis: Total revenue by month,
--  by room type, by payment method

-- revenue by month

select
	date_trunc('month', b.check_in_date )::DATE as month,
	sum(total_amount) as room_revenue,
	coalesce(sum(s.service_price), 0) as service_revenue,
	sum(total_amount) + coalesce(sum(s.service_price), 0) as total_revenue
from tembo.bookings b
join services s on b.service_id = s.service_id 
where b.booking_status = 'Checked Out' 
group by date_trunc('month', b.check_in_date)
order by month;


select
	sum(total_amount) + coalesce(sum(s.service_price), 0) as total_revenue
from tembo.bookings b
join services s on b.service_id = s.service_id;


-- revenue by room type

select
		b.room_no,
		r.room_type,
		sum(b.total_amount) + coalesce(sum(s.service_price), 0) as total_revenue
from tembo.bookings b 
join tembo.rooms r on b.room_no = r.room_no 
join services s on b.service_id = s.service_id 
group by b.room_no , r.room_type 
order by total_revenue desc ;


-- revenue by payment method

select payment_method,
		sum(total_amount) + coalesce(sum(s.service_price), 0) as total_revenue
from tembo.bookings b 
join services s on b.service_id = s.service_id 
group by b.payment_method 
order by total_revenue desc;


-- ===========================================================================================================

-- ===========================================================================================================

/* 2.	Occupancy: Which room types are booked most? Average nights stayed per room type */


-- occupancy per room

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


-- bookings per room

select room_no,
		count(*) as bookings_count
from tembo.bookings b 
where b.booking_status = 'Checked Out'
group by b.room_no
order by bookings_count desc;


-- bookings per room type

select 
	r.room_type ,
	count(*) as bookings_count
from tembo.bookings b 
join tembo.rooms r on b.room_no = r.room_no 
group by r.room_type
order by bookings_count desc;


-- avg nights per room 

select room_no,
		round(avg(nights_stayed), 2) as nights
from tembo.bookings b 
group by b.room_no
order by nights desc;


-- avg nights per room type

select 
		room_type,
		round(avg(nights_stayed), 2) as nights
from tembo.bookings b 
join rooms r on b.room_no = r.room_no 
group by r.room_type 
order by nights desc;


-- ===========================================================================================================

-- ===========================================================================================================

/* 3.	Guest insights: Top 10 cities guests come from. Average rating per room type */

-- guest and no of bookings

select 
		g.guest_name,
		g.guest_city,
		count(*) as total_bookings,
		sum(b.nights_stayed ) as total_nights,
		round(avg(b.guest_rating ), 2) as avg__guest_rating
from tembo.bookings b 
join tembo.guests g on b.guest_id = g.guest_id 
group by g.guest_name , g.guest_city 
order by total_bookings desc;


-- guest city by total bookings and total nights stayed

select 
		g.guest_city,
		count(*) as total_bookings,
		sum(b.nights_stayed) as total_nights,
		round(avg(b.guest_rating), 2) as avg_rating
from tembo.bookings b 
join tembo.guests g on b.guest_id = g.guest_id 
join tembo.rooms r on b.room_no = r.room_no 
group by g.guest_city 
order by total_bookings desc;

-- ===========================================================================================================

-- ===========================================================================================================


/* 4.	Staff performance: Which staff handled the most bookings? 
 * Which department generates most revenue? */


-- staff member by total bookings served

select 
		s.staff_name,
		s.staff_department,
		count(*) as bookings_served,
		sum(b.total_amount) + coalesce(sum(s2.service_price), 0) as total_revenue
from tembo.bookings b 
join tembo.staff s on b.staff_id = s.staff_id 
join services s2 on b.service_id = s2.service_id 
group by s.staff_name, s.staff_department 
order by bookings_served  desc;



-- staff dept by bookings served and total revenue

select staff_department,
		count(*) as bookings_served,
		sum(b.total_amount) + coalesce(sum(s2.service_price), 0) as total_revenue
from tembo.bookings b 
join tembo.staff s on b.staff_id = s.staff_id
join services s2 on b.service_id = s2.service_id 
where b.booking_status = 'Checked Out'
group by s.staff_department 
order by bookings_served desc;



-- ===========================================================================================================

-- ===========================================================================================================


/* 5.	Trends: Revenue growth month over month (window function). 
 * Busiest vs quietest months */

-- Month over month growth


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', b.check_in_date)::DATE AS month,
        SUM(b.total_amount) + coalesce(sum(s.service_price), 0) AS revenue
    FROM tembo.bookings b
    join services s on b.service_id = s.service_id 
    WHERE b.booking_status = 'Checked Out'
    GROUP BY DATE_TRUNC('month', b.check_in_date)
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change,
    ROUND(
	        (
	            (revenue - LAG(revenue) OVER (ORDER BY month))
	           		 / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)
	        ) * 100,
	        2
	    ) AS revenue_growth_percentage
FROM monthly_revenue
ORDER BY month;



-- busiest vs quitest months


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', check_in_date)::DATE AS month,
        count(*) as total_bookings,
        SUM(total_amount) + coalesce(sum(s.service_price), 0) AS revenue
    FROM tembo.bookings b
    join services s on b.service_id = s.service_id 
    WHERE booking_status = 'Checked Out'
    GROUP BY DATE_TRUNC('month', check_in_date)
),
ranked_months AS (
    SELECT
        month,
        total_bookings,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS busiest_rank,
        RANK() OVER (ORDER BY revenue ASC) AS quietest_rank
    FROM monthly_revenue
)
SELECT
    month,
    total_bookings,
    revenue,
    busiest_rank,
    quietest_rank
FROM ranked_months
ORDER BY month;


-- ===========================================================================================================

-- ===========================================================================================================


/* 6.	Cancellations: Cancellation rate per room type. Revenue lost from cancellations and no-shows */

select * 
from tembo.bookings b 
where b.booking_status != 'Checked Out';


-- revenue lost per room

select room_no,
		sum(total_amount) as revenue_lost,
		coalesce(sum(s.service_price), 0) as servive_rev_lost,
		sum(b.total_amount) + coalesce(SUM(s.service_price ), 0) as total_rev_loss
from tembo.bookings b 
join services s on b.service_id = s.service_id 
where b.booking_status != 'Checked Out'
group by room_no
order by revenue_lost desc;


-- revenue lost per room type
select 
		r.room_type,
		sum(total_amount) as revenue_lost,
		coalesce(sum(s.service_price), 0) as servive_rev_lost,
		sum(b.total_amount) + coalesce(SUM(s.service_price ), 0) as total_rev_loss
from tembo.bookings b 
join tembo.rooms r on b.room_no = r.room_no 
join services s on b.service_id = s.service_id 
where b.booking_status != 'Checked Out'
group by r.room_type 
order by revenue_lost desc;

-- cancellation rate

SELECT
    booking_status,
    COUNT(*) AS booking_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM tembo.bookings
WHERE booking_status IN ('Checked Out', 'Cancelled', 'No Show')
GROUP BY booking_status
ORDER BY booking_count DESC;


-- cancellation by room type


SELECT
    r.room_type,
    COUNT(*) AS total_bookings,
    COUNT(*) FILTER (
        WHERE b.booking_status != 'Checked Out'
    ) AS cancelled_and_No_show_bookings,
    ROUND(
        COUNT(*) FILTER (
            WHERE b.booking_status != 'Checked Out'
        ) * 100.0 / COUNT(*), 2) AS cancellation_rate
FROM tembo.bookings b
JOIN tembo.rooms r
    ON b.room_no = r.room_no
GROUP BY r.room_type
ORDER BY cancellation_rate DESC;


-- cancellations by month


SELECT
    DATE_TRUNC('month', check_in_date)::DATE AS month,
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
FROM tembo.bookings
GROUP BY DATE_TRUNC('month', check_in_date)
ORDER BY month;















