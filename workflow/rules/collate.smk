rule collate:
    input:
        backbone=config["input"]["meta"]["backbone"],
        backbone_seq=config["input"]["fasta"]["backbone"],
        samples=config["input"]["meta"]["samples"],
        samples_seq=config["input"]["fasta"]["samples"],
    output:
        metadata=OUTDIR / "raw" / "all.tsv",
        sequences=OUTDIR / "raw" / "all.fasta",
    conda:
        "../envs/misc.yaml"
    threads: 1
    shell:
        """
    csvtk -t concat \
    {input.samples} \
    {input.backbone} -T > {output.metadata}

    seqkit seq \
    {input.backbone_seq} \
    {input.samples_seq} > {output.sequences}
    """
