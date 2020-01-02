# this is the complete analysis pipeline it takes command line arguments and database connections. 
# as the analysis runs database will be updated with results and progress
# in addition to all the packages will also need python to argparse


#TODO monitor RAM usage for the script. It is fishy that the package load takes so much time. 
message("loading packages")

suppressPackageStartupMessages(library(minfi))
suppressPackageStartupMessages(library(conumee))
suppressPackageStartupMessages(library(CopyNeutralIMA))
suppressPackageStartupMessages(library(argparse))
suppressPackageStartupMessages(library(R.filesets))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(RPostgreSQL))
suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(maxprobes))
suppressPackageStartupMessages(library(limma))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(genefilter))
suppressPackageStartupMessages(library(gplots))
suppressPackageStartupMessages(library(caret))
suppressPackageStartupMessages(library(gbm))
suppressPackageStartupMessages(library(hdnom))
suppressPackageStartupMessages(library(rmarkdown))

# will use command line parameters for the package
parser<-ArgumentParser()

parser$add_argument('-s', '--sampleid', action="store", help='sample id')
parser$add_argument('-y', '--yaml', action='store', help='config yaml file')

args<-parser$parse_args()

parameters<-yaml.load_file(args$yaml)




message("loading external data")

load(file = paste0(parameters$app_files$utils$extrenaldata,"/3objs_AUC88_MDA77_MRMRE9.5k_23K_Final.RData"))
load(file = paste0(parameters$app_files$utils$extrenaldata, "/coxregression.Rdata"))

conn<-dbConnect(drv = PostgreSQL(), parameters$database$host, 
                user=parameters$database$username, 
                password=parameters$database$password, 
                dbname=parameters$database$name, 
                port=parameters$database$port)

dbSendStatement(conn, "SET search_path = samples_users;")

# samples table columns are
# description
# samplename
# who_grade
# simpson_score
# sample_id
# status
# added

message("loading sample info")

sample_query<-"select * from samples_users.samples where sampleid=?id"
sample_query<-sqlInterpolate(conn, sample_query, id=args$sampleid)
sample_info<-dbGetQuery(conn, sample_query)
user_query<-"select username from users where userid=(select userid from samples_users_linked where sampleid=?id)"
user_query<-sqlInterpolate(conn, user_query, id=args$sampleid)
username<-dbGetQuery(conn, user_query)
basepath<-paste0(parameters$basepath, parameters$sample_files, unlist(username), "/", sample_info$samplename)
print(basepath)
message("starting analysis")

status<-"update samples_users.samples set status='Running' where sampleid=?id"
status<-sqlInterpolate(conn, status, id=args$sampleid)
dbSendStatement(conn, status)



message("loading sample files")

RGset<-try(
  read.metharray.exp(base = basepath, verbose = T)
)

