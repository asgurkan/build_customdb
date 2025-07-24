#!/bin/bash

###############################################################################
# build_blast_db.sh
# ------------------
# Download (reference-only or all) genomes for a given NCBI TaxID with the
# `datasets` CLI, build a concatenated FASTA file, and create a BLAST nucleotide
# database. Prompts the user whether to restrict the download to reference
# genomes.
###############################################################################

set -euo pipefail

# -------------------------- Logging helpers ----------------------------------
log_info()    { echo -e "\033[1;34m[INFO]\033[0m    $*"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m   $*" >&2; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }

# Abort cleanly on any error (prints the failing line number)
trap 'log_error "Script failed at line $LINENO. Exiting."; exit 1' ERR

# --------------------------- Input arguments ---------------------------------
TAXID="${1:-}"
DB_DIR="${2:-}"

if [[ -z "$TAXID" || -z "$DB_DIR" ]]; then
    log_error "Usage: $0 <taxid> <output_folder>"
    exit 1
fi

# Ask whether to restrict download to reference genomes -----------------------
read -r -p $'Download *only* reference/representative genomes? [y/N]: ' REF_CHOICE
REF_ARG=""
case "${REF_CHOICE:-n}" in
    [yY]|[yY][eE][sS])
        REF_ARG="--reference"
        log_info "User selected *reference-only* genomes."
        ;;
    *)
        log_info "User selected *all* available genomes."
        ;;
esac

# --------------------------- Path setup --------------------------------------
mkdir -p "$DB_DIR"
DB_DIR=$(realpath "$DB_DIR")

TEMP_DIR="$DB_DIR/temp_genomes"
FASTA_FILE="$DB_DIR/sequences.fasta"
BLAST_PREFIX="$DB_DIR/blastdb"

log_info "Taxonomic ID      : $TAXID"
log_info "Output directory  : $DB_DIR"
log_info "Temporary dir     : $TEMP_DIR"

mkdir -p "$TEMP_DIR"

# --------------------------- Workflow ----------------------------------------
# 1) Download dehydrated genome package (metadata only)
log_info "Downloading genome metadata (taxid=$TAXID)..."
datasets download genome taxon "$TAXID" \
    $REF_ARG \
    --dehydrated \
    --filename "$TEMP_DIR/genomes.zip"

# 2) Unzip metadata
log_info "Unzipping genome metadata..."
unzip -q "$TEMP_DIR/genomes.zip" -d "$TEMP_DIR"

# 3) Rehydrate (download the actual FASTA sequence files)
log_info "Rehydrating: downloading genome sequences..."
datasets rehydrate --directory "$TEMP_DIR"

# 4) Concatenate all .fna files into one FASTA
log_info "Combining FASTA files into: $FASTA_FILE"
find "$TEMP_DIR/ncbi_dataset/data" -name "*.fna" -exec cat {} + > "$FASTA_FILE"

# 5) Build BLAST nucleotide database
log_info "Creating BLAST database at prefix: $BLAST_PREFIX"
makeblastdb -in "$FASTA_FILE" -dbtype nucl -out "$BLAST_PREFIX"

# --------------------------- Finish ------------------------------------------
log_success "BLAST database created successfully!"
log_info    "Combined FASTA : $FASTA_FILE"
log_info    "BLAST DB prefix: $BLAST_PREFIX"
