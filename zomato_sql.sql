-- EDA

-- importing data


SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;



-- 1.  Popular Time slot: 
--Identify the time Slots during which the most orders are placed based on 2 hours interval

SELECT 
     case 
		when extract(HOUR from order_time) between 0 and 1 then '00:00 - 02:00'
		when extract(HOUR from order_time) between 2 and 3 then '02:00 - 04:00'
		when extract(HOUR from order_time) between 4 and 5 then '04:00 - 06:00'
		when extract(HOUR from order_time) between 6 and 7 then '06:00 - 08:00'
		when extract(HOUR from order_time) between 8 and 9 then '08:00 - 10:00'
		when extract(HOUR from order_time) between 10 and 11 then '11:00 - 12:00'
		when extract(HOUR from order_time) between 12 and 13 then '12:00 - 14:00'
		when extract(HOUR from order_time) between 14 and 15 then '14:00 - 16:00'
		when extract(HOUR from order_time) between 16 and 17 then '16:00 - 18:00'
		when extract(HOUR from order_time) between 18 and 19 then '18:00 - 20:00'
		when extract(HOUR from order_time) between 20 and 21 then '20:00 - 22:00'
		when extract(HOUR from order_time) between 22 and 23 then '22:00 - 00:00'
	end as time_slot,
	count(order_id) as order_count
	from orders
	group by time_slot
	order by order_count desc
	
	
		
  -- 2. High Value Customers:
  --List the Customers who have spent more than 100K in total on food orders.
  --Return customer_name,  customer_id, total_spent	
     

 SELECT 
c.customer_id, 
c.customer_name,
 SUM(o.total_amount) Total_Spent
 FROM Customers c
 JOIN Orders o
 ON c.customer_id = o.customer_id
 GROUP BY c.customer_id, 
c.customer_name
 HAVING 
SUM(o.total_amount) > 100000
 ORDER BY 
SUM(o.total_amount) DESC


-- 3.Orders without Delivery: 
-- Write query to find orders that were placed but not delivered
--Return each restaurant name, city and number of not delivered orders



 SELECT  
r.restaurant_name, 
r.city, 
COUNT(o.order_id) AS Total_Not_Delivered_Orders
 FROM 
Orders o
 LEFT JOIN Deliveries d 
ON o.order_id = d.order_id
 LEFT JOIN Restaurants r 
ON r.restaurant_id = o.restaurant_id
 WHERE 
d.delivery_status = 'Not Delivered' 
OR d.delivery_status IS NULL  
GROUP BY
r.restaurant_name, r.city
 ORDER BY 
Total_Not_Delivered_Orders DESC




 --4. Restaurant Revenue Ranking: 
 --Rank restaurants by their total reveneu from the last year.
 -- Return their name, Total Revenue, and rank within their city

 SELECT
 r.city,
 r.restaurant_name, 
SUM(o.total_amount) Revenue, 
DENSE_RANK() OVER(PARTITION BY city ORDER BY SUM(total_amount) DESC) 
Rank_of_Restaurant
 FROM Orders o
 LEFT JOIN Restaurants r
 ON r.restaurant_id = o.restaurant_id
 GROUP BY city, r.restaurant_name



 --5. Top 2 Restaurant in their City based on Their Highest Revenue Revenue
 WITH cte 
AS (
 SELECT
 r.city City,
 r.restaurant_name Restaurant, 
SUM(o.total_amount) Revenue, 
DENSE_RANK() OVER(PARTITION BY city ORDER BY SUM(total_amount) DESC) 
Rank_of_Restaurant
 FROM Orders o
 LEFT JOIN Restaurants r
 ON r.restaurant_id = o.restaurant_id
 GROUP BY city, r.restaurant_name
 )
 SELECT * FROM cte
 WHERE Rank_of_Restaurant <= 2


  --6. Most popular dish by City:
 --Identify the Most Popular dish in each city based on the number of orders
 
 
 
 WITH Most_Popular_dish
AS
 (SELECT 
city, 
order_item as Dishes,
 COUNT(order_id) Nr_of_Orders, 
DENSE_RANK() OVER(PARTITION BY city ORDER BY COUNT(order_id)DESC) 
Rank_of_Dish
 FROM Orders o
 LEFT JOIN Restaurants r
 ON r.restaurant_id = o.restaurant_id
 GROUP BY city, order_item
 )
 SELECT * FROM Most_Popular_dish
 WHERE Rank_of_Dish = 1
 ORDER BY 
