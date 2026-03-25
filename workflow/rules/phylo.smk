rule tree_bootstrapped:
    input:
        alignment=rules.mask.output.sequences,
    output:
        tree=OUTDIR / "tree" / "tree.boot.nwk",
    log:
        OUTDIR / "logs" / "tree.boot.txt",
    conda:
        "../envs/augur.yaml"
    threads: 50
    params:
        substitution=config["tree"]["model"],
        tree_params=config["tree"]["tree_params"],
    message:
        "Building bootstrap phylogenetic tree"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --nthreads {threads} \
            --override-default-args \
            --tree-builder-args={params.tree_params:q} \
            --substitution-model {params.substitution} > {log} 2>&1
        """


rule tree:
    input:
        alignment=rules.mask.output.sequences,
    output:
        tree=OUTDIR / "tree" / "tree.raw.nwk",
    log:
        OUTDIR / "logs" / "tree.txt",
    conda:
        "../envs/augur.yaml"
    threads: 20
    params:
        substitution=config["tree"]["model"],
    message:
        "Building tree"
    shell:
        """
    augur tree \
        --alignment {input.alignment} \
        --output {output.tree} \
        --nthreads {threads} \
        --override-default-args \
        --substitution-model {params.substitution} > {log} 2>&1
    """


rule refine:
    input:
        alignment=rules.mask.output.sequences,
        tree=rules.tree.output.tree,
        metadata=rules.collate.output.metadata,
    output:
        tree=OUTDIR / "tree" / "tree.refined.nwk",
        node_data=OUTDIR / "tree" / "nodedata" / "branch-lengths.json",
    log:
        OUTDIR / "logs" / "refine.txt",
    conda:
        "../envs/augur.yaml"
    threads: 1
    params:
        coalescent=config["refine"]["coalescent"],
        date_inference=config["refine"]["date_inference"],
        clock_filter_iqd=config["refine"]["clock_filter_iqd"],
        strain_id=config["auspice"]["strain_id_field"],
    message:
        """
    Refining tree
      - estimate timetree
      - use {params.coalescent} coalescent timescale
      - estimate {params.date_inference} node dates
    """
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --coalescent {params.coalescent} \
            --date-confidence \
            --date-inference {params.date_inference} \
            --clock-filter-iqd {params.clock_filter_iqd} \
            --stochastic-resolve \
            --verbosity 0 2> {log}
        """


rule ancestral:
    input:
        tree=rules.refine.output.tree,
        alignment=rules.mask.output.sequences,
        reference=config["align"]["reference"],
    output:
        node_data=OUTDIR / "tree" / "nodedata" / "nt-muts.json",
    log:
        OUTDIR / "logs" / "ancestral.txt",
    conda:
        "../envs/augur.yaml"
    params:
        inference=config["ancestral"]["inference"],
    message:
        "Reconstructing ancestral sequences and mutations"
    shell:
        """
    augur ancestral \
        --tree {input.tree} \
        --alignment {input.alignment} \
        --output-node-data {output.node_data} \
        --inference {params.inference} \
        --root-sequence {input.reference} > {log} 2>&1
    """


rule translate:
    """Translating amino acid sequences"""
    input:
        tree=rules.refine.output.tree,
        node_data=rules.ancestral.output.node_data,
        reference=config["align"]["reference"],
    output:
        node_data=OUTDIR / "tree" / "nodedata" / "aa_muts.json",
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data} > {log} 2>&1
        """


rule traits:
    input:
        tree=rules.refine.output.tree,
        metadata=rules.collate.output.metadata,
    output:
        node_data=OUTDIR / "tree" / "nodedata" / "traits.json",
    log:
        OUTDIR / "logs" / "traits.log",
    conda:
        "../envs/augur.yaml"
    params:
        strain_id=config.get("strain_id_field", "strain"),
        columns=config["traits"]["columns"],
    message:
        """Inferring ancestral traits"""
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --columns {params.columns} \
            --confidence \
            --output {output.node_data} > {log} 2>&1
        """
