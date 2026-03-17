rule tree_bootstrapped:
    message:
        "Building bootstrap phylogenetic tree"
    input:
        alignment=rules.mask.output.sequences,
    output:
        tree=OUTDIR / "tree" / "tree.boot.nwk",
    threads: 50
    params:
        substitution=config["tree"]["model"],
        tree_params=config["tree"]["tree_params"],
    log:
        OUTDIR / "logs" / "tree.boot.txt",
    conda:
        "../envs/augur.yaml"
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
    message:
        "Building tree"
    input:
        alignment=rules.mask.output.sequences,
    output:
        tree=OUTDIR / "tree" / "tree.raw.nwk",
    threads: 20
    params:
        substitution=config["tree"]["model"],
    log:
        OUTDIR / "logs" / "tree.txt",
    conda:
        "../envs/augur.yaml"
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
    message:
        """
    Refining tree
      - estimate timetree
      - use {params.coalescent} coalescent timescale
      - estimate {params.date_inference} node dates
    """
    input:
        alignment=rules.mask.output.sequences,
        tree=rules.tree.output.tree,
        metadata=rules.collate.output.metadata,
    output:
        tree=OUTDIR / "tree" / "tree.refined.nwk",
        node_data=OUTDIR / "tree" / "nodedata" / "branch-lengths.json",
    log:
        OUTDIR / "logs" / "refine.txt",
    params:
        coalescent=config["refine"]["coalescent"],
        date_inference=config["refine"]["date_inference"],
        clock_filter_iqd=config["refine"]["clock_filter_iqd"],
        strain_id=config["auspice"]["strain_id_field"],
    threads: 1
    conda:
        "../envs/augur.yaml"
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
    message:
        "Reconstructing ancestral sequences and mutations"
    input:
        tree=rules.refine.output.tree,
        alignment=rules.mask.output.sequences,
        reference=config["align"]["reference"],
    output:
        node_data=OUTDIR / "tree" / "nodedata" / "nt-muts.json",
    params:
        inference=config["ancestral"]["inference"],
    log:
        OUTDIR / "logs" / "ancestral.txt",
    conda:
        "../envs/augur.yaml"
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
    message:
        """Inferring ancestral traits"""
    input:
        tree=rules.refine.output.tree,
        metadata=rules.collate.output.metadata,
    output:
        node_data=OUTDIR / "tree" / "nodedata" / "traits.json",
    params:
        strain_id=config.get("strain_id_field", "strain"),
        columns=config["traits"]["columns"],
    log:
        OUTDIR / "logs" / "traits.log",
    conda:
        "../envs/augur.yaml"
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
