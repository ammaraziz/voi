"""
Snakefile for cleaning and aligning msa
"""


rule align:
    input:
        sequences=rules.collate.output.sequences,
        reference=config["align"]["reference"],
    output:
        alignment=OUTDIR / "align" / "all.fasta",
    log:
        OUTDIR / "logs" / "align.txt",
    conda:
        "../envs/augur.yaml"
    threads: 20
    message:
        """
    Aligning sequences to {input.reference}
        - filling gaps with N
        """
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
    input:
        alignment=rules.align.output.alignment,
    output:
        sequences=OUTDIR / "align" / "masked.fasta",
    log:
        OUTDIR / "logs" / "mask.txt",
    conda:
        "../envs/augur.yaml"
    threads: 1
    params:
        bed=config["mask"]["utr"],
    message:
        """
        Mask start and end of alignments
        """
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
    conda:
        "../envs/augur.yaml"
    threads: 1
    shell:
        """
        augur index \
            --sequences {input.sequences} \
            --output {output.index} > {log} 2>&1
        """
