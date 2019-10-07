#' @importFrom purrr map2
#' @importFrom dplyr bind_rows %>%
drop_sublists <- function(list) {
  list_without_sublists <- list()
  names <- names(list)
  map2(list, names, function(element, name) {
    if (!is.list(element)) {
      list_without_sublists[[name]] <<- element
    }

  })
  list_without_sublists %>%
    bind_rows() %>%
    return()
}

rename_columns <- function(data, new_part) {
  names(data) <- paste(names(data), new_part, sep = "_")
  return(data)
}

#' @importFrom dplyr %>%
#' @export
get_header <- function(data, new_part) {
  data %>%
    drop_sublists() %>%
    rename_columns(new_part) %>%
    return()
}

#' @importFrom tibble tibble
#' @importFrom dplyr filter pull %>%
#' @importFrom stringr str_ends
#' @export
get_json_files_paths <- function() {
  tibble(files = list.files(path = Sys.getenv("JSON_DIRECTORY"), full.names = TRUE)) %>%
    filter(str_ends(files, ".json")) %>%
    pull(files) %>%
    return()
}
