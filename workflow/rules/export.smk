"""
Export to auspice.json and visualisations with ggtree
"""


rule export:
    message:
        """Exporting data files for auspice"""
    input:
        tree=rules.refine.output.tree,
        metadata=rules.collate.output.metadata,
        branch_lengths=rules.refine.output.node_data,
        traits=rules.traits.output.node_data,
        nt_muts=rules.ancestral.output.node_data,
        aa_muts=rules.translate.output.node_data,
        auspice_config=config["auspice"]["config"],
    output:
        auspice_json=OUTDIR / "auspice" / "tree.json",
    params:
        strain_id=config.get("strain_id_field", "strain"),
        metadata_columns=config["auspice"]["export"],
        auspice_root=OUTDIR / "nc_dataset" / "tree_root-sequence.json",
    log:
        OUTDIR / "logs" / "export.log",
    conda:
        "../envs/augur.yaml"
    shell:
        """
    augur export v2 \
        --tree {input.tree} \
        --metadata {input.metadata} \
        --metadata-id-columns {params.strain_id} \
        --metadata-columns {params.metadata_columns} \
        --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {params.traits} \
        --auspice-config {input.auspice_config} \
        --include-root-sequence \
        --output {output.auspice_json} > {log} 2>&1
    """


rule plot_tree:
    message:
        "Plotting global tree"
    input:
        meta=rules.collate.output.metadata,
        tree=rules.tree_bootstrapped.output.tree,
    output:
        pdf=OUTDIR / "plots" / "global.pdf",
    params:
        title="not-used",
        cluster=config["plots"]["cluster"],
        label=config["plots"],
    conda:
        "../envs/tree_plots.yaml"
    shell:
        """
        Rscript workflow/scripts/plot_tree.R \
        --tree {input.tree} \
        --meta {input.meta} \
        --output {output.pdf}
        """


rule plot_snpdist_cluster:
    message:
        "plotting heatmap for dist matrix"
    input:
        snpdist=rules.calc_snpdist_cluster.output.snpdist,
        meta=INDIR / "hav.tsv",
    output:
        snpdist=OUTDIR / "plots" / "snpdist.vidrl.pdf",
    threads: 1
    conda:
        "../envs/snpdist_plot.yaml"
    shell:
        """
        Rscript workflow/scripts/plot_snpdist.R \
        --input {input.snpdist} \
        --meta {input.meta} \
        --output {output.snpdist}
        """


rule plot_snpdist_all:
    message:
        "plotting heatmap for dist matrix"
    input:
        snpdist=rules.calc_all_snpdist.output.snpdist,
        meta=OUTDIR / "all.metadata.tsv",
    output:
        snpdist=OUTDIR / "plots" / "snpdist.all.pdf",
    conda:
        "../envs/snpdist_plot.yaml"
    threads: 1
    shell:
        """
        Rscript workflow/scripts/plot_snpdist.R \
        --input {input.snpdist} \
        --meta {input.meta} \
        --output {output.snpdist}
        """
