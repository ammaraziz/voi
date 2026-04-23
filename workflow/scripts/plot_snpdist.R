library(dplyr)
library(pheatmap)
library(viridisLite)
library(optparse)
library(tibble)

rlang::global_handle()

option_list <- list(
  make_option(
    c("-i", "--input"),
    help = "input tsv snp dist.",
    action = "store",
    type = "character",
    default = NA
  ),
  make_option(
    c("-m", "--meta"),
    help = "file containing meta data information. This is used to plot the colored bars. In the meta.tsv the first column must match up with matrix.tsv first column.",
    action = "store",
    type = "character",
    default = NA
  ),
  make_option(
    c("-o", "--output"),
    help = "output path/file. Filetype is decided by the extension in the path. png, pdf, tiff, bmp, jpeg",
    action = "store",
    type = "character",
    default = NA
  ),
  make_option(
    c("--font-size"),
    help = "Control the font size",
    action = "store",
    type = "numeric",
    default = 12
  ),
  make_option(
    c("--decimals"),
    help = "Specify the number of decimals to show",
    action = "store",
    type = "numeric",
    default = 0
  ),
  make_option(
    c("--color-steps"),
    help = "Specify the number of viridis color steps to use.",
    action = "store",
    type = "numeric",
    default = 256
  ),
  make_option(
    c("--plot-type"),
    help = "Controls if to display the complete matrix complete, top or bottom half. Options: complete, top, bottom.",
    action = "store",
    type = "character",
    default = "all"
  ),
  make_option(
    c("-a", "--annotate-column"),
    help = "Given a metafile, select which column to include as an annotation column. Colors will be autoselected for you using colorbrew2 divergent scale. This flag can be specified multiple times.",
    action = "append",
    type = "character"
  ),
  make_option(
    c("--labels"),
    help = "Given a metafile, use this column in the metafile as the custom labels for heatmap",
    action = "store",
    type = "character",
    default = NA
  )
)

parser <- OptionParser(
  usage = paste(
    "%prog -i [INPUTDIR] -o [OUTPUTDIR]",
    "Plot heatmap",
    sep = "\n"
  ),
  option_list = option_list
)

arguments = parse_args(object = parser, positional_arguments = FALSE)

# control number of decimals to show
number_format = paste0("%.", arguments$decimals, "f")

# viridis colors
if (!is.na(arguments$`color-steps`)) {
  ucolors = viridis(arguments$`color-steps`, direction = -1, begin = 0.2)
} else {
  ucolors = viridis(256, direction = -1, begin = 0.1)
}

# annotation column colors
acolors = c(
  '#1f78b4',
  '#33a02c',
  '#e31a1c',
  '#6a3d9a',
  '#b15928',
  "#FA8072",
  "#FFD700",
  "#bdbdbd"
)

# read in data
distdata = read.csv(arguments$input, sep = "\t", header = F, skip = 1) %>%
  rename(id = V1)
rownames(distdata) = distdata$id
colnames(distdata) = c("id", distdata$id)

# keep track of how big the matrix is
matrix_width = nrow(distdata) - 1

# metadata
if (!is.na(arguments$meta)) {
  meta = read.csv(arguments$meta, sep = "\t")
  if (!is.null(arguments$`annotate-column`)) {
    # create annotation dataframe
    annotations = distdata %>%
      select(id) %>%
      left_join(meta, by = c("id" = colnames(meta)[1])) %>%
      mutate(across(everything(), as.factor))
    rownames(annotations) = annotations$id
    # subset to requested annotations
    annotations = annotations[, c(arguments$`annotate-column`), drop = FALSE]

    # create colours
    anno_colors = list()
    for (colname in arguments$`annotate-column`) {
      col_len = length(unique(annotations[, colname]))
      dat = list(setNames(
        rep(acolors, length.out = col_len),
        unique(annotations[, colname])
      ))
      names(dat) = colname
      anno_colors = append(anno_colors, dat)
    }
  } else {
    anno_colors = NA
    annotations = NA
  }

  # custom labels
  if (!is.na(arguments$labels)) {
    if (arguments$label %in% colnames(meta)) {
      labs = distdata %>%
        select(id) %>%
        left_join(meta, by = c("id" = colnames(meta)[1])) %>%
        pull(arguments$label)
      labels_row = labs
      labels_col = labs
    } else {
      stop(
        "Ooops - you specified a column name that does not match the colnames in the input meta file. Check inputs."
      )
    }
  } else {
    labels_row = rownames(meta)
    labels_col = rownames(meta)
  }
} else {
  annotations = NA
  anno_colors = NA
  labels_row = rownames(distdata)
  labels_col = colnames(distdata)
}

# convert to matrix
plot_matrix = as.matrix(distdata[, c(2:matrix_width)])
#calc dist for clustering then get order
order = hclust(dist(t(plot_matrix), method = "euclidean"))$order
plot_matrix = plot_matrix[order, order]
#keep display numbers for later use
display_numbers = round(plot_matrix, arguments$decimals)

# control what to display
if (arguments$`plot-type` == "all") {
  plot_matrix = plot_matrix
} else if (arguments$`plot-type` == "bottom") {
  plot_matrix[upper.tri(plot_matrix)] = NA
  display_numbers[upper.tri(plot_matrix)] = ''
} else if (arguments$`plot-type` == "top") {
  plot_matrix[lower.tri(plot_matrix)] = NA
  display_numbers[lower.tri(plot_matrix)] = ''
} else {
  stop("Whoops - can only choose from all, top, bottom.")
}

pheatmap(
  mat = plot_matrix,
  color = ucolors,
  display_numbers = display_numbers,
  angle_col = 90,
  annotation_row = annotations,
  annotation_colors = anno_colors,
  cluster_cols = F,
  cluster_rows = F,
  border_color = NA,
  number_color = "black",
  fontsize_number = arguments$`font-size`,
  fontsize_row = 12,
  fontsize_col = 12,
  filename = arguments$output,
  width = 11.7*2,
  height = 8.27*2,
  labels_row = labels_row,
  labels_col = labels_col
)
