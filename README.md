**ASSURE** (Adolescent ADHD and SSRI safety Using REal-world data) study
==============================

<img src="https://img.shields.io/badge/Study%20Status-Design%20Finalized-brightgreen.svg" alt="Study Status: Design Finalized">

- Analytics use case(s): **Population-level Estimation**
- Study type: **Clinical Application**
- Tags: **FEEDER-NET**

- Study lead: **Chungsoo Kim**, **Dong Yun Lee**, **Rae Woong Park**, **Yunmi Shin**
- Study lead forums tag: **[[Chungsoo_Kim]](https://forums.ohdsi.org/u/Chungsoo_Kim)**, **[[RWPark]](https://forums.ohdsi.org/u/rwpark)**
- Study start date: **Dec 1, 2021**
- Study end date: **-**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**

Comprehensive comparative safety study of SSRI for adolescent ADHD and depression cormobid population.


Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery, or Microsoft APS.
- R version 3.5.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 25 GB of free disk space

How to run
==========
1. Follow [these instructions](https://ohdsi.github.io/Hades/rSetup.html) for seting up your R environment, including RTools and Java. 

2. Open your study package in RStudio. Use the following code to install all the dependencies:

	```r
	renv::restore()
	```

3. In RStudio, select 'Build' then 'Install and Restart' to build the package.

3. Once installed, you can execute the study by modifying and using the code below. For your convenience, this code is also provided under `extras/CodeToRun.R`:

	```r
	library(adhdAdolescent)
	
  # Optional: specify where the temporary files (used by the Andromeda package) will be created:
  options(andromedaTempFolder = "s:/andromedaTemp")
	
	# Maximum number of cores to be used:
	maxCores <- parallel::detectCores()
	
	# Minimum cell count when exporting data:
	minCellCount <- 5
	
	# The folder where the study intermediate and result files will be written:
	outputFolder <- "s:/adhdAdolescent"
	
	# Details for connecting to the server:
	# See ?DatabaseConnector::createConnectionDetails for help
	connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
									server = "some.server.com/ohdsi",
									user = "joe",
									password = "secret")
	
	# The name of the database schema where the CDM data can be found:
	cdmDatabaseSchema <- "cdm_synpuf"
	
	# The name of the database schema and table where the study-specific cohorts will be instantiated:
	cohortDatabaseSchema <- "scratch.dbo"
	cohortTable <- "my_study_cohorts"
	
	# Some meta-information that will be used by the export function:
	databaseId <- "Synpuf"
	databaseName <- "Medicare Claims Synthetic Public Use Files (SynPUFs)"
	databaseDescription <- "Medicare Claims Synthetic Public Use Files (SynPUFs) were created to allow interested parties to gain familiarity using Medicare claims data while protecting beneficiary privacy. These files are intended to promote development of software and applications that utilize files in this format, train researchers on the use and complexities of Centers for Medicare and Medicaid Services (CMS) claims, and support safe data mining innovations. The SynPUFs were created by combining randomized information from multiple unique beneficiaries and changing variable values. This randomization and combining of beneficiary information ensures privacy of health information."
	
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
            synthesizePositiveControls = TRUE,
            runAnalyses = TRUE,
            packageResults = TRUE,
            maxCores = maxCores)
	```

4. To view the results, use the Shiny app:

	```r
	prepareForEvidenceExplorer("Result_<databaseId>.zip", "/shinyData")
	launchEvidenceExplorer("/shinyData", blind = TRUE)
	```
  
  Note that you can save plots from within the Shiny app. It is possible to view results from more than one database by applying `prepareForEvidenceExplorer` to the Results file from each database, and using the same data folder. Set `blind = FALSE` if you wish to be unblinded to the final results.
  
5. If you want to conduct subgroup studies by sex, you can execute as below
# subgroup study by sex
  ```r
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
  ```

License
=======
The ASSURE package is licensed under Apache License 2.0

Development
===========
ASSURE was developed in ATLAS and R Studio.

### Development status

Design finalized
