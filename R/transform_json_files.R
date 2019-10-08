#' Function that extract, transform and load data from Statistics Poland API
#' @param number_of_clusters number of CPU cores taking part in processing
#' @import foreach
#' @import doParallel
#' @import parallel
#' @importFrom jsonlite read_json
#' @importFrom purrr map_df
#' @importFrom dplyr bind_rows %>%
#' @importFrom RPostgres dbBegin dbWriteTable dbRollback dbCommit dbDisconnect
transform_json_files <- function(number_of_cores) {
  cluster <- makeCluster(number_of_cores)
  registerDoParallel(cluster)
  database_connection <- create_database_connection()
  file_paths <- get_json_files_paths()

  lapply(file_paths, function(file) {
    print(file)
    file_name_without_extension <- strsplit(file, "\\.")[[1]][[1]]
    tryCatch({
      table_final <- map_df(read_json(path = file), function(part) {
        children_list <- part$childs

        foreach(
          i = 1:length(children_list),
          .combine = "bind_rows",
          .packages = c("dplyr", "purrr"),
          .export = "get_header"
        ) %dopar% {
          child <- children_list[[i]]
          map_df(child$variables, function(variable) {
            map_df(variable$data, function(set) {
              do.call(bind_rows, set$values) %>%
                merge(get_header(set, "set"))
            }) %>%
              merge(get_header(variable, "variable"))
          }) %>%
            merge(get_header(child, "child"))
        } %>%
          merge(get_header(part, "part"))
      })

      dbBegin(database_connection)
      dbWriteTable(database_connection, "STG", table_final, append = TRUE)
      print("Data inserted to STG")
      dbCommit(database_connection)

    }, error = function(cond) {
      dbRollback(database_connection)
      print(paste("Error when processing JSON file: ", cond, sep = ""))
    })

  })

  dbDisconnect(database_connection)
  stopCluster(cluster)
}
