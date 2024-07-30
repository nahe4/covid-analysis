select * from Covid_Project.deaths 
order by 1;

#set sql_safe_updates = 0;


#update Covid_Project.deaths set date = str_to_date(date, "%m/%d/%Y") ; 
	-- change date format from m/d/yyyy to yyyy-mm-dd

#Alter table Covid_Project.deaths 
#rename column date to date_ymd ;
	-- rename date column to easily distinguish from DATE datatype

SELECT location, date_ymd, total_cases, new_cases, population, total_deaths  FROM Covid_Project.deaths
order by location, date_ymd;

-- total cases vs total deaths

SELECT location, date_ymd, total_cases, new_cases, population, total_deaths, (total_cases/total_deaths)*100 as deathpercentage 
FROM Covid_Project.deaths
order by location, date_ymd;

-- total cases and population

SELECT location, population, date_ymd, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as percent_inf_dead, (total_cases/population)*100 as percent_infected 
FROM Covid_Project.deaths
where date_ymd like '%2021%' 
order by location, date_ymd;

-- countries with highest infection rates

SELECT location, population, max(cast(total_cases as unsigned)) as total_cases, max((total_cases/population)*100) as percent_infected  
FROM Covid_Project.deaths
where continent <> ''
group by location, population
order by percent_infected desc;

-- highest deaths to population rates

SELECT location, population, max(cast(total_deaths as unsigned)) as total_deaths, max((total_deaths/population)*100) as percent_killed  
FROM Covid_Project.deaths
where continent <> ''
group by location, population, continent
order by percent_killed desc;

-- deaths and death rate by continent
SELECT continent, max(cast(total_deaths as unsigned)) as total_deaths, max((total_deaths/population)*100) as percent_killed  
FROM Covid_Project.deaths
where continent <> ''	
group by continent
order by percent_killed desc;

-- global cases
SELECT date_ymd, sum(total_cases), sum(total_deaths), sum(total_deaths)*100/sum(total_cases) as cases_deaths_percent 
FROM Covid_Project.deaths
where continent <> '' 	
group by date_ymd
order by date_ymd;

-- total population vs vaccinations

select deaths.continent, deaths.location, deaths.date_ymd, deaths.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by deaths.location order by deaths.location, deaths.date_ymd) as vaccinations_to_date
#, vaccinations_to_date*100/population as percent_vaccinated
from Covid_Project.deaths deaths
join Covid_Project.Vaccinations vac
	on deaths.location = vac.location and deaths.date_ymd = vac.date_ymd
where deaths.continent <> '' and vac.new_vaccinations <> ''
order by 2,3;

-- percent vaccinated

with pop_vac (continent, location, date_ymd, population, new_vaccinations, vaccinations_to_date) as 
(
select deaths.continent, deaths.location, deaths.date_ymd, deaths.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by deaths.location order by deaths.location, deaths.date_ymd) as vaccinations_to_date
from Covid_Project.deaths deaths
join Covid_Project.Vaccinations vac on deaths.location = vac.location and deaths.date_ymd = vac.date_ymd
where deaths.continent <> '' and vac.new_vaccinations <> ''
)

select *, vaccinations_to_date*100/population from pop_vac;
    
-- temporary table
drop table if exists Covid_project.vax_temp;
Create Table Covid_Project.vax_temp (
continent text,
country text,
date_ymd date,
population numeric,
new_vaccinations numeric,
vaccinations_to_date numeric
);

insert into Covid_Project.vax_temp
select deaths.continent, deaths.location, deaths.date_ymd, deaths.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by deaths.location order by deaths.location, deaths.date_ymd) as vaccinations_to_date
from Covid_Project.deaths deaths
join Covid_Project.Vaccinations vac on deaths.location = vac.location and deaths.date_ymd = vac.date_ymd
where deaths.continent <> '' and vac.new_vaccinations <> '';

select *, vaccinations_to_date*100/population as percent_vaccinated from Covid_Project.vax_temp;

-- create view to store data for visualisation

create view Covid_Project.percent_vax as
select *, vaccinations_to_date*100/population as percent_vaccinated from Covid_Project.vax_temp;

