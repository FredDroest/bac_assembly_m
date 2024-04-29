#!/bin/bash

#INPUT-Parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) input="$2"; shift ;;
        -o|--output) outputpath="$2"; shift ;;
        -g|--genome-size) genomesize="$2"; shift ;;
        -c|--coverage) coverage="$2"; shift ;;
        -t|--trim-length) trimlen="$2"; shift ;;
        -q|--qualityscore) qualityscore="$2"; shift ;;
        -k|--kingdom) kingdom="$2"; shift;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "_________________"
echo "Pipeline start"

#set default values for flye-run (also passed to script by generate_assembly.sh)
if [ -z "$coverage" ]; then
  coverage="50"
fi
if [ -z "$genomesize" ]; then
  genomesize="5m"
fi
if [ -z "$trimlen" ]; then
  trimlen="100"
fi
if [ -z "$qualityscore" ]; then
  qualityscore="12"
fi
if [ -z "$kingdom" ]; then
  kingdom="Bacteria"
fi

echo "INPUT-VALUES:"
echo "IN-Folder: $input"
echo "OUT-Folder: $outputpath"
echo "genomesize: $genomesize"
echo "kingdom: $kingdom"

#INPUT-Variables
in_name="$(basename -- "$input")"
filename="${in_name%%.*}"

echo "in_name: $in_name"


if [ ! -d "$outputpath" ]; then
  echo "WARNING: $outputpath does not exist, directory will be created"
  echo "creating path $outputpath"
  mkdir -p $outputpath
  else echo "output-path OK"
fi

findfastq=$(find . -type f -name "*_assemble.fastq.gz")

echo "FASTQ: $findfastq"


echo "#################"
echo "unzipping and NanoFilt-ering"
$(gunzip -c "$findfastq" | NanoFilt --logfile $outputpath/$in_name"_trimming.log" -q $qualityscore -l $trimlen > $outputpath/$filename"_trimmed_q_"$qualityscore"_l_"$trimlen".fastq")
echo "#################"
echo "Running Flye-assembly"
# $(flye --nano-raw $outputpath/$filename"_trimmed_q_"$qualityscore"_l_"$trimlen".fastq" --out-dir $outputpath"/flye_assembly" --threads 20 --asm-coverage $coverage --iterations 2)
$(flye --nano-raw $outputpath/$filename"_trimmed_q_"$qualityscore"_l_"$trimlen".fastq" --out-dir $outputpath"/flye_assembly" --threads 20 --asm-coverage $coverage --iterations 3 --genome-size $genomesize)
echo "#################"
# echo "running medaka"
# change model after new basecalling to r941_min_sup_g507
# $(medaka_consensus -d $outputpath"/flye_assembly/assembly.fasta" -i $outputpath/$in_name"_trimmed_q_"$qualityscore"_l_"$trimlen".fastq" -o $outputpath"/flye_medaka" -t 2 -m r941_min_hac_g507 )
echo "#################"
if [ -f "$outputpath""/flye_medaka/consensus.fasta" ]; then
  #$(bowtie2-build $outputpath"/flye_medaka/consensus.fasta")
  echo "Running minimap(on medaka consensus)"
  $(minimap2 -ax map-ont $outputpath"/flye_medaka/consensus.fasta" $outputpath/$filename"_trimmed_q_"$qualityscore"_l_"$trimlen".fastq" --secondary=no | samtools view -bS | samtools sort > $outputpath/"ONT_trimmed_q_"$qualityscore"_l_"$trimlen"_to_assembly.bam"; samtools index $outputpath"/ONT_trimmed_q_"$qualityscore"_l_"$trimlen"_to_assembly.bam")
  echo "#################"
  echo "Running Prokka (on medaka consensus)"
  $(prokka $outputpath"/flye_medaka/consensus.fasta" --outdir $outputpath"/prokka_annotation" --kingdom $kingdom --cpu 4 --prefix "PROKKA" --force)
  else
    echo "Running minimap(on flye assembly)"
    $(minimap2 -ax map-ont $outputpath"/flye_assembly/assembly.fasta" $outputpath/$in_name"_trimmed_q_"$qualityscore"_l_"$trimlen".fastq" --secondary=no | samtools view -bS | samtools sort > $outputpath/"ONT_trimmed_q_"$qualityscore"_l_"$trimlen"_to_assembly.bam"; samtools index $outputpath"/ONT_trimmed_q_"$qualityscore"_l_"$trimlen"_to_assembly.bam")
    echo "#################"
    echo "Running Prokka (on flye assembly)"
    $(prokka $outputpath"/flye_assembly/assembly.fasta" --outdir $outputpath"/prokka_annotation" --kingdom $kingdom --prefix "PROKKA" --force)
    $(mv $outputpath"/prokka_annotation/PROKKA.log" $outputpath"/prokka_annotation/PROKKA.txt")
fi

# pharokkainstall=$(mamba list pharokka | wc -l)
# pharokkadbs=list=$(find ./pharokka -type d -iname "pharokkadb")
# if [ "$pharokkainstall" -gt 3 ] && [ "$kingdom" == "Virus" ]; then
#   $(pharokka.py -i $outputpath"/flye_assembly/assembly.fasta" -o $outputpath"/pharokka_annotation" -d $pharokkadbs)
# fi
loglist=$(find $outputpath -type f -name "*.log")
for logfile in $loglist; do
$(mv $logfile "$logfile.txt")
done
echo "#################"
echo "Pipeline end"
echo "_________________"
