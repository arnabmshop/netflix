select * from netflix_raw;

Drop table netflix_raw;

---create the new schema to allow foreign characters and make the table faster
CREATE TABLE [dbo].[netflix_raw](
	[show_id] [varchar](10) NULL,
	[type] [varchar](10) NULL,
	[title] [nvarchar](110) NULL,
	[director] [varchar](210) NULL,
	[cast] [varchar](780) NULL,
	[country] [varchar](130) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [int] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](20) NULL,
	[listed_in] [varchar](90) NULL,
	[description] [varchar](300) NULL
)

---remove duplicates

select * from netflix_raw where concat(title,type) in (
select concat(title,type)
from netflix_raw group by title,type having count(*)>1) order by title;

---using type and title, there are 3 duplicates could be identified.Keep the record which was nearest added. Delete the remaining.

with cte as 
( 
	select *,row_number() over (partition by type,title order by date_added desc) as rn from netflix_raw
) 
select * into netflix_temp from cte where rn=1;

drop table netflix_raw;

EXEC sp_rename 'netflix_temp', 'netflix_raw';

select * from netflix_raw;

-- create a different table each for directors, cast, country, listed_in. Each title can have multiple directors or country. 
-- They should be in different rows. These sub tables are joined to the main table by the showId as the primary key.

select show_id,trim(value) as director 
into netflix_directors
from netflix_raw cross apply string_split(director,',');

select show_id,trim(value) as cast_team 
into netflix_cast
from netflix_raw cross apply string_split(cast,','),

select show_id,trim(value) as country
into netflix_country
from netflix_raw cross apply string_split(country,',');

select show_id,trim(value) as listed_in 
into netflix_listed
from netflix_raw cross apply string_split(listed_in,',');

--- In the raw table, populate the country where it is null with values based on the director. For example: In X and Y both movies
--have director Z and country for Y is India. Then country for X will also be India.

select count(*) from netflix_raw where country is null

select * from netflix_raw where director='Ahishor Solomon';

update netflix_raw 
set country= b.country from netflix_raw join (
select director,country from netflix_raw where director in (select director from netflix_raw where country is null)
and country is not null )b on netflix_raw.director=b.director 
where netflix_raw.country is null;

select * from netflix_raw where director='Ahishor Solomon';

---Fill the duration=NUll with rating

select * from netflix_raw where duration is null;

update netflix_raw
set duration=rating,rating=null where duration is null;

select * from netflix_raw where rating is null;

--- Fill in the date_added where it is null with release year - 01-01

select * from netflix_raw where date_added is null;

UPDATE netflix_raw
SET date_added = DATEFROMPARTS(release_year, 1, 1)
WHERE date_added IS NULL;

select * from netflix_raw where show_id='s6067';

UPDATE netflix_raw
SET date_added = DATENAME(MONTH, CAST(date_added AS DATE)) + ' ' + 
CAST(DAY(date_added) AS VARCHAR(2)) + ', ' + CAST(YEAR(date_added) AS VARCHAR(4)) 

---In the table, date_added column is in varchar type. Convert it to date type and create a transaction table from the raw table.
-- drop columns directors, cast, country, listed_in from this transaction table.

drop table netflix_main;

select show_id, type,title, release_year, cast(date_added as date) as date_added, rating,duration,description
into netflix_main from netflix_raw;

select * from netflix_main;

----DATA ANALYSIS PART----
/* 1. for each director, count the number of movies and tv shows created by them in separate columns for directors who have 
created tv shows and movies both */

with cte as 
(
	select director,type,title from netflix_directors a join netflix_main b on a.show_id=b.show_id
),
cte1 as 
(
	select director, case when x.type='Movie' then cnt end as Movies,
	case when x.type='TV Show' then cnt end as TV_Show 
	from (select director,type,count(distinct title) as cnt from cte group by director,type)x
)
select * from 
(
	select director, max(movies) as Movies, max(TV_show) as TV_show from cte1 group by director
)x 
where Movies is not null and TV_show is not null;

/*2.which country has highest number of comedy movies*/
select top 1 * from 
(
	select country, count(distinct show_id) as cnt from netflix_country 
	where show_id in (
						select distinct a.show_id
						from netflix_listed a join netflix_main b 
						on a.show_id=b.show_id 
						where listed_in like 'comedies' and b.type like 'movie'
					 )
	group by country
)X order by cnt desc

/*3.For each year as per the date added to netflix, which director has maximum number of movie released*/

with cte as (
select year_added,director,count(distinct title) as no_movies_released
from (
select b.*,a.director,year(date_added) as year_added from netflix_directors a join netflix_main b on a.show_id=b.show_id where type='Movie'
)x group by year_added,director 
) select year_added,director,no_movies_released from (
select *, rank() over (partition by year_added order by no_movies_released desc) as rn from cte )x where rn=1
order by no_movies_released desc;

/*4. What is the average duration of movies and tv-shows in each genre*/

select genre,type,avg(time_dur) as avg_duration 
from
(
	select title,type,genre, cast(substring(duration,1,charindex(' ',duration)-1) as int) as time_dur
	from (
			select distinct a.title,a.type,a.duration,b.listed_in as genre 
			from netflix_main a join netflix_listed b on a.show_id=b.show_id
		 )y
)x group by genre,type order by genre;

/*5.Find the list of directors who have created horror and comedy movies both.
display directors along with number of comedy and horror movies*/

with cte as 
(
	select director, listed_in as genre, count(distinct show_id) as number from (
	select b.director,a.show_id,a.listed_in from netflix_listed a join netflix_directors b on a.show_id=b.show_id 
	where a.listed_in like '%horror%' or a.listed_in like '%comed%' )x group by director, listed_in
), 
cte1 as 
(
	select director, max(comedies) as comedies, max(horrors) as horrors from 
	(select director, 
	case when genre like '%comed%' then number end as comedies,case when genre like '%horror%' then number end as horrors
	from cte)x group by director 
) 
select * from cte1 where comedies is not null and horrors is not null;