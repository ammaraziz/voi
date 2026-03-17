pacman::p_load(dplyr, tidyr, ggplot2, pheatmap, viridis, gridExtra, svglite, optparse)

option_list <- list(
  make_option(c("-i","--input"), help = "input tsv snp dist", 
              action="store", type="character", default=NA),
  make_option(c("-m","--meta"), help = "meta.tsv file containing meta data information", 
              action="store", type="character", default=NA),
  make_option(c("-o","--output"), help = "output path and name",
              action="store", type="character", default=NA),
  make_option(c("-g","--genotype"), help = "genotype - number only",
              action="store", type="character", default=NA)
)

parser <- OptionParser(
  usage = paste("%prog -i [INPUTDIR] -o [OUTPUTDIR]",
                "Script to plot genotype specific trees", sep="\n"),
  epilogue = "INPUT, OUTPUT are required",
  option_list=option_list
)

#custom function to stop quietly
stop_quietly = function(message) {
  opt = options(show.error.messages = FALSE)
  on.exit(options(opt))
  cat(message, sep = "\n")
  quit()
}

arguments=NA
tryCatch(
  { arguments = parse_args(object = parser, positional_arguments = FALSE) },
  error = function(e) { }
)

if (any(is.na(arguments$options))) {
  stop_quietly(parser$usage)
}

if (interactive()) {
  arguments = list(
    meta = "../output/all.metadata.tsv",
    input = "../output/snpdist/snpdist.vidrl.tsv",
    output = "tmp.pdf",
    genotype = "HAV-A1"
  )
}

meta = read.csv(arguments$meta, sep = "\t") %>%
    mutate(name = case_when(
        grepl("AUST", Source) ~ paste(Sample_ID, Country, strain, sep = "|"),
        TRUE ~ paste(Country, Suspected_Country_Infection, strain, sep = "|")
        )
    )

# remove the first line 
snpdist_cluster = read.csv(arguments$input, sep = "\t", header = F) %>%
    slice(-1)

# extract width for subsetting downstream
# nrow is used due to the first column being names.
# the matrix is square, therefore nrow gives correct value
width = nrow(snpdist_cluster)

# rename columns
colnames(snpdist_cluster) = c("id", snpdist_cluster$V1)
snpdist_cluster = left_join(snpdist_cluster, meta, by = c("id" = "strain"))
snpdist_cluster_matrix = snpdist_cluster[, c(2:width)]

snpdistplot = pheatmap(mat = snpdist_cluster_matrix,
         labels_row = snpdist_cluster$name,
         labels_col = snpdist_cluster$name,
         display_numbers = T,
         number_format = "%.0f",
         treeheight_row = 0,
         treeheight_col = 0,
         number_color = "black",
         viridis(10, direction = -1, begin = 0.2),
         fontsize=15
         )[[4]]


ggsave(filename=arguments$output, plot=snpdistplot, width = 297, height = 210, units = "mm")
# 
# ### snp dist with gaps and ambig
# snpdist_cluster_gaps = read.csv("../output/snpdist/snpdistgaps.vidrl.tsv", sep = "\t", header = F) %>%
#     slice(-1)
# colnames(snpdist_cluster_gaps) = c("id", snpdist_cluster_gaps$V1)
# snpdist_cluster_gaps = left_join(snpdist_cluster_gaps, meta, by = c("id" = "strain"))
# snpdist_cluster_gaps_matrix = snpdist_cluster_gaps[, c(2:15)] %>% mutate(QLD_2892S = as.integer(QLD_2892S))
# 
# plot_gaps = pheatmap(mat = snpdist_cluster_gaps_matrix,
#                 labels_row = snpdist_cluster_gaps$name,
#                 labels_col = snpdist_cluster_gaps$name,
#                 display_numbers = T,
#                 number_format = "%.0f",
#                 treeheight_row = 0,
#                 treeheight_col = 0,
#                 number_color = "black",
#                 viridis(10, direction = -1, begin = 0.2),
#                 fontsize=15)[[4]]
# 
# plot_arrange_gaps = grid.arrange(plot_gaps, nrow=1, ncol=1)
# ggsave(filename="snpdist_cluster_gaps.pdf", plot=plot_arrange_gaps, width = 297, height = 210, units = "mm")
