calculate_dsr2 <-
  function (data, x, n, stdpop = NULL, type = "full", confidence = 0.95, 
          multiplier = 1e+05, independent_events = TRUE, eventfreq = NULL, 
          ageband = NULL) {
  if (missing(data) | missing(x) | missing(n) | missing(stdpop)) {
    stop("function calculate_dsr requires at least 4 arguments: data, x, n, stdpop")
  }
  if (!is.data.frame(data)) {
    stop("data must be a data frame object")
  }
  if (!deparse(substitute(x)) %in% colnames(data)) {
    stop("x is not a field name from data")
  }
  if (!deparse(substitute(n)) %in% colnames(data)) {
    stop("n is not a field name from data")
  }
  if (!deparse(substitute(stdpop)) %in% colnames(data)) {
    stop("stdpop is not a field name from data")
  }
  data <- data %>% rename(x = {
    {
      x
    }
  }, n = {
    {
      n
    }
  }, stdpop = {
    {
      stdpop
    }
  })
  if (!is.numeric(data$x)) {
    stop("field x must be numeric")
  }
  else if (!is.numeric(data$n)) {
    stop("field n must be numeric")
  }
  else if (!is.numeric(data$stdpop)) {
    stop("field stdpop must be numeric")
  }
  else if (anyNA(data$n)) {
    stop("field n cannot have missing values")
  }
  else if (anyNA(data$stdpop)) {
    stop("field stdpop cannot have missing values")
  }
  else if (any(pull(data, x) < 0, na.rm = TRUE)) {
    stop("numerators must all be greater than or equal to zero")
  }
  else if (any(pull(data, n) <= 0)) {
    stop("denominators must all be greater than zero")
  }
  else if (any(pull(data, stdpop) < 0)) {
    stop("stdpop must all be greater than or equal to zero")
  }
  else if (!(type %in% c("value", "lower", "upper", 
                         "standard", "full"))) {
    stop("type must be one of value, lower, upper, standard or full")
  }
  else if (!is.numeric(confidence)) {
    stop("confidence must be numeric")
  }
  else if (length(confidence) > 2) {
    stop("a maximum of two confidence levels can be provided")
  }
  else if (length(confidence) == 2) {
    if (!(confidence[1] == 0.95 & confidence[2] == 0.998)) {
      stop("two confidence levels can only be produced if they are specified as 0.95 and 0.998")
    }
  }
  else if ((confidence < 0.9) | (confidence > 1 & confidence < 
                                 90) | (confidence > 100)) {
    stop("confidence level must be between 90 and 100 or between 0.9 and 1")
  }
  else if (!is.numeric(multiplier)) {
    stop("multiplier must be numeric")
  }
  else if (multiplier <= 0) {
    stop("multiplier must be greater than 0")
  }
  else if (!rlang::is_bool(independent_events)) {
    stop("independent_events must be TRUE or FALSE")
  }
  if (!independent_events) {
    if (missing(eventfreq)) {
      stop(paste0("function calculate_dsr requires an eventfreq column ", 
                  "to be specified when independent_events is FALSE"))
    }
    else if (!deparse(substitute(eventfreq)) %in% colnames(data)) {
      stop("eventfreq is not a field name from data")
    }
    else if (!is.numeric(data[[deparse(substitute(eventfreq))]])) {
      stop("eventfreq field must be numeric")
    }
    else if (anyNA(data[[deparse(substitute(eventfreq))]])) {
      stop("eventfreq field must not have any missing values")
    }
    if (missing(ageband)) {
      stop(paste0("function calculate_dsr requires an ageband column ", 
                  "to be specified when independent_events is FALSE"))
    }
    else if (!deparse(substitute(ageband)) %in% colnames(data)) {
      stop("ageband is not a field name from data")
    }
    else if (anyNA(data[[deparse(substitute(ageband))]])) {
      stop("ageband field must not have any missing values")
    }
  }
  if (independent_events) {
    dsrs <- dsr_inner2(data = data, x = x, n = n, stdpop = stdpop, 
                      type = type, confidence = confidence, multiplier = multiplier)
  }
  else {
    data <- data %>% rename(eventfreq = {
      {
        eventfreq
      }
    }, ageband = {
      {
        ageband
      }
    }) %>% group_by(eventfreq, .add = TRUE)
    grps <- group_vars(data)[!group_vars(data) %in% "eventfreq"]
    check_groups <- filter(summarise(group_by(data, pick(all_of(c(grps, 
                                                                  "ageband")))), num_n = n_distinct(.data$n), 
                                     num_stdpop = n_distinct(.data$stdpop), .groups = "drop"), 
                           .data$num_n > 1 | .data$num_stdpop > 1)
    if (nrow(check_groups) > 0) {
      stop(paste0("There are rows with the same grouping variables and ageband", 
                  " but with different populations (n) or standard populations", 
                  "(stdpop)"))
    }
    freq_var <- data %>% dsr_inner2(x = x, n = n, stdpop = stdpop, 
                                   type = type, confidence = confidence, multiplier = multiplier, 
                                   rtn_nonindependent_vardsr = TRUE) %>% mutate(freqvars = .data$vardsr * 
                                                                                  .data$eventfreq^2) %>% group_by(pick(all_of(grps))) %>% 
      summarise(custom_vardsr = sum(.data$freqvars), .groups = "drop")
    event_data <- data %>% mutate(events = .data$eventfreq * 
                                    .data$x) %>% group_by(pick(all_of(c(grps, "ageband", 
                                                                        "n", "stdpop")))) %>% summarise(x = sum(.data$events, 
                                                                                                                na.rm = TRUE), .groups = "drop")
    dsrs <- event_data %>% left_join(freq_var, by = grps) %>% 
      group_by(pick(all_of(grps))) %>% dsr_inner2(x = x, 
                                                 n = n, stdpop = stdpop, type = type, confidence = confidence, 
                                                 multiplier = multiplier, use_nonindependent_vardsr = TRUE)
  }
  return(dsrs)
}



