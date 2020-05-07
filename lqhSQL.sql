//1. What are the genres of the movies? how many distinct genres of movies?
SELECT genre, COUNT(DISTINCT genre) FROM movies GROUP BY genre;
SELECT DISTINCT genre FROM movies;
SELECT COUNT(DISTINCT genre) somme_genre FROM movies;
//2. What are the titles and the years of French movies released from1960 to 2010?
SELECT * FROM movies;
SELECT title, year, country FROM movies WHERE year>=1960 AND year<=2010 AND country like 'F%';
//3. What are the names and the roles of the actors who played in ’The Dark Knight Rises’
movie? Give at least two different equivalent queries (one of them should use a subquery).
SELECT * FROM artists;
SELECT * FROM movies;
SELECT * FROM movies_actors;
SELECT * FROM movies_directors;
//1.1 原始方法都是sobquery
SELECT last_name, first_name,role,movie 
FROM artists d, 
(SELECT actor_id,actor_role as role,movie FROM movies_actors b, 
(SELECT id,title as movie FROM movies WHERE title='The Dark Knight Rises')a
WHERE b.movie_id=a.id)c 
WHERE c.actor_id=d.id;
//1.2 join和subquery合并方法判断在list中可以=（1.2）也可以in（1.2.1）
SELECT last_name, first_name, actor_role FROM artists 
JOIN movies_actors ON artists.id=movies_actors.actor_id
WHERE movies_actors.movie_id =(SELECT id from movies WHERE title='The Dark Knight Rises');
//1.3纯join方法
SELECT last_name, first_name, actor_role as role,title as movie
FROM (artists JOIN 
(movies JOIN movies_actors ON movies.id=movies_actors.movie_id) 
ON artists.id=movies_actors.actor_id)a
WHERE a.title='The Dark Knight Rises';
//1.2.1 join 可以直接 from 后面列出所有的表 在where中加join的条件,判断在list中可以=也可以in
SELECT last_name, first_name, actor_role FROM artists, movies_actors
WHERE artists.id=movies_actors.actor_id AND 
movies_actors.movie_id in (SELECT id from movies WHERE title='The Dark Knight Rises');
//2.3.1 join 可以直接 from 后面列出所有的表 再where中加join的条件
SELECT last_name, first_name, actor_role as role,title as movie
FROM artists ,movies, movies_actors 
WHERE movies.title='The Dark Knight Rises' 
AND artists.id=movies_actors.actor_id 
AND movies.id=movies_actors.movie_id;
//4. What are the names and the roles of the actors who directed and played in a movie (the same movie)?
SELECT last_name, first_name, actor_role as role,title as movie
FROM (movies_directors JOIN 
(artists JOIN 
(movies JOIN movies_actors ON (movies.id=movies_actors.movie_id)) 
ON (artists.id=movies_actors.actor_id))
ON (movies_directors.director_id=artists.id AND movies.id=movies_directors.movie_id))a
WHERE a.actor_role IS NOT NULL;
//2
SELECT last_name, first_name, actor_role as role,title as movie
FROM movies_directors,artists,movies, movies_actors
WHERE movies.id=movies_actors.movie_id AND
artists.id=movies_actors.actor_id AND
artists.id=movies_directors.director_id AND
movies.id=movies_directors.movie_id;
//3 最好的方法
SELECT a.last_name,a.first_name, ma.actor_role
FROM movies_directors md,movies_actors ma,artists a
WHERE a.id=md.director_id AND a.id=ma.actor_id AND md.movie_id=ma.movie_id;

//5. What is the number of movies by country? by country and year. Retrieve the answers in different kind of orders.
//by country
SELECT country, COUNT(*)  as num_movies 
FROM movies 
GROUP BY country
ORDER BY count(*);
//by year
SELECT country, year, COUNT(title)as num_movies 
FROM movies 
GROUP BY country,year
ORDER BY year asc;
//不知道想干嘛
select country, year, count(*) from movies group by country, year
order by year, country desc;
//6. What is the number of movies by artist? First, retrieve only the identifier’s artist then the first/last name’s artist.
//1st step 有问题了 错误方法
SELECT id,COUNT(md.movie_id) as num_md_movies,COUNT(ma.movie_id) as num_ma_movies 
FROM movies_actors ma,movies_directors md,artists a
WHERE ma.actor_id=a.id OR md.director_id=a.id
GROUP BY id
ORDER BY id asc;
//问题：需要考虑一部电影里面同时为actors和directors的id
SELECT a.id,COUNT(*) FROM
((SELECT actor_id as id FROM movies_actors GROUP BY actor_id) 
UNION ALL
(SELECT director_id FROM movies_directors GROUP BY director_id))a
GROUP BY a.id
ORDER BY a.id;
//2nd step
//方法1 先合并两个表再筛选
SELECT A.id,b.last_name,b.first_name,COUNT(*) FROM
((SELECT actor_id as id FROM movies_actors) UNION ALL
(SELECT director_id FROM movies_directors))as A,artists b
WHERE b.id=A.id
GROUP BY A.id,b.first_name,b.last_name
ORDER BY A.id;
//方法2 先分别筛选两个表再合并 事实表明这种方法快
select count(*) n, u.id, u.name1, u.name2 from (
(select a.id as id, a.first_name as name1, a.last_name as name2
from movies_actors ma, artists a
where a.id=ma.actor_id)
union all
(select a.id as id, a.first_name as name1, a.last_name as name2
from movies_directors md, artists a
where md.director_id = a.id)
) u group by u.id, u.name1, u.name2
order by  u.id;


//7. What is the name of the actor who played in the most of movies?
//取最大值方法1
SELECT last_name, first_name,num_movies FROM 
(SELECT actor_id,COUNT(movie_id) as num_movies FROM movies_actors ma
GROUP BY ma.actor_id)a,artists
WHERE artists.id=a.actor_id AND 
num_movies=(select max(n) from (select count(*) n from movies_actors group by actor_id) as s);
//取最大值方法2
SELECT last_name, first_name,num_movies FROM 
(SELECT actor_id,COUNT(movie_id) as num_movies FROM movies_actors ma
GROUP BY ma.actor_id)a,artists
WHERE artists.id=a.actor_id AND 
num_movies >=ALL (SELECT num_movies FROM (SELECT actor_id,COUNT(movie_id) as num_movies FROM movies_actors ma
GROUP BY ma.actor_id)b);
//取最大值方法3 先group by然后在having中取最值
select id, first_name, last_name, count(*) from movies_actors ma, artists a
where ma.actor_id=a.id
group by id, first_name, last_name 
having count(*) =(Select Max(n) from (select count(*) n from movies_actors group by actor_id) as s);
//8. What are the artists who are not associated to any movie as an actor?as a director? as neither?
//方法1 not exists
SELECT id,first_name,last_name 
FROM artists a 
WHERE NOT EXISTS(SELECT * FROM movies_actors b WHERE b.actor_id=a.id) 
or NOT EXISTS(SELECT * FROM movies_directors c WHERE c.director_id=a.id)
order by id;
//方法2 not in
select id, first_name, last_name from artists where id
not in (select actor_id from movies_actors WHERE actor_id is not null)
or id
not in (select director_id from movies_directors WHERE director_id is not null)
order by id;