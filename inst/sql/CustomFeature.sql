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