dsr_inner2 <-
function (data, x, n, stdpop, type, confidence, multiplier, rtn_nonindependent_vardsr = FALSE, 
          use_nonindependent_vardsr = FALSE) {
  if (isTRUE(rtn_nonindependent_vardsr) && ("custom_vardsr" %in% 
                                            names(data) || isTRUE(use_nonindependent_vardsr))) {
    stop("cannot get nonindependent vardsr and use nonindependent vardsr in the same execution")
  }
  confidence[confidence >= 90] <- confidence[confidence >= 
                                               90]/100
  conf1 <- confidence[1]
  conf2 <- confidence[2]
  if (!use_nonindependent_vardsr) {
    method = "Dobson"
    data <- data %>% mutate(custom_vardsr = NA_real_)
  }
  else {
    method = "Dobson, with confidence adjusted for non-independent events"
  }
  dsrs <- data %>% mutate(wt_rate = PHEindicatormethods:::na.zero(.data$x) * .data$stdpop/.data$n, 
                          sq_rate = PHEindicatormethods:::na.zero(.data$x) * (.data$stdpop/(.data$n))^2, 
  ) %>% summarise(total_count = sum(.data$x, na.rm = TRUE), 
                  total_pop = sum(.data$n), value = sum(.data$wt_rate)/sum(.data$stdpop) * 
                    multiplier, vardsr = case_when(isTRUE(use_nonindependent_vardsr) ~ 
                                                     unique(.data$custom_vardsr), .default = 1/sum(.data$stdpop)^2 * 
                                                     sum(.data$sq_rate)), .groups = "keep")
  if (!rtn_nonindependent_vardsr) {
    dsrs <- mutate(ungroup(dsrs), lowercl = .data$value + 
                     sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_lower(.data$total_count, 
                                                                         conf1) - .data$total_count) * multiplier, uppercl = .data$value + 
                     sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_upper(.data$total_count, 
                                                                         conf1) - .data$total_count) * multiplier, lower99_8cl = .data$value + 
                     sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_lower(.data$total_count, 
                                                                         0.998) - .data$total_count) * multiplier, upper99_8cl = .data$value + 
                     sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_upper(.data$total_count, 
                                                                         0.998) - .data$total_count) * multiplier) %>% 
      mutate(confidence = paste0(confidence * 100, "%", 
                                 collapse = ", "), statistic = paste("dsr per", 
                                                                     format(multiplier, scientific = FALSE)), method = method)
    if (!is.na(conf2)) {
      names(dsrs)[names(dsrs) == "lowercl"] <- "lower95_0cl"
      names(dsrs)[names(dsrs) == "uppercl"] <- "upper95_0cl"
    }
    else {
      dsrs <- dsrs %>% select(!c("lower99_8cl", "upper99_8cl"))
    }
    # dsrs <- dsrs %>% mutate(across(c("value", starts_with("upper"), 
    #                                  starts_with("lower")), function(x) if_else(.data$total_count < 
    #                                                                               10, NA_real_, x))
    #                         , statistic = if_else(.data$total_count < 10, "dsr NA for total count < 10", .data$statistic))
  }
  if (rtn_nonindependent_vardsr) {
    dsrs <- dsrs %>% select(group_cols(), "vardsr")
  }
  else if (type == "lower") {
    dsrs <- dsrs %>% select(!c("total_count", "total_pop", 
                               "value", starts_with("upper"), "vardsr", 
                               "confidence", "statistic", "method"))
  }
  else if (type == "upper") {
    dsrs <- dsrs %>% select(!c("total_count", "total_pop", 
                               "value", starts_with("lower"), "vardsr", 
                               "confidence", "statistic", "method"))
  }
  else if (type == "value") {
    dsrs <- dsrs %>% select(!c("total_count", "total_pop", 
                               starts_with("lower"), starts_with("upper"), 
                               "vardsr", "confidence", "statistic", 
                               "method"))
  }
  else if (type == "standard") {
    dsrs <- dsrs %>% select(!c("vardsr", "confidence", 
                               "statistic", "method"))
  }
  else if (type == "full") {
    dsrs <- dsrs %>% select(!c("vardsr"))
  }
  return(dsrs)
}

