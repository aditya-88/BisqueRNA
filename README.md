# BisqueRNA Pipeline #

## General information
This repository contains scripts used to prepare and deconvolve cell type proportions from several public bulk RNAseq datasets involving ALS.

## BisqueRNA.R
The main script written by Oscar Bedoya Reina to perform deconvolution of bulk RNAseq data based on a single cell RNAseq dataset. The package used to perform deconvolution here is BisqueRNA.

This script was modified by **Aditya Singh**

This modification converts the pipeline into a user software, not requiring any modification to the code.

To run the script two libraries are needed:
- BisqueRNA
- Biobase

These libraries are automatically installed by the software if not provided.

```bash
Usage: Rscript BisqueRNA.R bulk_counts_file single_cell_counts_file single_cell_clusters_labels_file [output_file]

bulk_counts_file: Path to the bulk counts file

single_cell_counts_file: Path to the single cell counts file

single_cell_clusters_labels_file: Path to the single cell clusters labels file

output_file: Path to the output file (Optional, will use the same folder and derived file name as the bulk counts file if not provided)
```

## Data files
Data used as input for deconvolution were extracted from the following repositories:
- https://github.com/NathanSkene/ALS_Human_EWCE
- https://github.com/NathanSkene/ALS_Mouse_EWCE

Single cell as well as bulk RNAseq data was extracted by running the scripts inside the repositories and perform additional filtering.  
For more details see the documentation:  
<i>Deconvolution of bulk RNAseq – PRJNA512012.docx</i> - Available upon request</i>
## Resources
The folder called resources contains several resources files used for correct conversion between Ensembl IDs and gene names. Also, it contains a file listing one-to-one orthologs between human and mouse.

## READOUT
Folder containing deconvolved cell proportions of bulk RNAseq data.

## Test_files
The folder called test_files contains pseudo-data to test the BisqueRNA script.

## Contact
For questions don't hesitate to send me a message at:
q.c.lin@students.uu.nl

For the modified code, feel free to open an issue on this GitHub repo.

*Aditya Singh*