#!/usr/bin/env Rscript

# Already in bioconductor/bioconductor_docker
# install.packages(c("BiocManager", "devtools", "dplyr", "knitr", "yaml"), repos="https://cloud.r-project.org")

# Already in rocker/verse
# "BiocManager", "DBI", "devtools", "dplyr", "knitr", "RColorBrewer", "rmarkdown", "yaml"


options(timeout=5000)

withCallingHandlers(
  BiocManager::install(c(
    "argparse",
    "caret",
    "conumee",
    "CopyNeutralIMA",
    "gbm",
    "genefilter",
    "gplots",
    "kableExtra",
    "limma",
    "minfi",
    "minfiData",
    "R.filesets",
    "RPostgreSQL",
    "IlluminaHumanMethylation450kmanifest",
    "IlluminaHumanMethylation450kanno.ilmn12.hg19",
    "IlluminaHumanMethylationEPICmanifest",
    "IlluminaHumanMethylationEPICanno.ilm10b4.hg19"
  )),
  warning=stop
)
withCallingHandlers(
  devtools::install_github("markgene/maxprobes"),
  warning=stop
)
withCallingHandlers(
  devtools::install_version("hdnom", version="5.0"),
  warning=stop
)
