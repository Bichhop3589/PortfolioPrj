select *
from PortfolioProject..CovidDeaths
order by 3,4

select *
from PortfolioProject..CovidVaccinations
where continent is not null
order by 3,4

-- select data that be used
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- looking at total cases and total deaths
-- show the likelihood of dying if contract the covid
select location, date, total_cases,total_deaths, (total_deaths/ total_cases)
from PortfolioProject..CovidDeaths
order by 1,2
-- error: type nvarchar(MAX) can not devided
-- solution: transform to float
select 
    location,
    date,
    cast(total_cases as float) as total_cases,
    cast(total_deaths as float) as total_deaths,
    cast(total_deaths as float) / nullif(cast(total_cases as float), 0) *100 as Deathpercentage
from PortfolioProject..CovidDeaths
where location like '%state%' and continent is not null
order by 1,2;
-- note: cast (... as float): ép kiểu dữ liệu / nullif(...,0): trả về null khi ... là 0


-- looking at the total_cases vs population
-- show what percentage of population got the covid
select 
    location,
    date,
    cast(population as float) as population,
    cast(total_cases as float) as total_cases,
    cast(total_cases as float) / cast(population as float) *100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%state%'
where continent is not null
order by 1,2;

-- looking at countries with highest infection rate compared to population
select 
    location,
    cast(population as float) as population,
    MAX(cast(total_cases as float)) as highestInfectionCount,
    MAX(cast(total_cases as float) / cast(population as float) *100) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
group by population, location
order by PercentPopulationInfected desc

-- showing the country with highest death count per population
select 
    location,
    MAX(cast(total_deaths as float)) as TotalDeathCount 
    --MAX(cast(total_cases as float) / cast(population as float) *100) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- breaking things down by continent
-- showing the continent with the highest death count
select 
   continent,
    MAX(cast(total_deaths as float)) as TotalDeathCount 
    --MAX(cast(total_cases as float) / cast(population as float) *100) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc


--GLOBAL NUMBER: thống kê theo thế giới
-- từng ngày thế giới  có bao nhiêu ca mắc bệnh mới?
select
   SUM(cast(new_cases as float)) as total_case, SUM(CAST(new_deaths as float)) as total_deaths,
    SUM(CAST(new_deaths as float))/SUM(cast(new_cases as float)) *100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
--group by date
order by 1,2

--
--looking at total population vs vaccination
with PopvsVac (continent, location, date, population,New_vaccination, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as float)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100 as Rate from PopvsVac

-- TEMP TABLE
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(MAX),
Location nvarchar(MAX),
Date datetime,
Population numeric, 
New_vaccinations numeric,
 RollingPeopleVaccinated numeric
 )
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as float)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
select *, (RollingPeopleVaccinated/population)*100 as Rate from #PercentPopulationVaccinated

-- creating view store data for later visualization
create view PercentPopulationVaccinated as
select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as float)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null

select * from PercentPopulationVaccinated