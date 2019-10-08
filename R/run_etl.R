#'@export
run_etl <- function() {
  Sys.setenv("JSON_DIRECTORY" = file.path(getwd(), "sample_gus_json"))
  transform_json_files(2)
  load_core_data()
}
