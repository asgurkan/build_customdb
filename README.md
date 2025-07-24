# Build Custom Taxonomic BLAST Database

A lightweight workflow for downloading taxon‑specific genomes from NCBI, building a nucleotide BLAST database, and summarising BLAST hits.

---

## Prerequisites

| Requirement                 | Version / Notes                                                                               |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| **Conda**                   | Anaconda ≥ 23 or Miniconda ≥ 23                                                               |
| **`build_db` environment**  | Install from the provided `environment.yml`, then activate with:<br>`conda activate build_db` |
| **NCBI command‑line tools** | Installed automatically from the environment (`ncbi‑datasets-cli`, `entrez‑direct`, `blast`)  |

> **Activate first**
>
> ```bash
> conda activate build_db
> ```

---

##  Quick‑start

### 1 · Build the taxon database

```bash
./build_tax_db.sh <TAXON_ID> <OUTPUT_FOLDER>

# Example: build a *Toxoplasma gondii* database
./build_tax_db.sh 5810 toxoplasma_db
```

The script will:

1. Download reference **or** all genomes for the TaxID (you’ll be asked).
2. Rehydrate them and concatenate the FASTA files.
3. Build a BLAST nucleotide database in `<OUTPUT_FOLDER>/blastdb`.

---

### 2 · Run BLAST against the new DB

```bash
blastn \
  -query /path/to/assembly.fasta \
  -db    /path/to/<OUTPUT_FOLDER>/blastdb \
  -num_threads 24 \
  -outfmt '6 qseqid sseqid pident qcovs length bitscore evalue' \
  -culling_limit 1 \
  -out   sample_blast_results.txt
```

Change `-num_threads` and file paths as needed.

---

### 3 · Post‑process the BLAST output

```bash
./blast_processing.py \
  --email you@example.com \
  --top   100 \
  --out   top100_matches.csv \
  sample_blast_results.txt
```

`blast_processing.py` will 

* filter hits (≥ 90 % identity, e‑value = 0, length ≥ 10 kb and qcovs >=80),
* keep the **top N** by bitscore,
* fetch organism titles via Entrez, and
* write a tidy CSV.

---

## Generated files

| File / Folder                     | Purpose                                        |
| --------------------------------- | ---------------------------------------------- |
| `<OUTPUT_FOLDER>/temp_genomes/`   | Raw genomes + metadata downloaded from NCBI    |
| `<OUTPUT_FOLDER>/sequences.fasta` | Concatenated FASTA of all genomes              |
| `<OUTPUT_FOLDER>/blastdb/`        | BLAST DB (`*.nsq`, `*.nhr`, `*.nin` …)         |
| `top100_matches.csv`              | Summary of best BLAST hits with organism names |

---

## Author

* **Ahmet Serkan Gurkan** – [asgurkan@github.com](mailto:asgurkan@github.com)
