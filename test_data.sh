#!/usr/bin/env bash

# Script to generate test data for the Yak Quality Assessment Pipeline

set -euo pipefail

# Create test data directory structure
mkdir -p test_data/{illumina,nanopore}

echo "Generating test data for Yak Quality Assessment Pipeline..."

# Function to generate synthetic FASTQ data
generate_fastq() {
    local output_file="$1"
    local num_reads="$2"
    local read_length="$3"
    local quality_score="$4"
    
    echo "Generating $output_file with $num_reads reads of length $read_length..."
    
    # Generate synthetic DNA sequences and quality scores
    python3 -c "
import random
import gzip

bases = 'ATCG'
num_reads = $num_reads
read_length = $read_length
quality_char = chr($quality_score + 33)  # Phred+33 encoding

with gzip.open('$output_file', 'wt') as f:
    for i in range(num_reads):
        # Generate random DNA sequence
        sequence = ''.join(random.choice(bases) for _ in range(read_length))
        quality = quality_char * read_length
        
        # Write FASTQ record
        f.write(f'@read_{i+1}\n')
        f.write(f'{sequence}\n')
        f.write(f'+\n')
        f.write(f'{quality}\n')
"
}

# Generate Illumina paired-end reads (high quality, short reads)
echo "Creating Illumina test data..."
generate_fastq "test_data/illumina/sample1_R1.fastq.gz" 10000 150 35
generate_fastq "test_data/illumina/sample1_R2.fastq.gz" 10000 150 35

# Generate nanopore long reads (lower quality, long reads)
echo "Creating nanopore test data..."
generate_fastq "test_data/nanopore/sample1_nanopore.fastq.gz" 1000 5000 20

# Create a test parameters file
cat > test_params.yml << 'EOF'
# Test parameters for Yak Quality Assessment Pipeline

# Input data paths
illumina_reads: "test_data/illumina/*_{R1,R2}.fastq.gz"
nanopore_reads: "test_data/nanopore/*.fastq.gz"

# Output directory
outdir: "test_results"

# Reduced parameters for faster testing
threads: 2
kmer_size: 21
yak_bloomfilter_bits: 25

# Resource limits for testing
max_memory: "8.GB"
max_cpus: 4
max_time: "2.h"
EOF

echo ""
echo "Test data generation complete!"
echo ""
echo "Generated files:"
echo "  - test_data/illumina/sample1_R1.fastq.gz (10,000 reads, 150bp)"
echo "  - test_data/illumina/sample1_R2.fastq.gz (10,000 reads, 150bp)"
echo "  - test_data/nanopore/sample1_nanopore.fastq.gz (1,000 reads, 5kb)"
echo "  - test_params.yml (test configuration)"
echo ""
echo "To run the test:"
echo "  nextflow run main.nf -params-file test_params.yml"
echo ""
echo "Note: This is synthetic test data for pipeline validation only."