Nr_of_Orders DESC



 --7. Customer Churn:
 --Find Customers who haven't placed an order in 2024 but did in 2023

 
 SELECT DISTINCT c.* FROM Orders o
 LEFT JOIN Customers c
 ON o.customer_id = c.customer_id
 WHERE
eXTRACT(YEAR FROM o.order_date) = 2023
 AND 
c.customer_id NOT IN 
(SELECT DISTINCT customer_id FROM Orders
 WHERE EXTRACT(YEAR FROM order_date) = 2024)
 ORDER BY c.customer_id




  --8. Customer Segmentations:
 --(1) Segment Customers into "Gold" or "Silver" groups based on their total spending
 --(2) Compare to the Average Order Value
--If Customer's total spending  exceeds AOV Label them with gold other wise label 
--them as  silver
 --Write a Query to Determine each segment's total number of orders and total revenue

 SELECT 
 Customer_Category,
 SUM(Total_Spend) Total_Revenue,
 SUM(Nr_of_Orders) Total_Orders
FROM 
(
 SELECT 
 c.customer_name,
 COUNT(o.order_id) Nr_of_Orders,
 SUM(o.total_amount) Total_Spend,
 CASE
 WHEN SUM(o.total_amount)> (SELECT AVG(total_amount) from Orders) THEN
 'Gold'
  ELSE 'Silver'
 END as Customer_Category
 FROM Orders o
 JOIN Customers c
 ON c.customer_id = o.customer_id
 GROUP BY 
c.customer_id,
 c.customer_name
 ) as t2
 GROUP BY Customer_Category
 order by total_revenue desc




 --9.  Order Item Popularity :
 --Track the Popularity of specific order items over time and identify seasonal demand spike

 SELECT order_item,Season, COUNT(order_id) Nr_of_Orders
 FROM (
 SELECT 
*, 
CASE 
WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 5 THEN 'Summer' 
WHEN EXTRACT(MONTH FROM order_date) BETWEEN 6 AND 9 THEN  'Monsoon'
 WHEN EXTRACT(MONTH FROM order_date) BETWEEN 10 AND 11 THEN  'Autumn'
 WHEN EXTRACT(MONTH FROM order_date) IN ( 11, 12, 1, 2) THEN  'Winter'
 END Season
 FROM Orders
 ) t1
 GROUP BY order_item,
 Season
 ORDER BY 
order_item,
 Nr_of_Orders DESC


 -- 10.Rank each City based on the Total revenue for last year 2023
 SELECT 
r.city, 
SUM(o.total_amount) Total_Revenue,
 RANK() OVER(ORDER BY SUM(o.total_amount) DESC) Rank_of_City_by_Revenue 
FROM Orders o
 LEFT JOIN Restaurants r
 ON r.restaurant_id = o.restaurant_id
 WHERE extract(YEAR from order_date) = 2023
 GROUP BY r.city



 --11.   Rider Average Delivery Time
 --Determine each rider's average delivery tim
 
 WITH Riders_Avg_Delivery_Time AS (
  SELECT
    r.rider_id,
    r.rider_name,
    o.order_time,
    d.delivery_time,
   
    CASE
      WHEN d.delivery_time < o.order_time THEN
        (1440 - ABS(EXTRACT(EPOCH FROM (o.order_time - d.delivery_time)) / 60))
      ELSE
        (ABS(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time)) / 60))
    END::numeric(10,2) AS time_taken_to_deliver
  FROM orders o
  LEFT JOIN deliveries d
    ON o.order_id = d.order_id
  LEFT JOIN riders r
    ON d.rider_id = r.rider_id
  WHERE d.delivery_status = 'Delivered'
)
SELECT
  rider_id,
  rider_name,
  ROUND(AVG(time_taken_to_deliver)::numeric, 2)::numeric(10,2) AS avg_time_by_riders_in_mins
FROM Riders_Avg_Delivery_Time
GROUP BY rider_id, rider_name
ORDER BY rider_id;



--12.  Rider Effeciency
 --Evaluate rider Effeciency by determining Average Delivery times and Identifying 
--those with lowest And highest Average Delivery time



WITH time_to_deliver AS (
	SELECT ord.order_id,
		delv.rider_id,
		ord.order_time,
		delv.delivery_time,
		EXTRACT(EPOCH FROM (delv.delivery_time - ord.order_time + 
		CASE WHEN delv.delivery_time < ord.order_time THEN INTERVAL '1 DAY'
			ELSE INTERVAL '0 DAY' 
		END )) / 60 AS delivery_process_time
	FROM orders ord
	JOIN deliveries delv 
		ON ord.order_id = delv.order_id
	WHERE delv.delivery_status = 'Delivered'
)
SELECT 
	rider_id,
    AVG(CASE
            WHEN delivery_process_time < 30 THEN 5
            WHEN delivery_process_time BETWEEN 30 AND 55 THEN 4
            ELSE 3
        END) AS average_star_rating
