# Copyright 2022 Observational Health Data Sciences and Informatics
#
# This file is part of Assure
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#' Execute the Study
#'
#' @details
#' This function executes the Assure Study.
#' 
#' The \code{createCohorts}, \code{synthesizePositiveControls}, \code{runAnalyses}, and \code{runDiagnostics} arguments
#' are intended to be used to run parts of the full study at a time, but none of the parts are considered to be optional.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param databaseId           A short string for identifying the database (e.g.
#'                             'Synpuf').
#' @param databaseName         The full name of the database (e.g. 'Medicare Claims
#'                             Synthetic Public Use Files (SynPUFs)').
#' @param databaseDescription  A short description (several sentences) of the database.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included 
#'                             in packaged results.
#'
#'
#' @export
SubgroupAnalyses <- function(connectionDetails,
                          cdmDatabaseSchema,
                          cohortDatabaseSchema,
                          cohortTable,
                          outputFolder,
                          oracleTempSchema,
                          databaseId,
                          databaseDescription,
                          databaseName,
                          maxCores,
                          minCellCount){
  
  conn <- DatabaseConnector::connect(connectionDetails)
  
  if (!file.exists(paste0(outputFolder, '/male_group')))
    dir.create(paste0(outputFolder, '/male_group'), recursive = TRUE)
  if (!file.exists(paste0(outputFolder, '/female_group')))
    dir.create(paste0(outputFolder, '/female_group'), recursive = TRUE)
  
  # subgroup study by sex
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "Assure")
  tcList <- read.csv(pathToCsv)[,1:2]
  tcCohortIds <- unique(c(tcList$targetId, tcList$comparatorId))
  
  # male and female table
  
  cohort_table_male <- paste0(cohortTable, '_male')
  cohort_table_female <- paste0(cohortTable, '_female')
  
  # outcome and negative cohorts
  sql <- 'select * into @cohort_database_schema.@cohort_table2 from @cohort_database_schema.@cohort_table where cohort_definition_id not in (@tcCohortIds)'
  sql <- SqlRender::render(sql, 
                cohort_database_schema = cohortDatabaseSchema,
                cohort_table = cohortTable,
                cohort_table2 = cohort_table_male,
                tcCohortIds = tcCohortIds)
  DatabaseConnector::executeSql(conn, sql)
  
  # target andn comparator cohorts male only
  sql <- 'insert into @cohort_database_schema.@cohort_table2 select cohort_definition_id, subject_id, cohort_start_date, cohort_end_date from (select c.*, p.gender_concept_id from @cohort_database_schema.@cohort_table c left join @cdm_database_schema.person p on c.subject_id = p.person_id where cohort_definition_id in (@tcCohortIds)) a where a.gender_concept_id = 8507'
  sql <- SqlRender::render(sql,
                cdm_database_schema = cdmDatabaseSchema,
                cohort_database_schema = cohortDatabaseSchema,
                cohort_table = cohortTable,
                cohort_table2 = cohort_table_male,
                tcCohortIds = tcCohortIds)
  DatabaseConnector::executeSql(conn, sql)
  
  # run cohortMethods
  ParallelLogger::logInfo("Running subgroup analyses - MALE")
  runCohortMethod(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohort_table_male,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = paste0(outputFolder, '/male_group'),
                  maxCores = maxCores)
  ParallelLogger::logInfo("Packaging results")
  exportResults(outputFolder = paste0(outputFolder, '/male_group'),
                databaseId = databaseId,
                databaseName = databaseName,
                databaseDescription = databaseDescription,
                minCellCount = minCellCount,
                maxCores = maxCores)
  
  
  # outcome and negative cohorts
  sql <- 'select * into @cohort_database_schema.@cohort_table2 from @cohort_database_schema.@cohort_table where cohort_definition_id not in (@tcCohortIds)'
  sql <- SqlRender::render(sql, 
                cohort_database_schema = cohortDatabaseSchema,
                cohort_table = cohortTable,
                cohort_table2 = cohort_table_female,
                tcCohortIds = tcCohortIds)
  DatabaseConnector::executeSql(conn, sql)
  
  # target andn comparator cohorts male only
  sql <- 'insert into @cohort_database_schema.@cohort_table2 select cohort_definition_id, subject_id, cohort_start_date, cohort_end_date from (select c.*, p.gender_concept_id from @cohort_database_schema.@cohort_table c left join @cdm_database_schema.person p on c.subject_id = p.person_id where cohort_definition_id in (@tcCohortIds)) a where a.gender_concept_id = 8532'
  sql <- SqlRender::render(sql, 
                cdm_database_schema = cdmDatabaseSchema,
                cohort_database_schema = cohortDatabaseSchema,
                cohort_table = cohortTable,
                cohort_table2 = cohort_table_female,
                tcCohortIds = tcCohortIds)
  DatabaseConnector::executeSql(conn, sql)
  
  # run cohortMethods
  ParallelLogger::logInfo("Running subgroup analyses - FEMALE")
  runCohortMethod(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohort_table_female,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = paste0(outputFolder, '/female_group'),
                  maxCores = maxCores)
  ParallelLogger::logInfo("Packaging results")
  exportResults(outputFolder = paste0(outputFolder, '/female_group'),
                databaseId = databaseId,
                databaseName = databaseName,
                databaseDescription = databaseDescription,
                minCellCount = minCellCount,
                maxCores = maxCores)
  
}

