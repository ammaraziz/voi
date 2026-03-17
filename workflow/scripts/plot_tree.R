pacman::p_load(
  dplyr,
  tidyr,
  ggplot2,
  pheatmap,
  ggtree,
  treeio,
  patchwork,
  lubridate,
  optparse,
  tidytree
)

option_list <- list(
  make_option(
    c("-t", "--tree"),
    help = "inputtree nwk",
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
    c("-o", "--output"),
    help = "output name without extension",
    action = "store",
    type = "character",
    default = NA
  ),
  make_option(
    c("-c", "--color"),
    help = "color by column in meta file input",
    action = "store",
    type = "character",
    default = ""
  ),
  make_option(
    c("-l", "--label"),
    help = "which labels to put on the tree, if specified blank then none is printed",
    action = "store",
    type = "character",
    default = "strain"
  )
)

parser <- OptionParser(
  usage = paste(
    "%prog -i [INPUTDIR] -o [OUTPUTDIR]",
    "Generic script to plot trees",
    sep = "\n"
  ),
  epilogue = "INPUT, OUTPUT are required",
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
    meta = "../../results/raw/all.tsv",
    tree = "../../results/tree/tree.boot.nwk",
    output = "hav-2026-outbreak.pdf",
    label = "",
    color = "Country"
  )
}

tree = read.newick(arguments$tree)
meta = read.csv(arguments$meta, sep = "\t")


tree_plot = ggtree(tree)

if (nchar(arguments$label) > 0) {
  tree_plot + geom_tiplab(aes(label = arguments$label))
}

if (nchar(arguments$color) > 0) {
  if ( arguments$color %in% colnames(meta) ) {
    tree_plot + 
    color = geom_tippoint(aes(fill = arguments$color), shape = 21, size = 2)
  } else {
    print(paste0("Count not find ", arguments$color, " in input meta.tsv. Using geom_point without fill"))
    tree_plot +
    color = geom_tippoint(color="grey50", shape = 21, size = 2)
  }
} else {
  tree_plot + geom_blank()
}

ggsave(
  filename = arguments$output,
  plot = tree_plot,
  device = "pdf",
  width = 297,
  height = 210,
  units = "mm"
)
