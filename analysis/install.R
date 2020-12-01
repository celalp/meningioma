#!/usr/bin/env Rscript
# Already in bioconductor/bioconductor_docker
# install.packages(c("BiocManager", "devtools", "dplyr", "knitr", "yaml"), repos="https://cloud.r-project.org")

# library(BiocManager)
# library(devtools)

withCallingHandlers(
  BiocManager::install(c(
    "argparse",
    "caret",
    "conumee",
    "CopyNeutralIMA",
  	"DBI",
    "gbm",
    "genefilter",
    "gplots",
    "kableExtra",
    "limma",
    "minfi",
    "minfiData",
    "R.filesets",
    "RColorBrewer",
    "rmarkdown",
    "RPostgreSQL"
  )),
  warning=stop
)
withCallingHandlers(
  devtools::install_github("markgene/maxprobes"),
  warning=stop
)
withCallingHandlers(
  devtools::install_version("hdnom", version="5.0", repos="http://cran.us.r-project.org"),
  warning=stop
)
