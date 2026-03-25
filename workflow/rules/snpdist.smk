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


rule mask_custom:
    input:
        cluster_seqs=rules.extract_cluster_sequences.output.alignment,
        all_seqs=rules.mask.output.sequences,
    output:
        masked_cluster=OUTDIR / "snpdist" / "cluster.masked.custom.fasta",
        masked_all=OUTDIR / "snpdist" / "all.masked.custom.fasta",
    log:
        OUTDIR / "logs" / "mask_custom.txt",
    conda:
        "../envs/augur.yaml"
    threads: 1
    params:
        bed=config["mask"]["custom"],
    message:
        "Masking custom region"
    shell:
        """
        augur mask \
            --mask {params.bed} \
            --sequence {input.cluster_seqs} \
            --output {output.masked_cluster} > {log} 2>&1

        augur mask \
            --mask {params.bed} \
            --sequence {input.all_seqs} \
            --output {output.masked_all} > {log} 2>&1
        """


rule calc_snpdist_cluster:
    input:
        sequences=rules.mask_custom.output.masked_cluster,
    output:
        snpdist=OUTDIR / "snpdist" / "snpdist.cluster.tsv",
        snpdistgaps=OUTDIR / "snpdist" / "snpdist.gaps.cluster.tsv",
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

    snp-dists -a {input.sequences} > {output.snpdistgaps}
    """


rule calc_all_snpdist:
    input:
        sequences=rules.mask_custom.output.masked_all,
    output:
        snpdist=OUTDIR / "snpdist" / "snpdist.all.tsv",
        snpdistgaps=OUTDIR / "snpdist" / "snpdist.gaps.all.tsv",
    conda:
        "../envs/snpdist.yaml"
    threads: 5
    message:
        "Calculating snp distance for all sequences"
    shell:
        """
    goalign compute distance \
    --model rawdist \
    --threads {threads} \
    --align {input.sequences} > {output.snpdist}

    snp-dists -a {input.sequences} > {output.snpdistgaps}
    """
