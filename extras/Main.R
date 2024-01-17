suppressMessages(library(DatabaseConnector))
setwd("./")
tryCatch({
  install.packages(file.path(".")
                   , repos = NULL, type = "source", INSTALL_opts=c("--no-multiarch"))
}, finally = {})

tryCatch( {
  cohortDatabaseSchema <- 'alex_alexeyuk_results'
  resultsDatabaseSchema <- cohortDatabaseSchema
  cdmDatabaseSchema <- "cdm_531"
  cohortTable <- 'takeda_test'
  databaseId <- "testDatabaseId"
  packageName <- "NSCLCCharacterization"
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "postgresql",
    server = "testnode.arachnenetwork.com/synpuf_110k",
    user = Sys.getenv("ohdsi_password"),
    password = Sys.getenv("ohdsi_password"),
    port = "5441"
  )
  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  outputFolder <- file.path(getwd(), 'my_results')
  dir.create(outputFolder)

  # GenerateSurvival::createCohorts(
  #     connection = conn,
  #     cdmDatabaseSchema = cdmDatabaseSchema,
  #     cohortDatabaseSchema = cohortDatabaseSchema,
  #     cohortTable = cohortTable
  # )
  settings <- GenerateSurvival::settingsGs()
  res <- purrr::map_dfr(settings$outcomeIds, ~GenerateSurvival::generateSurvivalInfo(
    connection = conn,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTable = cohortTable,
    targetIds = settings$targetIds,
    outcomeId = .x
  ))
  data.table::fwrite(res, 'my_results/surv_info.csv')
} , finally = {}
)