FROM time_to_deliver
GROUP BY rider_id
order by rider_id



--13.  Monthly Restaurant Growth Ratio:
 --Calculate each restaurant's growth ratio based on the total number of delivered 
--orders since its joining


WITH Growth_Rate_of_Delivered_Orders AS (
    SELECT
        o.restaurant_id,
        EXTRACT(YEAR FROM o.order_date)::int AS order_year,
        EXTRACT(MONTH FROM o.order_date)::int AS order_month,
        TO_CHAR(o.order_date, 'Mon YYYY') AS month_year,
        COUNT(d.delivery_id)::numeric(10,2) AS current_month_orders_delivered,
        LAG(COUNT(d.delivery_id)) OVER (
            PARTITION BY o.restaurant_id 
            ORDER BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
        )::numeric(10,2) AS prev_month_orders_delivered
    FROM orders o
    LEFT JOIN deliveries d 
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY 
        o.restaurant_id, 
        EXTRACT(YEAR FROM o.order_date), 
        EXTRACT(MONTH FROM o.order_date), 
        TO_CHAR(o.order_date, 'Mon YYYY')
)
SELECT 
    restaurant_id,
    month_year,
    current_month_orders_delivered,
    prev_month_orders_delivered,
    ROUND(
        ((current_month_orders_delivered - prev_month_orders_delivered) 
        / NULLIF(prev_month_orders_delivered, 0)) * 100, 2
    ) AS growth_rate_in_orders_delivered
FROM Growth_Rate_of_Delivered_Orders
ORDER BY 
    restaurant_id, 
    order_year,
    order_month;





	--14.Rider Monthly Earning:
 --Calculate each ride's total monthly earnings, assuming they earn 8% of the 
--Delivered Order Amount


WITH Riders_Monthly_Earning AS (
  SELECT
    rd.rider_id,
    rd.rider_name,
    EXTRACT(YEAR FROM o.order_date)::int AS order_year,
    EXTRACT(MONTH FROM o.order_date)::int AS order_month,
    TO_CHAR(o.order_date, 'FMMonth YYYY') AS month_year,
    SUM(o.total_amount)::numeric * 0.08 AS total_earning_of_rider -- result as numeric
  FROM orders o
  JOIN deliveries d ON o.order_id = d.order_id
  JOIN riders rd ON rd.rider_id = d.rider_id
  WHERE d.delivery_status = 'Delivered'
  GROUP BY rd.rider_id, rd.rider_name, order_year, order_month, month_year
)
SELECT
  rider_id,
  rider_name,
  month_year,
  ROUND(total_earning_of_rider, 2) AS total_earning_of_rider
FROM Riders_Monthly_Earning
ORDER BY rider_id, order_year, order_month;



-- 15. Rider Rating Analysis:
 --Find the number of 5 Star. 4 star, and 3 star rating Each riders has.
 --Riders recieve this rating based on delivery time
 --IF orders are delivered less than 15 Minutes of order recieved time the rider 
--get 5 star rating.
 --IF they delivery is 15 to 20 Minute then they get a 4 star rating
 --IF they deliver after 20 Minute they get 3 star rating



 WITH main_cte AS (
    SELECT 
        d.rider_id AS rider_id,
        o.order_time,
        d.delivery_time,
        -- Calculate time taken to deliver in minutes, handling midnight wrap
        CASE 
            WHEN d.delivery_time < o.order_time 
                THEN 1440 - ABS(EXTRACT(EPOCH FROM (o.order_time - d.delivery_time)) / 60)
            ELSE ABS(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time)) / 60)
        END AS time_taken_to_deliver
    FROM orders o
    JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
final AS (
    SELECT
        rider_id,
        CASE 
            WHEN time_taken_to_deliver <= 15 THEN '5 Star'
            WHEN time_taken_to_deliver > 15 AND time_taken_to_deliver <= 20 THEN '4 Star'
            ELSE '3 Star'
        END AS stars
    FROM main_cte
)
SELECT
    rider_id,
    stars,
    COUNT(stars) AS total_stars
FROM final
GROUP BY rider_id, stars
ORDER BY rider_id, total_stars DESC;



--16.  Order Frequency by Day:
 --Analyze order fequency per day of the week and identify the peak day for each 
