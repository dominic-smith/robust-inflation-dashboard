# Download the latest BEA underlying PCE detail workbook (Section 2, all tables).
# This is the ONLY monthly-changing input; everything else is static author
# classification. Run with the working directory at compute/code/.
#
# The file is the same one the paper uses (Section2All_xls.xlsx), pulled live from
# BEA rather than from a frozen copy — so the dashboard tracks the current vintage.

BEA_URL  <- "https://apps.bea.gov/national/Release/XLS/Underlying/Section2All_xls.xlsx"
DEST     <- "../data/1_raw/Section2All_xls.xlsx"

download_bea <- function(url = BEA_URL, dest = DEST) {
  old <- options(timeout = 600); on.exit(options(old))
  message("Downloading BEA underlying PCE detail from:\n  ", url)
  tmp <- tempfile(fileext = ".xlsx")
  utils::download.file(url, tmp, mode = "wb", quiet = FALSE)
  if (!file.exists(tmp) || file.size(tmp) < 1e6) {
    stop("BEA download looks too small (", file.size(tmp), " bytes). ",
         "Check the URL or download Section2All_xls.xlsx manually into data/1_raw/.")
  }
  # Sanity: the workbook must expose the monthly price sheet the loader reads.
  sheets <- readxl::excel_sheets(tmp)
  if (!"U20404-M" %in% sheets) {
    stop("Downloaded workbook is missing sheet 'U20404-M'. BEA may have changed ",
         "the layout; the loader (01m) needs updating before trusting the output.")
  }
  file.copy(tmp, dest, overwrite = TRUE)
  message("Saved ", dest, " (", round(file.size(dest) / 1e6, 1), " MB, ",
          length(sheets), " sheets).")
  invisible(dest)
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) download_bea()
