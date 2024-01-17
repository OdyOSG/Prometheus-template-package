# Prometheus-template-package
## Screencast tutorial
Link for screencast [gdrive link](https://drive.google.com/file/d/1A0BoF2DQNhnbtma-07knvL51HanrQvFd/view?usp=drive_link)

## Purpose of the Repository

The package to provide custom analysis in Prometheus 

## How to Use this Repository

### Download the package
- 1) Launch GenerateSurvival.Rproj 
- 2) Build the package (press "Install" or ctrl+shift+b)

### Set Main.R
- 3.1) if you need KM survival info
```
suppressMessages(library(DatabaseConnector))
tryCatch({
  install.packages(file.path(getwd())
                   , repos = NULL, type = "source", INSTALL_opts=c("--no-multiarch"))
}, finally = {})

tryCatch( {
  outputFolder <- file.path(getwd(), 'results')
  dir.create(outputFolder, showWarnings = F)
  dbms <- Sys.getenv("DBMS_TYPE")
  connectionString <- Sys.getenv("CONNECTION_STRING")
  user <- Sys.getenv("DBMS_USERNAME")
  pwd <- Sys.getenv("DBMS_PASSWORD")
  cdmDatabaseSchema <- Sys.getenv("DBMS_SCHEMA")
  resultsDatabaseSchema <- Sys.getenv("RESULT_SCHEMA")
  cohortsDatabaseSchema <- Sys.getenv("TARGET_SCHEMA")
  cohortTable <- Sys.getenv("COHORT_TARGET_TABLE")
  driversPath <- (function(path) if (path == "") NULL else path)( Sys.getenv("JDBC_DRIVER_PATH") )
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    connectionString = connectionString,
    user = user,
    password = pwd,
    pathToDriver = driversPath
  )
  conn <- connect(connectionDetails = connectionDetails)
  GenerateSurvival::createCohorts(
    connection = conn,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = cohortsDatabaseSchema,
    cohortTable = cohortTable
  )
  settings <- GenerateSurvival::settingsGs()
  res <- purrr::map_dfr(settings$outcomeIds, ~GenerateSurvival::generateSurvivalInfo(
    connection = conn,
    cohortDatabaseSchema = cohortsDatabaseSchema,
    cohortTable = cohortTable,
    targetIds = settings$targetIds,
    cdmSchema = cdmDatabaseSchema,
    outcomeId = .x
  ))
  data.table::fwrite(res, 'results/results.csv')
} , finally = {}
)
```


- 3.2) if you need custom feature analysis

- 3.3) Open inst/sql/CustomFeature.sql

- 3.4) Put required query (as used in custom feature in Atlas)
```
SELECT
  CAST(drug_concept_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
  c.concept_name                                                                  AS covariate_name,
  drug_concept_id                                                                 AS concept_id,
  COUNT(*)                                                                            AS sum_value,
  COUNT(*) * 1.0 / stat.total_cnt * 1.0                                   AS average_value
FROM (
       SELECT DISTINCT
         drug_concept_id,
         cohort.subject_id,
         cohort.cohort_start_date
       FROM @cohort_database_schema.@cohort_table cohort
         INNER JOIN @cdm_database_schema.drug_era ON cohort.subject_id = drug_era.person_id
       WHERE drug_era_start_date <= cohort.cohort_start_date
             AND drug_concept_id != 0
             AND cohort.cohort_definition_id = @cohort_id
     ) drug_entries
  JOIN @cdm_database_schema.concept c ON drug_entries.drug_concept_id = c.concept_id
  CROSS JOIN (SELECT COUNT(*) total_cnt
              FROM @cohort_database_schema.@cohort_table
              WHERE cohort_definition_id = @cohort_id) stat
GROUP BY drug_concept_id, c.concept_name, stat.total_cnt
```

- 4) Use that Main.R
```
suppressMessages(library(DatabaseConnector))
tryCatch({
  install.packages(file.path(getwd())
                   , repos = NULL, type = "source", INSTALL_opts=c("--no-multiarch"))
}, finally = {})

tryCatch( {
  outputFolder <- file.path(getwd(), 'results')
  dir.create(outputFolder, showWarnings = F)
  dbms <- Sys.getenv("DBMS_TYPE")
  connectionString <- Sys.getenv("CONNECTION_STRING")
  user <- Sys.getenv("DBMS_USERNAME")
  pwd <- Sys.getenv("DBMS_PASSWORD")
  cdmDatabaseSchema <- Sys.getenv("DBMS_SCHEMA")
  resultsDatabaseSchema <- Sys.getenv("RESULT_SCHEMA")
  cohortsDatabaseSchema <- Sys.getenv("TARGET_SCHEMA")
  cohortTable <- Sys.getenv("COHORT_TARGET_TABLE")
  driversPath <- (function(path) if (path == "") NULL else path)( Sys.getenv("JDBC_DRIVER_PATH") )
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    connectionString = connectionString,
    user = user,
    password = pwd,
    pathToDriver = driversPath
  )
  conn <- connect(connectionDetails = connectionDetails)
  GenerateSurvival::createCohorts(
    connection = conn,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = cohortsDatabaseSchema,
    cohortTable = cohortTable
  )
  settings <- GenerateSurvival::settingsGs()
  res <- purrr::map_dfr(settings$targetIds, ~GenerateSurvival::runCustomFeatureAnalysis(
    cdm_database_schema = cdmDatabaseSchema,
    cohort_table = cohortTable,
    cohort_id = .x,
    analysis_id = .x,
    connection = conn,
    cohort_database_schema = cohortsDatabaseSchema
    ))
  data.table::fwrite(res, 'results/results.csv')
} , finally = {}
)
```

- 5) Open extras/LoadCohorts.R
```
tryCatch({
  tarIds <- c(617:622) # set target cohorts from your Atlas
  outcomeIds <- 148 # set outcome cohorts from your Atlas if needed
  baseUrl <-  Sys.getenv("BaseUrl") # link to Atlas
  webApiUsername <- Sys.getenv("WEBAPI_USERNAME") # your  Atlas login
  webApiPassword <- Sys.getenv("WEBAPI_PASSWORD") # your  Atlas password
  authMethod <- "db" # auth in Atlas
  GenerateSurvival::setPackageUtilits(
    baseUrl,
    authMethod,
    webApiUsername,
    webApiPassword,
    atlasTargetCohortIds = tarIds,
    atlasOutcomeCohortIds = outcomeIds,
    cleanPreviousFiles = TRUE
  )
  zip(zipfile = 'CharZip', files = dir('.', full.names = T)) # will be created zip to upload
}, finally = {})
```

- 6) *Upload zip in Prometheus (see screencast)*

- 7) Run analysis



If you have questions - contact me **alexander.alexeyuk@odysseusinc.com**
