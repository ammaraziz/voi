"""
Snakefile for cleaning and aligning msa
"""


rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences=rules.collate.output.sequences,
        reference=config["align"]["reference"],
    output:
        alignment=OUTDIR / "align" / "all.fasta",
    threads: 20
    log:
        OUTDIR / "logs" / "align.txt",
    conda:
        "../envs/augur.yaml"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --fill-gaps \
            --nthreads {threads} > {log} 2>&1
        """


rule mask:
    """
    Mask start and end of alignments
    """
    input:
        alignment=rules.align.output.alignment,
    output:
        sequences=OUTDIR / "align" / "masked.fasta",
    params:
        bed=config["mask"]["utr"],
    threads: 1
    log:
        OUTDIR / "logs" / "mask.txt",
    conda:
        "../envs/augur.yaml"
    shell:
        """
        augur mask \
            --mask {params.bed} \
            --sequence {input.alignment} \
            --output {output.sequences} > {log} 2>&1
        """


rule index:
    input:
        sequences=rules.mask.output.sequences,
    output:
        index=OUTDIR / "align" / "index.txt",
    threads: 1
    conda:
        "../envs/augur.yaml"
    shell:
        """
        augur index \
            --sequences {input.sequences} \
            --output {output.index} > {log} 2>&1
        """
