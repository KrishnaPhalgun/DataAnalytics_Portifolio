
/*SELECT *
FROM dbo.CovidDeaths;*/

SELECT * FROM Portifolio_1..CovidDeaths

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM Portifolio_1..CovidDeaths
where continent is not null
order by 1,2;

--SELECT * 
--FROM Portifolio_1..CovidVaccinations
--order by 3,4;

-- These queries can also be modified for whole world data, here I am only considering location specific to India.

-- Looking at totalcases vs total deaths
--Indirectly this is the likely death rate if you are infected with covid in your country , you can even check at specific date
SELECT location, date, total_cases, total_deaths, ( (total_deaths/total_cases)*100) as Death_Percent
FROM Portifolio_1..CovidDeaths
where location like '%India%'
and continent is not null
order by 1,2;

-- Looking at Population vs Total Cases
-- This data shows what percentage of population in India on specific dates got affected by Covid
SELECT location, date, population, total_cases, ((total_cases/population)*100) as Affected_Percent
FROM Portifolio_1..CovidDeaths
where continent is NOT NULL and location like '%India%'
order by 1,2;

--Looking at Continent and Countries with Highest Infection Rate
SELECT continent, location, MAX(total_cases) as HighestInfected, (MAX(total_cases/population)*100) as Infection_Rate
FROM Portifolio_1..CovidDeaths
where continent is NOT NULL
group by continent, location
order by 4 desc;

--Looking at Countries with Highest Infection Rate when compared with population
SELECT location, population, MAX(total_cases) as HighestInfected, (MAX(total_cases/population)*100) as Infection_Rate
FROM Portifolio_1..CovidDeaths
where continent is NOT NULL
group by location, population
order by 4 desc;

--Looking at Countries with Highest Death Count per population
-- The data type for total_deaths column is nvarchar so we casted it into int for efficient results
/*For location column values with continent names the continent column for those specific locations is 
NULL in table so we removed those records from
every query above.*/
SELECT location, population, MAX(cast(total_deaths as int)) as Deathsperpopulation
FROM Portifolio_1..CovidDeaths
where continent is NOT NULL
group by location, population
order by Deathsperpopulation desc;

--Let us look in terms of continents now
SELECT continent, MAX(cast(total_deaths as int)) as Deathsperpopulation
FROM Portifolio_1..CovidDeaths
where continent is NOT NULL
group by continent
order by Deathsperpopulation desc;
 
-- The above data is flawed as table is not proper
-- Let us look in terms of location where continent is NULL so that location provides continent value
-- Table contains separate records for continent specific data 
SELECT location, MAX(cast(total_deaths as int)) as Deathsperpopulation
FROM Portifolio_1..CovidDeaths
where continent is NULL
group by location
order by Deathsperpopulation desc;

--Global Numbers
SELECT location, date, total_cases, total_deaths, ( (total_deaths/total_cases)*100) as Death_Percent
FROM Portifolio_1..CovidDeaths
where continent is not null
order by 1,2;

--Global Total Cases, Total Death and Death Percentage
SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_Deaths,
((SUM(cast(new_deaths as int))/SUM(new_cases))*100) as DeathPercentage
FROM Portifolio_1..CovidDeaths
where continent is not null
order by 1,2;


-- Global Numbers each day with total cases and total deaths per day and respective death percentages
SELECT date, SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_Deaths,
((SUM(cast(new_deaths as int))/SUM(new_cases))*100) as DeathPercentage
FROM Portifolio_1..CovidDeaths
where continent is not null
group by date
order by 1,2;

--Covid_Vaccinations Table
SELECT *
FROM Portifolio_1..CovidVaccinations

--Joining CovidDeaths and CovidVaccinations Tables
-- Looking at Total_Population vs Vaccinations
SELECT Dt.continent, Dt.location, Dt.date, Dt.population, Vc.new_vaccinations
FROM Portifolio_1..CovidDeaths Dt
JOIN Portifolio_1..CovidVaccinations Vc	
	ON Dt.location = Vc.location 
	AND Dt.date = Vc.date
WHERE Dt.continent is NOT NULL
ORDER BY 2,3;

--Same as above result but rolling total vaccinations per day and per location
--We used window function for rolling sum
SELECT Dt.continent, Dt.location, Dt.date, Dt.population, Vc.new_vaccinations,
SUM(cast(Vc.new_vaccinations as int)) OVER (Partition by Dt.location ORDER BY Dt.location, Dt.date) as Cummulative_TotalVaccinations
FROM Portifolio_1..CovidDeaths Dt
JOIN Portifolio_1..CovidVaccinations Vc	
	ON Dt.location = Vc.location 
	AND Dt.date = Vc.date
WHERE Dt.continent is NOT NULL
ORDER BY 2,3;


--Percentage Vaccinated vs Population Using CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccination, Cummulative_TotalVaccinated)
as
(
SELECT Dt.continent, Dt.location, Dt.date, Dt.population, Vc.new_vaccinations,
SUM(cast(Vc.new_vaccinations as int)) OVER (Partition by Dt.location ORDER BY Dt.location, Dt.date) as Cummulative_TotalVaccinated
FROM Portifolio_1..CovidDeaths Dt
JOIN Portifolio_1..CovidVaccinations Vc	
	ON Dt.location = Vc.location 
	AND Dt.date = Vc.date
WHERE Dt.continent is NOT NULL
)
SELECT *, (Cummulative_TotalVaccinated/Population)*100
FROM PopvsVac

--Using TEMP Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Cummulative_TotalVaccinated numeric
)
Insert into #PercentPopulationVaccinated
SELECT Dt.continent, Dt.location, Dt.date, Dt.population, Vc.new_vaccinations,
SUM(cast(Vc.new_vaccinations as int)) OVER (Partition by Dt.location ORDER BY Dt.location, Dt.date) as Cummulative_TotalVaccinations
FROM Portifolio_1..CovidDeaths Dt
JOIN Portifolio_1..CovidVaccinations Vc	
	ON Dt.location = Vc.location 
	AND Dt.date = Vc.date
WHERE Dt.continent is NOT NULL
ORDER BY 2,3

SELECT *, (Cummulative_TotalVaccinated/Population)*100 as Percent_TotalVaccinated
FROM #PercentPopulationVaccinated



--Creating Views to Store data for future Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT Dt.continent, Dt.location, Dt.date, Dt.population, Vc.new_vaccinations,
SUM(cast(Vc.new_vaccinations as int)) OVER (Partition by Dt.location ORDER BY Dt.location, Dt.date) as Cummulative_TotalVaccinations
FROM Portifolio_1..CovidDeaths Dt
JOIN Portifolio_1..CovidVaccinations Vc	
	ON Dt.location = Vc.location 
	AND Dt.date = Vc.date
WHERE Dt.continent is NOT NULL;
--ORDER BY 2,3

