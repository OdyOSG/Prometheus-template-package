#' @importFrom magrittr %>%
#' @export
generateSurvivalInfo <- function(
    connection,
    cohortDatabaseSchema,
    cdmSchema,
    cohortTable,
    targetIds,
    outcomeId
    ) {
  sqlFileName <- "TimeToEvent.sql"
  pathToSql <- system.file("sql", sqlFileName, package = getThisPackageName())
  sql <- readChar(pathToSql, file.info(pathToSql)$size)
  survOutputs <- purrr::map_dfr(targetIds, function(targetId) {
    sqlTmp <- SqlRender::render(sql,
                                cohort_database_schema = cohortDatabaseSchema,
                                cohort_table = cohortTable,
                                outcome_id = outcomeId,
                                target_id = targetId
    )
    sqlTmp <- SqlRender::translate(
      sql = sqlTmp,
      targetDialect = connection@dbms
    )

    kmRaw <- DatabaseConnector::querySql(
      connection = connection,
      sql = sqlTmp,
      snakeCaseToCamelCase = T
    )

    ## edit
    if (nrow(kmRaw) < 100 | length(kmRaw$event[kmRaw$event == 1]) < 1) {
      return(NULL)
    }

    km_proc <- kmRaw %>%
      dplyr::mutate(
        timeToEvent = as.integer(as.Date(eventDate) - as.Date(cohortStartDate)),
        id = dplyr::row_number()
      ) %>%
      dplyr::select(id, timeToEvent, event)

    survInfo <- survival::survfit(survival::Surv(timeToEvent, event) ~ 1, data = km_proc)

    survInfo <- surv_summary(survInfo)

    data.frame(
      targetId = targetId,
      outcomeId = outcomeId,
      time = survInfo$time,
      surv = survInfo$surv,
      n.censor = survInfo$n.censor,
      n.event = survInfo$n.event,
      n.risk = survInfo$n.risk,
      lower = survInfo$lower,
      upper = survInfo$upper,
      cdmSchema = cdmSchema
    )
  })
}
