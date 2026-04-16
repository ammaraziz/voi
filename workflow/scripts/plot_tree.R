pacman::p_load(
  dplyr,
  ggplot2,
  ggtree,
  treeio,
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
    output = "../../results/plots/global.pdf"
    )
}

tree = read.newick(arguments$tree)
meta = read.csv(arguments$meta, sep = "\t")

meta_heatmap = meta %>%
  select(notification_id, 
         State,
         `Aquisition (Country)` = place_of_acquisition_country,
         `Outbreak Ref #` = outbreak_ref,
         DSid) %>%
  tibble::column_to_rownames('notification_id')

tree_plot = ggtree(tree) %<+% meta +
  geom_tippoint() +
  geom_tiplab(aes(label = Designation))+
  coord_cartesian(clip = 'off', expand = FALSE) +
  geom_treescale(x=0.004)

tree_heatmap_plot = gheatmap(p = tree_plot,
                             data = meta_heatmap
                             ) + 
  scale_fill_viridis_d()

ggsave(
  filename = arguments$output,
  plot = tree_plot,
  device = "pdf",
  width = 297,
  height = 210,
  units = "mm"
)