if(class(RGset)!="try-error"){
  MsetEx1 <- preprocessIllumina(RGset) 
  prog_df<-data.frame(time=Sys.time(), message="Files loaded successfully", status="Proceed", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
} else {
  prog_df<-data.frame(time=Sys.time(), message="File read error", status="Fail", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
  status<-"update samples_users.samples set status='Error see analysis logs' where sampleid=?id"
  status<-sqlInterpolate(conn, status, id=args$sampleid)
  dbSendStatement(conn, status)
  stop("File read error")
}

ima <- annotation(MsetEx1)[['array']]
array_type <- ifelse(ima=="IlluminaHumanMethylationEPIC","EPIC","450k")

message("loading annotations")

if(array_type=="450k"){
  MsetCtrl <- loadRDS(paste0(parameters$app_files$utils$extrenaldata,"/", "450K_control.Rds"))
  library(IlluminaHumanMethylation450kmanifest)
  library(IlluminaHumanMethylation450kanno.ilmn12.hg19)
  load(file = paste0(parameters$app_files$utils$extrasample, "/", "450K_1ExtraSample_RGset.RData"))
  prog_df<-data.frame(time=Sys.time(), message=paste("Array type", array_type), status="Proceed", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
} else if (array_type=="EPIC"){
  MsetCtrl <- loadRDS(paste0(parameters$app_files$utils$extrenaldata, "/", "EPIC_control.Rds"))
  library(IlluminaHumanMethylationEPICmanifest)
  library("IlluminaHumanMethylationEPICanno.ilm10b4.hg19")
  load(file = paste0(parameters$app_files$utils$extrasample, "/", "EPIC_1ExtraSample_RGset.RData"))
  load(file = paste0(parameters$app_files$utils$extrasample, "/", "450K_1ExtraSample_RGset.RData"))
  prog_df<-data.frame(time=Sys.time(), message=paste("Array type", array_type), status="Proceed", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
} else {
  prog_df<-data.frame(time=Sys.time(), message=paste("Array type", array_type, "not valid"), status="Fail", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
  status<-"update samples_users.samples set status='Array Type Error, arrays must be either 450K or 850K' where sampleid=?id"
  status<-sqlInterpolate(conn, status, id=args$sampleid)
  dbSendStatement(conn, status)
  stop("Array type error, uploaded array is not 850K or 450K")
}


message("CNV analysis")

data(exclude_regions)
data(detail_regions)
anno <- CNV.create_anno(array_type = array_type, exclude_regions = exclude_regions, 
                        detail_regions = detail_regions)

Mset <- mapToGenome(MsetEx1)
anno@probes <- subsetByOverlaps(anno@probes, granges(Mset))
control.data <- CNV.load(MsetCtrl)
ex.data <- CNV.load(MsetEx1)
cnv <- CNV.fit(ex.data, control.data, anno)
cnv <- CNV.segment(CNV.detail(CNV.bin(cnv)))

results_path<-paste0(basepath, "/results")
dir.create(results_path, mode=0600)

#TODO think about reasosns this might fail
prog_df<-data.frame(time=Sys.time(), message="CNV analysis complete", status="Proceed", 
                    username=username, samplename=sample_info$samplename)
dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)


CNV.write(cnv, what = "segments", file = paste0(results_path,"/CNVsegments.seg"))
CNV.write(cnv, what = "bins", file = paste0(results_path,"/CNVbins.igv"))
CNV.write(cnv, what = "detail", file = paste0(results_path,"/CNVdetail.txt"))

png(file=paste0(results_path, "/CNV.png"),width=800,height=400,res=60)
CNV.genomeplot(cnv, main="Copy number variation profile")
dev.off()


message("sample QC")

Mset.noob <- preprocessNoob(RGset)

png(file = paste0(results_path,"/density_plot.png"), width = 720, height = 660, units = "px",res=100)
densityPlot(Mset.noob[,1], main="Quality control profile", legend=FALSE)
dev.off()



detP <- detectionP(RGset)
#TODO warn if colMeans(detP) > 0.05 in the report
qc_pval<-colMeans(detP)
status<-"update samples_users.samples set detection_p=?detp where sampleid=?id"
status<-sqlInterpolate(conn, status, id=args$sampleid, detp=qc_pval)
dbSendStatement(conn, status)


idx1 = row.names(RGset)[which(row.names(RGset) %in% row.names(RGset1))]
RGset <- cbind(RGset[idx1,],RGset1[idx1,])



prog_df<-data.frame(time=Sys.time(), message="QC complete", status="Proceed", 
                    username=username, samplename=sample_info$samplename)
dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)

Mset.noobFlt <- Mset.noob[,1] 

message("methylation probablility")

Rset = ratioConvert(Mset.noobFlt, what = "both", keepCN=T)
GRset <- mapToGenome(Rset)
RSetSNP <- addSnpInfo(GRset)
beta_value = getBeta(RSetSNP)
newDF <- t(beta_value[rownames(beta_value) %in% predictorNames,]) 

gbm_new <- predict(objGBM, newDF, type='prob')[,2]
metp <- 1-gbm_new

status<-"update samples_users.samples set methylome_prob=?met_p where sampleid=?id"
status<-sqlInterpolate(conn, status, id=args$sampleid, met_p=metp)
dbSendStatement(conn, status)
prog_df<-data.frame(time=Sys.time(), message="methylome prediction complete", status="Proceed", 
                    username=username, samplename=sample_info$samplename)
dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)

if(sample_info$who_grade!="NA" & sample_info$simpson_score!="NA"){
  message("recurrence probability")
  newx<-matrix(c(as.numeric(sample_info$who_grade), as.numeric(sample_info$simpson_score), metp), nrow=1)
  colnames(newx)<-hdnom.varinfo(hdnom_model, x)$name
  recurrence_p<-predict(hdnom_model, as.matrix(x), as.matrix(y), newx, 5)[1]
  prog_df<-data.frame(time=Sys.time(), message="recurrence prediction complete", status="Done", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
} else {
  message("no simpson or who score stopping")
  prog_df<-data.frame(time=Sys.time(), message="No who or simpson score stopping!", status="Done", 
                      username=username, samplename=sample_info$samplename)
  dbWriteTable(conn, "analysis", prog_df, append=T, row.names=F)
  recurrence_p<-NA
}

file.copy("sample_report.Rmd", paste0(results_path, "/sample_report.Rmd"), overwrite = T)
render(input = paste0(results_path, "/sample_report.Rmd"), output_file = "report.pdf")

status<-"update samples_users.samples set recurrence_prob=?rec_p, status=?stat where sampleid=?id"
status<-sqlInterpolate(conn, status, id=args$sampleid, rec_p=recurrence_p, stat="Done")
dbSendStatement(conn, status)

message("Done")