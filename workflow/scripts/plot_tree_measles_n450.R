pacman::p_load(
  dplyr,
  ggplot2,
  ggtree,
  treeio,
  optparse,
  tidytree,
  ggnewscale,
  randomcoloR
)

rlang::global_handle()

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
    c("--offset_rate"),
    help = "The offset value heatmap away from the tree, 0.1 as default, if you would like to move if more right, increase by 0.1 slowly",
    action = "store",
    type = "double",
    default = 0.1
  ),
  make_option(
    c("--width_adjust"),
    help = "Whether you would like to adjust the heatmap cell width, add parameter if you would like to or need to",
    action = "store",
    type = "logical",
    default = FALSE
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
    meta = "../../results-b3/raw/all.tsv",
    #meta = "/Users/admin/Documents/VIDRL/outbreak/measles/CW_report/N450/d8.tsv",
    tree = "../../results-b3/tree/tree.boot.nwk",
    #tree = "/Users/admin/Documents/VIDRL/outbreak/measles/CW_report/N450/d8.tree.boot.nwk",
    output = "/Users/admin/Documents/VIDRL/outbreak/measles/CW_report/N450/b3-test.pdf",
    #output = "/Users/admin/Documents/VIDRL/outbreak/measles/CW_report/N450/d8.pdf"
    offset_rate = 0.11,
    width_adjust = TRUE
    )
}

tree = read.newick(arguments$tree)
meta = read.csv(arguments$meta, sep = "\t")
offset_rate = arguments$offset_rate
width_adjust = arguments$width_adjust

meta_heatmap = meta %>%
  select(notification_id, 
         State,
         `Aquisition (Country)` = place_of_acquisition_country,
         `Outbreak Ref #` = outbreak_ref,
         DSid) %>%
  tibble::column_to_rownames('notification_id') %>%
  mutate(State = case_when(
    is.na(State) ~ "International",
    TRUE ~ State
  )) %>%
  replace(is.na(.), 'Unknown') %>%
  mutate(DSid = case_when(
    DSid == "-" ~ "Unknown",
    DSid == "N/A" ~ "Unknown",
    TRUE ~ DSid
  ))

tree_plot = ggtree(tree) %<+% meta +
  geom_tippoint() +
  geom_tiplab(aes(label = Designation))+
  coord_cartesian(clip = 'off', expand = FALSE) +
  geom_treescale(x=0.004)

## create color pelette

assign_variable_colors <- function(vars, palette_func = rainbow) {
  unique_vars <- unique(vars)
  
  # Generate a color for each unique variable using a palette function
  # rainbow(n) or heat.colors(n) are common built-in options
  colors <- palette_func(length(unique_vars))
  
  # Create a named vector (variable name = color) for easy lookup
  color_map <- setNames(colors, unique_vars)
  
  # Return the mapped color vector for the original input
  return(color_map[vars])
}


add_heatmap <- function(gtree, meta_heatmap, offset_rate, width_adjust){
  ## make color vector
  total_color <- c("VIC"   = "#1F77B4",
                   "NT" = "#FF7F0E",
                   "QLD" = "#2CA02C",
                   "SA"   = "#D62728",
                   "TAS"  = "#9467BD",
                   "NSW" = "#FFD700",
                   "WA" = "#6A00FF",
                   "International" = "#FFF8DC")
  for (c in colnames(meta_heatmap)){
    if (c == "State"){
      next
    }
    tmp_color <- assign_variable_colors(unique(meta_heatmap[[c]]), distinctColorPalette)
    total_color <- c(tmp_color, total_color)
  }
  total_color["Unknown"] = "#FFF5EE"
  
  # calculate the tree paramters
  plot_dim_x <- ggplot_build(gtree)$layout$panel_scales_x[[1]]$range$range[2]
  tree_width <- range(ggplot_build(gtree)$data[[1]]$x)[2]
  
  width = 0.025
  #where to change if offset is not enough or too much
  #*0.11 is the default value
  offset <- plot_dim_x * offset_rate
  width_rate <- 1
  if (width_adjust){
    width_rate <- 1.6
  }
  
  p_tmp <- gtree
  for (c in colnames(meta_heatmap)){
    tmp_h <- p_tmp + new_scale_fill()
    p_tmp <- gheatmap(
      tmp_h, 
      meta_heatmap[, c, drop=FALSE],
      offset=offset,
      width=width,
      colnames_angle=90,
      colnames_position="top"
      ) +
      scale_fill_manual(c, values = total_color) + 
      guides(fill=guide_legend(ncol=2,byrow=TRUE))
    #where to change if there is gap between heatmap cols
    offset = offset + tree_width * width * width_rate
  }
  
  return(p_tmp)
}

heat_tree <- add_heatmap(tree_plot, meta_heatmap, offset_rate, width_adjust) +
  ylim(NA, tree$Nnode + 5)
  

ggsave(
  filename = arguments$output,
  plot = heat_tree,
  device = "pdf",
  width = 297*1.5,
  height = 210*1.5,
  units = "mm"
)

