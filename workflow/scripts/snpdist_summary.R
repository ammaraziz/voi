pacman::p_load(ggplot2, dplyr, tidyr,  optparse)

option_list <- list(
  make_option(
    c("-m", "--meta"),
    help = "meta.tsv file containing meta data information",
    action = "store",
    type = "character",
    default = NA
  ),
  make_option(
    c("-d", "--dist"),
    help = "dist.tsv file containing snp distance matrix",
    action = "store",
    type = "character",
    default = NA
  ),
  make_option(
    c("-o", "--output"),
    help = "output folder for stats files",
    action = "store",
    type = "character",
    default = NA
    )
  )


parser <- OptionParser(
  usage = paste(
    "%prog -m [META] -d [DIST] -o [OUTPUTDIR] ",
    "Generic script to plot histogram",
    sep = "\n"
  ),
  epilogue = "Meta file, Distance Matrix and OUTPUT DIR are required",
  option_list = option_list
)

#custom function to stop quietly
stop_quietly = function(message) {
  opt = options(show.error.messages = FALSE)
  on.exit(options(opt))
  cat(message, sep = "\n")
  quit()
}

arguments = NA
tryCatch(
  {
    arguments = parse_args(object = parser, positional_arguments = FALSE)
  },
  error = function(e) {}
)

if (any(is.na(arguments$options))) {
  stop_quietly(parser$usage)
}

if (interactive()) {
  arguments = list(
    meta = "../../results-wgs-b3/raw/all.tsv",
    dist = "../../results-wgs-b3/snpdist/snpdist.all.tsv",
    output = "../../results-wgs-b3/snpdist/"
  )
}

meta <- read.csv(arguments$meta, sep = "\t")
dist <- read.csv(arguments$dist, sep = "\t", skip=1, header=FALSE, row.names = 1)
colnames(dist) <- rownames(dist)
dist$id <- rownames(dist)
outdir <- arguments$output

join_dist <- left_join(dist, meta%>%select(notification_id, outbreak_ref, DSid), by=c("id"="notification_id"))


df_outbreak <- data.frame(
  outbreak=character(),
  n=integer(),
  max=numeric(),
  min=numeric(),
  mean=numeric()
)

for (outb in unique(unique(join_dist$outbreak_ref))) {
  if (is.na(outb)){
    next
  } else {
    sub_df <- join_dist %>% filter(outbreak_ref == outb)
    samples <- sub_df$id
    num_samples <- length(samples)
    sub_matrix <- as.matrix(sub_df %>% select(all_of(samples)))
    max <- max(sub_matrix, na.rm=TRUE)
    min <- min(sub_matrix, na.rm=TRUE)
    mean <- mean(sub_matrix, na.rm=TRUE)
    df_outbreak <- df_outbreak %>% add_row(outbreak=outb, n=num_samples, max=max, min=min, mean=mean)
  }
}

df_dsid <- data.frame(
  dsid=integer(),
  n=integer(),
  max=numeric(),
  min=numeric(),
  mean=numeric()
)

for (ds in unique(join_dist$DSid)){
  if (is.na(ds)){
    next
  } else {
    sub_df <- join_dist %>% filter(DSid == ds)
    samples <- sub_df$id
    num_samples <- length(samples)
    sub_matrix <- as.matrix(sub_df %>% select(all_of(samples)))
    max <- max(sub_matrix, na.rm=TRUE)
    min <- min(sub_matrix, na.rm=TRUE)
    mean <- mean(sub_matrix, na.rm=TRUE)
    df_dsid <- df_dsid %>% add_row(dsid=ds, n=num_samples, max=max, min=min, mean=mean)
  }
}

## save summary to files
if (!dir.exists(outdir)) {
  dir.create(outdir)
}
outbreak_file <- paste(outdir, "/outbreak_ref_snp_summary.csv", sep="")
write.csv(df_outbreak, outbreak_file, row.names = F)
ds_file <- paste(outdir, "/ssid_snp_summary.csv", sep="")
write.csv(df_dsid, ds_file, row.names = F)
#df_dsid
