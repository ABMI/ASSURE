library(Assure)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "s:/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
outputFolder <- "s:/Assure"

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = Sys.getenv("dbms"),
                                                                server = Sys.getenv("server"),
                                                                user = Sys.getenv("userID"),
                                                                password = Sys.getenv("userPW"),
                                                                port = Sys.getenv("PDW_PORT"),
                                                                pathToDriver = Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"))

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "your cdm database schema"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "your cohort database schema"
cohortTable <- "cohort table name"

# Some meta-information that will be used by the export function:
databaseId <- "your database id"
databaseName <- "your database name"
databaseDescription <- "brief description of your database"

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        createCohorts = TRUE,
        synthesizePositiveControls = FALSE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = F, launch.browser = T)

# Upload the results to the OHDSI SFTP server:
privateKeyFileName <- ""
userName <- ""
uploadResults(outputFolder, privateKeyFileName, userName)


# execute subgroup studies by sex

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        createCohorts = FALSE,
        synthesizePositiveControls = FALSE,
        runAnalyses = FALSE,
        packageResults = FALSE,
        subgroup = FALSE,
        maxCores = maxCores)

# MALE
resultsZipFile <- file.path(paste0(outputFolder, '/male_group'), "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(paste0(outputFolder, '/male_group'), "shinyData")
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = F, launch.browser = T)


# FEMALE
resultsZipFile <- file.path(paste0(outputFolder, '/female_group'), "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(paste0(outputFolder, '/female_group'), "shinyData")
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = F, launch.browser = T)

