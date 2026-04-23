"""
Export to auspice.json and visualisations with ggtree
"""


rule export:
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
    log:
        OUTDIR / "logs" / "export.log",
    conda:
        "../envs/augur.yaml"
    params:
        strain_id=config.get("strain_id_field", "strain"),
        metadata_columns=config["auspice"]["export"],
        auspice_root=OUTDIR / "nc_dataset" / "tree_root-sequence.json",
    message:
        """Exporting data files for auspice"""
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
    input:
        meta=rules.collate.output.metadata,
        tree=rules.tree_bootstrapped.output.tree,
    output:
        pdf=OUTDIR / "plots" / "tree.pdf",
    conda:
        "../envs/tree_plots.yaml"
    params:
        script_path=config["plots"]["scripts"]["tree"]["path"],
        extra_args=config["plots"]["scripts"]["tree"]["extra_args"]
    message:
        "Plotting global tree"
    shell:
        """
        Rscript {params.script_path} \
        --tree {input.tree} \
        --meta {input.meta} \
        --output {output.pdf} {params.extra_args} > /dev/null 2>&1
        """


rule plot_snpdist:
    input:
        meta=rules.collate.output.metadata,
        snpdist=rules.calc_snpdist_cluster.output.snpdist,
    output:
        snpdist=OUTDIR / "plots" / "snpdist.cluster.pdf",
    conda:
        "../envs/snpdist_plot.yaml"
    threads: 1
    params:
        script_path=config["plots"]["scripts"]["snpdist"]["path"],
        extra_args=config["plots"]["scripts"]["snpdist"]["extra_args"],
    message:
        "plotting heatmap for dist matrix"
    shell:
        """
        Rscript {params.script_path} \
        --input {input.snpdist} \
        --meta {input.meta} \
        --output {output.snpdist} {params.extra_args} > /dev/null 2>&1
        """


use rule plot_snpdist as plot_snpdist_all with:
    input:
        meta=rules.collate.output.metadata,
        snpdist=rules.calc_snpdist_all.output.snpdist,
    output:
        snpdist=OUTDIR / "plots" / "snpdist.pdf",
