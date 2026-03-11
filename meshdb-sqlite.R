library(DBI)
library(RSQLite)


con <- dbConnect(RSQLite::SQLite(), 'working-copies/meshnet-planning/2233580394.db')

dbListTables(con)

dbListFields(con, '2233580394_telemetry_host')

x <- dbReadTable(con, "2233580394_nodedb")
str(x)