--restaurant




 WITH order_counts AS (
  SELECT
    o.restaurant_id,
    r.restaurant_name AS restaurant,
    EXTRACT(DOW FROM o.order_date)::int AS week_number, -- 0=Sunday–6=Saturday
    TO_CHAR(o.order_date, 'Day') AS weekday_name,
    COUNT(o.order_id) AS nr_of_orders
  FROM orders o
  LEFT JOIN restaurants r
    ON r.restaurant_id = o.restaurant_id
  GROUP BY
    o.restaurant_id,
    r.restaurant_name,
    week_number,
    weekday_name
),
ranked AS (
  SELECT
    restaurant_id,
    restaurant,
    week_number,
    TRIM(weekday_name) AS weekday_name,
    nr_of_orders,
    DENSE_RANK() OVER (
      PARTITION BY restaurant_id
      ORDER BY nr_of_orders DESC
    ) AS rank_of_week_day
  FROM order_counts
)
SELECT
  restaurant,
  weekday_name,
  nr_of_orders,
  rank_of_week_day
FROM ranked
WHERE rank_of_week_day = 1
ORDER BY nr_of_orders DESC, restaurant;



--17. Customer Lifetime value(CLV)
 --Calculate the Total Revenue Generated by each customer over all  their orders

 
 SELECT
 c.customer_id, 
c.customer_name, 
SUM(o.total_amount) Customer_Lifetime_Value FROM Orders o
 JOIN Customers c
 ON c.customer_id = o.customer_id
 GROUP BY c.customer_id, c.customer_name
 ORDER BY 
SUM(o.total_amount) DESC



--18. Monthly Sales Trends:
 --Identify Sales Trends by Comparing each month's total Sales to the previous 
--months


 
 WITH monthly_sales AS (
  SELECT
    EXTRACT(YEAR FROM order_date)::int AS year,
    EXTRACT(MONTH FROM order_date)::int AS month_number,
    TO_CHAR(order_date, 'Mon YYYY') AS month_name,
    SUM(total_amount)::numeric AS current_month_sales
  FROM orders
  GROUP BY 1, 2, 3
),
sales_with_prev AS (
  SELECT
    year,
    month_number,
    month_name,
    current_month_sales,
    LAG(current_month_sales) OVER (ORDER BY year, month_number) AS prev_month_sales
  FROM monthly_sales
)
SELECT
  year,
  month_number,
  month_name,
  current_month_sales,
  prev_month_sales,
  ROUND(
    (current_month_sales - prev_month_sales)
    / NULLIF(prev_month_sales, 0) * 100, 2
  ) AS percent_growth_in_sales
FROM sales_with_prev
ORDER BY year, month_number;



--19.  Order Value Analysis: Find the Average Order value per customer who has placed
 --more than 750 orders
-- Return Customer_name, and AOV(Average Order Value)


SELECT 
c.customer_id,
 c.customer_name,
 CAST(AVG(O.total_amount) AS decimal(10,2)) Avg_Order_Value
 FROM Customers c
 JOIN Orders o
 ON c.customer_id = o.customer_id
 GROUP BY c.customer_id, c.customer_name
 HAVING 
COUNT(o.order_id) > 750
 ORDER BY 
AVG(total_amount) DESC



--20.Rider timeline ratio:
-- For each rider compute how many delivery met the on time and how many late.
WITH rider_times AS (
  SELECT
    d.rider_id,
    CASE
      WHEN d.delivery_time < o.order_time THEN
        1440 - ABS(EXTRACT(EPOCH FROM (o.order_time - d.delivery_time)) / 60)
      ELSE
        ABS(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time)) / 60)
    END AS time_taken_minutes
  FROM orders o
  JOIN deliveries d
    ON o.order_id = d.order_id
  WHERE d.delivery_status = 'Delivered'
),
counts AS (
  SELECT
    rider_id,
    COUNT(*) FILTER (WHERE time_taken_minutes <= 30) AS on_time_count,
    COUNT(*) FILTER (WHERE time_taken_minutes > 30) AS late_count
  FROM rider_times
  GROUP BY rider_id
)
SELECT
  c.rider_id,
  r.rider_name,
  c.on_time_count,
  c.late_count,
  CASE
    WHEN c.on_time_count = 0 THEN NULL
    ELSE ROUND(c.late_count::numeric / c.on_time_count, 2)
  END AS late_on_time_ratio
FROM counts c
LEFT JOIN riders r
  ON r.rider_id = c.rider_id
ORDER BY c.rider_id;







