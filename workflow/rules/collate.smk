rule collate:
    input:
        backbone=INDIR / "backbone.tsv",
        backbone_seq=INDIR / "backbone.fasta",
        vidrl=INDIR / "input.tsv",
        vidrl_seq=INDIR / "input.fasta",
    output:
        metadata=OUTDIR / "raw" / "all.tsv",
        sequences=OUTDIR / "raw" / "all.fasta",
    threads: 1
    conda:
        "../envs/misc.yaml"
    shell:
        """
    csvtk -t concat \
    {input.vidrl} \
    {input.backbone} -T > {output.metadata}

    seqkit seq \
    {input.backbone_seq} \
    {input.vidrl_seq} > {output.sequences}
    """
