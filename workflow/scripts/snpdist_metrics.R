library(dplyr)
library(optparse)

option_list <- list(
  make_option(
    c("-d", "--dist"),
    help = "dist.tsv file containing snp distance matrix",
    action = "store",
    type = "character",
    default = NA
    ),
  make_option(
    c("-m", "--meta"),
    help = "meta.tsv file containing meta data information",
    action = "store",
    type = "character",
    default = NA
    ),
  make_option(
    c("-g", "--group"),
    help = "compute statistics on this column (group) - can specify multiple times",
    action = "append",
    type = "character"
    ),
  make_option(
    c("-o", "--output"),
    help = "output file for stats",
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
    output = "tmp.csv",
    group = c("DSid", "outbreak_ref")
  )
}

meta <- read.csv(arguments$meta, sep = "\t")
dist <- read.csv(arguments$dist, sep = "\t", skip=1, header=FALSE)
colnames(dist) <- c("id", dist[, 1])

join_dist <- left_join(dist, meta, by = c("id" = colnames(meta)[1]))



compute_metrics = function(d, group, metrics) {
  if (isFALSE(group %in% colnames(meta))) {
    stop("Input grouping not in metadata: ", group)
  }
 
  for (item in unique(d[, group])) {
    if (is.na(item)){
      next
    } else {
      
      sub_df <- d %>% filter(!!sym(group) == item)
      samples <- sub_df$id
      sub_matrix <- as.matrix(sub_df %>% select(all_of(samples)))
      
      num_samples <- length(samples)
      max <- max(sub_matrix, na.rm=TRUE)
      min <- min(sub_matrix, na.rm=TRUE)
      mean <- mean(sub_matrix, na.rm=TRUE)
      
      metrics <- metrics %>% add_row(group=as.character(item), n=num_samples, max=max, min=min, mean=mean)
    }
  }
  return(metrics)
}

metrics <- data.frame(
  group=character(),
  n=integer(),
  max=numeric(),
  min=numeric(),
  mean=numeric()
)

for (g in arguments$group) {
  metrics = compute_metrics(d = join_dist, group = g, metrics = metrics)
}

write.csv(x = metrics, file = arguments$output, row.names = F)
