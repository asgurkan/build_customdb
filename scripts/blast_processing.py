#!/usr/bin/env python3
"""
filter_blast.py
---------------
Filter a tab‑separated BLAST outfmt 6 file, fetch organism titles for the
matching accessions via NCBI Entrez, and save the top N hits to CSV.

Required positional argument
----------------------------
blast_file            Path to BLAST results in outfmt 6

Optional arguments
------------------
--email EMAIL         Entrez contact e‑mail (required by NCBI)
--top N               Number of highest‑scoring rows to keep (default: 100)
--out FILE.csv        Output CSV filename (default: top_matches.csv)
"""
from __future__ import annotations
import argparse
import time
from typing import Dict, List

import pandas as pd
from Bio import Entrez


def get_organism_names(accessions: List[str], email: str) -> Dict[str, str]:
    """Return {accession: title} for a list of accessions via Entrez."""
    Entrez.email = email
    acc_to_name: Dict[str, str] = {}
    batch_size = 20
    for i in range(0, len(accessions), batch_size):
        batch = accessions[i : i + batch_size]
        try:
            handle = Entrez.esummary(db="nucleotide", id=batch, retmode="xml")
            records = Entrez.read(handle)
            for rec in records:
                acc_to_name[rec["AccessionVersion"]] = rec["Title"]
            time.sleep(0.34)  # stay polite to NCBI
        except Exception as exc:
            print(f"[ERROR] Failed batch {batch}: {exc}")
    return acc_to_name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Filter BLAST results and fetch organism names"
    )
    parser.add_argument("blast_file", help="BLAST outfmt 6 file (TSV)")
    parser.add_argument(
        "--email",
        required=True,
        help="Contact e‑mail for Entrez (required by NCBI’s usage policy)",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=100,
        metavar="N",
        help="Number of top‑scoring hits to keep (default: 100)",
    )
    parser.add_argument(
        "--out",
        default="top_matches.csv",
        metavar="FILE.csv",
        help="Output CSV filename (default: top_matches.csv)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    columns = [
        "qseqid",
        "sseqid",
        "pident",
        "qcovs",
        "length",
        "bitscore",
        "evalue",
        "staxids"
    ]
    df = pd.read_csv(args.blast_file, sep="\t", names=columns)

    # Basic filtering
    df = df.query("pident >= 90 and evalue == 0 and length >= 10000 and qcovs >=80")

    # Take top‑scoring rows
    df = df.sort_values("bitscore", ascending=False).head(args.top)

    # Retrieve organism titles
    unique_accessions = df["sseqid"].unique().tolist()
    acc_to_title = get_organism_names(unique_accessions, args.email)
    df["organism_name"] = df["sseqid"].map(acc_to_title)

    # Save
    df.to_csv(args.out, index=False)
    print(f"[DONE] Saved top {len(df)} matches to {args.out}")


if __name__ == "__main__":
    main()
