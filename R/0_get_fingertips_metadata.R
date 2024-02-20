
library(httr)
library(jsonlite)

res <- GET("https://fingertips.phe.org.uk/api/indicator_metadata/by_indicator_id?indicator_ids=253%2C%20255")
            

dt <- fromJSON(rawToChar(res$content))


res$status_code

res$content

dt$`253`
