if not config["mask_snpdist"]["skip"]:

    rule extract_cluster_sequences:
        input:
            alignment=rules.mask.output.sequences,
        output:
            alignment=OUTDIR / "snpdist" / "cluster.fasta",
        conda:
            "../envs/misc.yaml"
        threads: 1
        params:
            include=config["filter"]["strains_include"],
        shell:
            """
            seqkit grep -f {params.include} {input.alignment} > {output.alignment}
            """

    use rule mask as mask_snpdist_all with:
        input:
            alignment=rules.mask.output.sequences,
        output:
            sequences=OUTDIR / "snpdist" / "all.masked.snpdist.fasta",

    use rule mask as mask_snpdist_cluster with:
        input:
            alignment=rules.extract_cluster_sequences.output.alignment,
        output:
            sequences=OUTDIR / "snpdist" / "cluster.masked.snpdist.fasta",

else:

    rule mask_snpdist_all:
        input:
            alignment=rules.mask.output.sequences,
        output:
            sequences=OUTDIR / "snpdist" / "all.masked.snpdist.fasta",
        shell:
            """
            cp {input} {output}
            """

    rule mask_snpdist_cluster:
        input:
            alignment=rules.mask.output.sequences,
        output:
            sequences=OUTDIR / "snpdist" / "cluster.masked.snpdist.fasta",
        shell:
            """
            cp {input} {output}
            """


rule calc_snpdist_cluster:
    input:
        sequences=rules.mask_snpdist_cluster.output.sequences,
    output:
        snpdist=OUTDIR / "snpdist" / "snpdist.cluster.tsv",
        snpdistgaps=OUTDIR / "snpdist" / "snpdist.gaps.cluster.tsv",
    log:
        OUTDIR / "logs" / "snpdist.txt",
    conda:
        "../envs/misc.yaml"
    threads: 5
    message:
        "Calculating snp distance for cluster sequences only"
    shell:
        """
    goalign compute distance \
    --model rawdist \
    --threads {threads} \
    --align {input.sequences} > {output.snpdist}

    snp-dists -a {input.sequences} > {output.snpdistgaps} >> {log} 2>&1
    """


use rule calc_snpdist_cluster as calc_snpdist_all with:
    input:
        sequences=rules.mask_snpdist_all.output.sequences,
    output:
        snpdist=OUTDIR / "snpdist" / "snpdist.all.tsv",
        snpdistgaps=OUTDIR / "snpdist" / "snpdist.gaps.all.tsv",
