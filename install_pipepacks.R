install.packages("BiocManager", repos="https://cloud.r-project.org")

BiocManager::install(c("minfi", "conumee", "CopyNeutralIMA", "argparse", 
	"DBI", "RPostgreSQL", "yaml", "pandoc",
	"R.filesets", "limma", "RColorBrewer", 
	"devtools", "genefilter", "caret", "gbm", "rmarkdown", 
	"knitr", "dplyr", "kableExtra", "minfiData", "gplots"))

devtools::install_github("markgene/maxprobes")

devtools::install_version("hdnom", version = "5.0", repos = "http://cran.us.r-project.org", )
