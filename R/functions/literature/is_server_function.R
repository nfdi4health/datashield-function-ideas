# Whether a DataSHIELD function name is a server function: ending in DS,
# DS1, DS2, ... or DS.<suffix> (e.g. meanDS, glmDS2, vcovDS.coxph).
is_server_function <- function(fn) grepl("DS[0-9]*($|\\.)", fn)
