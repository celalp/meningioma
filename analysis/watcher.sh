#! /bin/bash

PARAMS=$1

mkdir -p analysis_logs
cd analysis

Rscript analysis_pipeline.R -y $PARAMS 

