#' Select the latest data for each observation
#' @importFrom RPostgres dbBegin dbReadTable dbWriteTable dbRollback dbCommit dbDisconnect
#' @import dbplyr
#' @import dplyr
#' @export
load_core_data <- function() {
  database_connection <- create_database_connection()

  # tbl enables lazy loading
  STG <- tbl(database_connection, "STG") %>%
    select(
      year,
      val,
      name_set,
      n1_variable,
      measureUnitName_variable,
      name_child,
      name_part
    ) %>%
    filter(name_part == "SPORT") %>% # select sport data
    group_by_at(vars(contains("name")))%>%
    filter(
      year == max(year)# select the latest data
    ) %>%
    ungroup() %>%
    collect()

  CORE <- dbReadTable(database_connection, "CORE")

  CORE_NEW <- STG %>%
    select(-name_part) %>%
    rename(
      value = val,
      region = name_set,
      sport = n1_variable,
      measure_unit = measureUnitName_variable,
      training_type = name_child
    ) %>%
    distinct() %>% # remove duplicates
    setdiff(CORE) # do not insert currently available data

  if(nrow(CORE_NEW) != 0) {
    tryCatch({
      dbBegin(database_connection)
      dbWriteTable(database_connection, "CORE", CORE_NEW, append = TRUE)
      dbCommit(database_connection)
      print(paste("Loading to CORE succeded: ", err, sep = ""))
    }, error = function(err){
      dbRollback(database_connection)
      print(paste("Loading to CORE failed: ", err, sep = ""))
    }, finally = {
      dbDisconnect(database_connection)
    })
  } else {
    print("There was no new CORE data")
  }
}
