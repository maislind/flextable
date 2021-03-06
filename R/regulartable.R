#' @rdname flextable
#' @importFrom stats setNames
#' @export
regulartable <- function( data, col_keys = names(data), cwidth = .75, cheight = .25 ){
  stopifnot(is.data.frame(data))

  if( any( duplicated(col_keys) ) ){
    stop("duplicated col_keys")
  }

  blanks <- setdiff( col_keys, names(data))
  if( length( blanks ) > 0 ){
    blanks_col <- lapply(blanks, function(x, n) character(n), nrow(data) )
    blanks_col <- setNames(blanks_col, blanks )
    data[blanks] <- blanks_col
  }

  body <- simple_tabpart( data = data, col_keys = col_keys, cwidth = cwidth, cheight = cheight )

  # header
  header_data <- setNames(as.list(col_keys), col_keys)
  header_data[blanks] <- as.list( rep("", length(blanks)) )
  header_data <- as.data.frame(header_data, stringsAsFactors = FALSE, check.names = FALSE)

  header <- simple_tabpart( data = header_data, col_keys = col_keys, cwidth = cwidth, cheight = cheight )

  footer_data <- header_data[FALSE, , drop = FALSE]
  footer <- simple_tabpart( data = footer_data, col_keys = col_keys, cwidth = cwidth, cheight = cheight )

  out <- list( header = header, body = body, footer = footer, col_keys = col_keys,
               blanks = blanks )
  class(out) <- c("flextable", "regulartable")

  out <- style( x = out,
                pr_p = fp_par(text.align = "right", padding = 2),
                pr_c = fp_cell(border = fp_border()), part = "all")
  out <- set_formatter_type(out)
  out
}



#' @title set column formatter functions
#' @description Define formatter functions associated to each column key.
#' Functions have a single argument (the vector) and are returning the formatted
#' values as a character vector.
#' @param x a regulartable object
#' @param ... Name-value pairs of functions, names should be existing col_key values
#' @param part partname of the table (one of 'body' or 'header' or 'footer')
#' @examples
#' ft <- regulartable( head( iris ) )
#' ft <- set_formatter( x = ft,
#'         Sepal.Length = function(x) sprintf("%.02f", x),
#'         Sepal.Width = function(x) sprintf("%.04f", x)
#'       )
#' ft <- theme_vanilla( ft )
#' ft
#' @export
set_formatter <- function(x, ..., part = "body"){

  stopifnot(inherits(x, "regulartable"))

  part <- match.arg(part, c("body", "header", "footer"), several.ok = FALSE )
  formatters <- list(...)
  col_keys <- names(formatters)
  col_keys <- intersect(col_keys, x[[part]]$col_keys)
  x[[part]]$printers[col_keys] <- formatters[col_keys]
  x
}


#' @export
#' @rdname set_formatter
#' @section set_formatter_type:
#' \code{set_formatter_type} is an helper function to quickly define
#' formatter functions regarding to column types.
#' @param fmt_double,fmt_integer arguments used by \code{sprintf} to
#' format double and integer columns.
#' @param fmt_date,fmt_datetime arguments used by \code{format} to
#' format date and date time columns.
#' @param fun_any function name (character) to use to convert other types of columns
#' as characters. Note that factors and strings are not transformed by
#' this function.
set_formatter_type <- function(x, fmt_double = "%.03f", fmt_integer = "%.0f",
                               fmt_date = "%Y-%m-%d", fmt_datetime = "%Y-%m-%d %H:%M:%S",
                               fun_any = "format"){

  stopifnot(inherits(x, "regulartable"))

  col_keys <- setdiff(x[["body"]]$col_keys, x$blanks)
  formatters <- lapply(x[["body"]]$dataset[col_keys], function(x){
    if( is.double(x) ) paste0("function(x) sprintf(", shQuote(fmt_double), ", x)")
    else if( is.integer(x) ) paste0("function(x) sprintf(", shQuote(fmt_integer), ", x)")
    else if( is.factor(x) ) "function(x) as.character(x)"
    else if( is.character(x) ) "function(x) as.character(x)"
    else if( inherits(x, "Date") ) paste0("function(x) format(x, ", shQuote(fmt_date), ")")
    else if( inherits(x, "POSIXt") ) paste0("function(x) format(x, ", shQuote(fmt_datetime), ")")
    else paste0("function(x) ", fun_any, "(x)")
  })
  formatters <- lapply( formatters, function(x) eval(parse( text = x)) )
  x[["body"]]$printers[col_keys] <- formatters[col_keys]
  x
}


