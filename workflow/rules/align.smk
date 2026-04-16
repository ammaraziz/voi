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


if not config["mask_utr"]["skip"]:

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
            bed=config["mask_utr"]["file"],
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

else:

    rule mask:
        input:
            alignment=rules.align.output.alignment,
        output:
            sequences=OUTDIR / "align" / "masked.fasta",
        log:
            OUTDIR / "logs" / "mask.txt",
        threads: 1
        message:
            """
            Skipping Masking
            """
        shell:
            """
            cp {input.alignment} {output.sequences}
            """
