
library(httr)
library(jsonlite)

res <- GET("https://fingertips.phe.org.uk/api/indicator_metadata/by_indicator_id?indicator_ids=253%2C%20255")
            

dt <- fromJSON(rawToChar(res$content), simplifyDataFrame = TRUE )


res$status_code

res$content

dt$`253`


pluck_result <- function(req) {
  req |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::pluck("result")
}


pluck_result(dt)

b<- unlist(dt, use.names = TRUE, recursive = FALSE)

library(fingertipsR)
