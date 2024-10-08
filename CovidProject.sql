SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--Selecting the data we are going to be using --

SELECT  date, MAX(total_cases) AS MaximumCase, AVG(population) AS AVGPopulation
FROM PortfolioProject..CovidDeaths
GROUP BY date
ORDER BY Date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--Looking at Total Cases VS Total Deaths--
--Shows Likelihood of dying if you contract covid in your country--

SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 As DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%pal%'
ORDER BY 1,2

--Looking at the Total Cases VS Population--
--Shows what percentage of population got covid--

SELECT Location, date, population, total_cases,  (total_cases/population)*100 AS CovidInfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%pal%'
ORDER BY 1,2


--Looking at the countries with Highest Infection Rate as compared to popuilatiuon--

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 AS CovidInfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%pal%'
GROUP BY location, Population
ORDER BY CovidInfectedPopulationPercentage DESC

--LETS BREAK THINGS DOWN BY CONTINENT--
--Showing Countries with highest death count per population--

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
,
--GLOBAL NUMBERS--


SELECT date,
       SUM(new_cases) AS TotalCases, 
       SUM(new_deaths) AS TotalDeaths, 
       SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY 1,2 


--This will give the TotalCases, TotalDeaths and DeathPercentage

SELECT 
       SUM(new_cases) AS TotalCases, 
       SUM(new_deaths) AS TotalDeaths, 
       SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY Date
ORDER BY 1,2 

--Now have a look on covidVaccination table once--

SELECT *
FROM PortfolioProject..CovidVaccinations

--Lets join this two table--S

SELECT *
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Mofifying the above query according to our needs--

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Looking at Total Population VS Vaccinations--

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations As vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Now using the CTE to run the above query--

WITH PopVsVac(continent, location, date, new_vaccinations, population, RollingPeopleVaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths AS dea
    JOIN PortfolioProject..CovidVaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS VaccinationRate
FROM PopVsVac

-- TEMP TABLE--

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths AS dea
    JOIN PortfolioProject..CovidVaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS VaccinationRate
FROM #PercentPopulationVaccinated








--Creating view to store date for visualization--

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths AS dea
    JOIN PortfolioProject..CovidVaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


-- Verifying the View Creation--

SELECT *
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME = 'PercentPopulationVaccinated'


--Alternatively we can use--

SELECT *
FROM sys.views
WHERE name = 'PercentPopulationVaccinated'


--Creating Views of other necessary tables--

CREATE VIEW GlobalNumber AS
SELECT 
       SUM(new_cases) AS TotalCases, 
       SUM(new_deaths) AS TotalDeaths, 
       SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY Date
--ORDER BY 1,2 

--Next one--

CREATE VIEW TotalDeathCount AS
Select location, SUM(cast(new_deaths as FLOAT)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--Next one--

CREATE VIEW MaxCases AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 AS CovidInfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%pal%'
GROUP BY location, Population
--ORDER BY CovidInfectedPopulationPercentage DESC


--Next One--
--Looking at the countries with Highest Infection Rate as compared to popuilatiuon--

CREATE VIEW HighestInfection AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 AS CovidInfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%pal%'
GROUP BY location, Population
ORDER BY CovidInfectedPopulationPercentage DESC











