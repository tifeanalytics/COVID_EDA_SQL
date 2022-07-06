
--EXPLORATION AND ANALYSIS OF GLOBAL COVID-19 DATA 

--SELECTING AND INSPECTING DATA TO INCLUDE IN PRELIMINARY DATA EXPLORATION (DEATH)

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Projects..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2  --Result ordered by location and date.


--EXPLORING THE DATA BY COUNTRY

--MORTALITY RATES USING TOTAL CASES VS TOTAL DEATHS 
--Shows Percentage of cases that resulted in death

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) as MortalityRate
FROM Projects..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--INFECTION RATES USING TOTAL CASES VS POPULATION
--Shows Percentage of Population that contracted COVID

SELECT location, date, population, total_cases, ROUND((total_cases/population)*100, 2) as InfectionRate
FROM Projects..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--COUNTRIES WITH HIGHEST INFECTION RATES COMPARED TO POPULATION
--Shows countires with the highest infection rates based on population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, ROUND(MAX((total_cases/population)*100), 2) as PercentPopulationInfected
FROM Projects..CovidDeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--COUNTRIES WITH HIGHEST DEATH COUNTS
--Show countries with the highest incidents of death

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount   --The CAST attribute was used to change total_deaths data type to integer (data wrongly inputed as (nvarchar, 255))
FROM Projects..CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


--EXPLORING THE DATA BY CONTINENT

--MORTALITY RATES USING TOTAL CASES VS TOTAL DEATHS 
--Shows Percentage of cases that resulted in death

SELECT continent, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, ROUND((SUM(CAST(new_deaths as int))/SUM(new_cases)*100), 2) as ContinentalMortalityRate
FROM Projects..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY ContinentalMortalityRate DESC

--CONTINENTS INFECTION RATES 
--Shows continents with the highest infection counts and percentage of total population infected

SELECT continent, SUM(DISTINCT population) as TotalPopulation, SUM(new_cases) as TotalInfectionCount, (SUM(new_cases)/SUM(DISTINCT population))*100 as ContinentalInfectionRate
FROM Projects..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY ContinentalInfectionRate DESC

--CONTINENTS DEATH COUNT
--Show countries with the highest incidents of death

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount 
FROM Projects..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


--GLOBAL NUMBERS

--GLOBAL COVID INCIDENCE AND MORTALITY 
--Shows number of new cases per day, number of deaths per day and date-specific Mortality Rates.

SELECT date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as GlobalMortalityRate
FROM Projects..CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--GLOBAL SUMMARY OF CASES, DEATHS AND MORTALITY RATE TO DATE
--Shows total number of cases, total deaths and mortality rate as at time of data access (03/07/2022)

SELECT SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as GlobalMortalityRate
FROM Projects..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2



--ANALYSIS OF COVID VACCINATION DATA

--Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Projects..CovidDeaths$ as dea
JOIN Projects..CovidVaccinations$ as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3

--Looking at Cummulative Frequency of Vaccination (Rolling count of People Vaccinated)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER  BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Projects..CovidDeaths$ as dea
JOIN Projects..CovidVaccinations$ as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--USING TEMP TABLE TO SHOW PERCENTAGE OF POPULATION VACCINATED
DROP TABLE if exists #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated 
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric)

INSERT INTO  #PercentPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER  BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Projects..CovidDeaths$ as dea
JOIN Projects..CovidVaccinations$ as vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
FROM #PercentPopulationVaccinated


--USING CTE TO SHOW PERCENTAGE OF POPULATION VACCINATED

WITH PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated) as 
	(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER  BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Projects..CovidDeaths$ as dea
JOIN Projects..CovidVaccinations$ as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null)

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM PopVsVac


--CREATING VIEW TO STORE DATA FOR VISUALIZATION

CREATE VIEW PercentPopulationVaccinated2 as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER  BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Projects..CovidDeaths$ as dea
JOIN Projects..CovidVaccinations$ as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT * FROM PercentPopulationVaccinated2