Before starting, please activate "build_db" environment.

1. Run "build_tax_db.sh" with a taxon ID and a DB folder name. 
./build_tax_db.sh 5810 toxoplasma_db

2. Then run the blastn rule, example:  
blastn   -query /home/massbiome/Desktop/11_04_2025_TOXO_LEISHMANIA/assembly/barcode23/assembly.fasta   -db /home/massbiome/Desktop/Samet/scripts/build_db/leishmania_db/blastdb   -num_threads 24   -outfmt '6 qseqid sseqid pident qcovs length bitscore evalue' -out leishmania_blast_results.txt   -culling_limit 1

3. Run "blast_processing.py" script to get top n matches and organism names. 
./blast_processingv2.py --email gurkan19@itu.edu.tr --top 100 --out top100_matches.csv leishmania_blast_results.txt 
