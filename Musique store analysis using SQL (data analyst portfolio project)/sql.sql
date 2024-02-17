-- 1 who is the senior most employee based on job title?
select * from musique_store.employee
order by musique_store.employee.levels desc
limit 1;

-- 2 which countries have the most invoices?
select count(*) as c, billing_country from musique_store.invoice
group by billing_country
order by c desc;

-- 3 what are top 3 values of total invoice?
select total from musique_store.invoice
order by total desc
limit 3;

-- 4 which city has the best customers?
select count(*) as c, city from musique_store.customer
group by city
order by c desc
limit 1;

select sum(total) as invoice_total , billing_city from musique_store.invoice
group by billing_city
order by invoice_total desc
limit 1;

-- 5 who is the best customer?
select customer_id, sum(invoice.total) as total from musique_store.invoice
group by customer_id
order by total desc;

select c.customer_id, c.first_name, c.last_name, sum(i.total) as total
from musique_store.customer as c
join musique_store.invoice as i 
on c.customer_id = i.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total desc;


-- L2_ 1 Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A.
select Distinct c.customer_id, c.email, c.first_name, c.last_name from musique_store.customer as c
join musique_store.invoice as i on c.customer_id = i.customer_id
join musique_store.invoice_line as l on i.invoice_id = l.invoice_id
where track_id in (
select track_id from musique_store.Track as t 
join musique_store.genre as g on t.genre_id = g.genre_id
where g.name like "Rock"
)
order by c.email;

select Distinct c.customer_id, c.email, c.first_name, c.last_name, g.name as name from musique_store.customer as c
join musique_store.invoice as i on c.customer_id = i.customer_id
join musique_store.invoice_line as l on i.invoice_id = l.invoice_id
join musique_store.Track as t on t.track_id=l.track_id 
join musique_store.genre as g on t.genre_id = g.genre_id
where g.name like "Rock"
order by c.email;


-- Q2: Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.
select a.artist_id, a.name, count(a.artist_id) as count from musique_store.artist as a
join musique_store.album2 as ab on a.artist_id = ab.artist_id
join musique_store.track as t on ab.album_id = t.album_id
join musique_store.genre as g on t.genre_id = g.genre_id
where g.name like "Rock"
GROUP BY a.artist_id, a.name
order by count desc;

-- Q3: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
select name, milliseconds as lenght from musique_store.track
where milliseconds > (select avg(milliseconds) from musique_store.track )
order by lenght desc;

-- Question Set 3 - Advance

-- Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent

WITH best_selling_artist as (
 select a.artist_id as artist_id, a.name as artist_name, sum(il.unit_price*il.quantity) as amount_spent from musique_store.invoice_line il
 join musique_store.track t on il.track_id=t.track_id
 join musique_store.album2 ab on t.album_id=ab.album_id
 join musique_store.artist a on ab.artist_id=a.artist_id
 group by a.artist_id, a.name
 order by amount_spent desc
 limit 1
 ) 
 select c.customer_id, c.first_name, c.last_name, bsa.artist_name, sum(il.unit_price*il.quantity) as amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

with popular_genre as
(
select c.country, g.name, g.genre_id, count(il.quantity) as purchases,
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo 
from customer c
join invoice i on c.customer_id=i.customer_id
join invoice_line il on i.invoice_id=il.invoice_id
join track t on il.track_id=t.track_id
join genre g on t.genre_id=g.genre_id
group by  c.country, g.name, g.genre_id
order by c.country ,purchases  desc
)

select * from popular_genre
where RowNo <= 1;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

-- most time
WITH most_on_customer as
(
select c.country, c.customer_id, c.first_name, c.last_name, sum(t.milliseconds) as total_time,
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY sum(t.milliseconds) DESC) AS RowNo
from customer c
join invoice i on c.customer_id=i.customer_id
join invoice_line il on i.invoice_id=il.invoice_id
join track t on il.track_id=t.track_id
group by c.customer_id, c.first_name, c.last_name, c.country
order by c.country, total_time desc
)
select * from most_on_customer
where RowNo<=1;

-- most total spending
WITH most_on_customer as
(
select c.country, c.customer_id, c.first_name, c.last_name, sum(i.total) as total_spending,
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY sum(i.total) DESC) AS RowNo
from customer c
join invoice i on c.customer_id=i.customer_id
group by c.customer_id, c.first_name, c.last_name, c.country
order by c.country, total_spending desc
)
select * from most_on_customer
where RowNo<=1;
