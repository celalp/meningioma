#! /bin/bash

DB=$1
PARAMS=$2

echo $DB
echo $PARAMS

mkdir -p analysis_logs

while true
do
	samples=$(psql -A -t -d $DB -w -c "select sampleid from samples_users.samples where status='queued for analysis'")
	if [ ${#samples} -eq 0 ]
	then
		sleep 10
	else
		for sample in $samples
		do
			Rscript analysis/analysis_pipeline.R -s $sample -y $PARAMS &>> analysis_logs/$sample.log
		done
	fi
done

