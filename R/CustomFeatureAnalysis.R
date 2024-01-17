#' @export
runCustomFeatureAnalysis <- function(
    cdm_database_schema,
    cohort_table,
    cohort_id,
    analysis_id,
    cohort_database_schema,
    connection
) {
  DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = SqlRender::readSql('inst/sql/CustomFeature.sql'),
    cdm_database_schema = cdm_database_schema,
    cohort_table = cohort_table,
    cohort_id = cohort_id,
    analysis_id = analysis_id,
    cohort_database_schema = cohort_database_schema
  )
}
