# Yak Quality Assessment Pipeline

A Nextflow pipeline for assessing nanopore read quality compared to Illumina reads using k-mer analysis with [Yak](https://github.com/lh3/yak).

## Overview

This pipeline performs quality assessment of nanopore long-read sequencing data by comparing k-mer distributions against high-quality Illumina short-read references. It uses the yak tool to:

1. **Count k-mers** in both Illumina and nanopore datasets
2. **Calculate quality values (QV)** for nanopore reads using Illumina k-mers as reference
3. **Generate comprehensive quality reports** with visualizations and statistics
4. **Provide FastQC analysis** for basic sequence quality metrics

## Features

- 🧬 **K-mer Analysis**: Uses yak for efficient k-mer counting and quality assessment
- 📊 **Quality Metrics**: Calculates QV scores for accuracy estimation
- 📈 **Visual Reports**: Generates HTML reports with quality statistics
- 🔧 **Configurable**: Customizable k-mer size, thread count, and resource allocation
- 🐳 **Container Support**: Compatible with Docker, Singularity, and Conda
- ⚡ **Scalable**: Optimized for both local and cluster execution

## Requirements

### Software Dependencies

- [Nextflow](https://nextflow.io/) (≥21.0.0)
- [Yak](https://github.com/lh3/yak)
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- Python 3.9+

### Installation

#### Option 1: Conda Environment

```bash
# Create conda environment
conda env create -f environment.yml
conda activate yak-quality-assessment

# Install Nextflow if not available
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

#### Option 2: Container Execution

```bash
# Using Docker
nextflow run main.nf -profile docker

# Using Singularity
nextflow run main.nf -profile singularity
```

## Quick Start

1. **Clone the pipeline:**
   ```bash
   git clone <repository-url>
   cd yak-quality-assessment
   ```

2. **Prepare your data:**
   ```
   data/
   ├── illumina/
   │   ├── sample1_R1.fastq.gz
   │   ├── sample1_R2.fastq.gz
   │   └── ...
   └── nanopore/
       ├── sample1_nanopore.fastq.gz
       └── ...
   ```

3. **Run the pipeline:**
   ```bash
   nextflow run main.nf \
     --illumina_reads "data/illumina/*_{R1,R2}.fastq.gz" \
     --nanopore_reads "data/nanopore/*.fastq.gz" \
     --outdir results \
     --threads 8
   ```

## Usage

### Basic Command

```bash
nextflow run main.nf \
  --illumina_reads "path/to/illumina/*_{R1,R2}.fastq.gz" \
  --nanopore_reads "path/to/nanopore/*.fastq.gz" \
  --outdir results
```

### Advanced Configuration

```bash
nextflow run main.nf \
  --illumina_reads "data/illumina/*_{R1,R2}.fastq.gz" \
  --nanopore_reads "data/nanopore/*.fastq.gz" \
  --outdir results \
  --threads 16 \
  --kmer_size 31 \
  --yak_bloomfilter_bits 30 \
  -profile slurm
```

### Using Parameter File

```bash
# Edit params.yml with your settings
nextflow run main.nf -params-file params.yml
```

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--illumina_reads` | Path to Illumina paired-end reads (e.g., `"data/*_{R1,R2}.fastq.gz"`) |
| `--nanopore_reads` | Path to nanopore long reads (e.g., `"data/*.fastq.gz"`) |

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--outdir` | `results` | Output directory |
| `--threads` | `4` | Number of threads |
| `--kmer_size` | `37` | K-mer size for analysis |
| `--yak_bloomfilter_bits` | `37` | Bloom filter bits for yak |
| `--max_memory` | `32.GB` | Maximum memory allocation |
| `--max_cpus` | `16` | Maximum CPU cores |
| `--max_time` | `48.h` | Maximum runtime |

## Output Structure

```
results/
├── yak_illumina/           # Illumina k-mer databases
│   └── sample_illumina.yak
├── yak_nanopore/           # Nanopore k-mer databases  
│   └── sample_nanopore.yak
├── quality_values/         # QV analysis results
│   ├── sample_qv_results.qv
│   └── sample_qv_summary.txt
├── fastqc/                 # FastQC reports
│   ├── sample_R1_fastqc.html
│   └── sample_R2_fastqc.html
├── quality_report.html     # Comprehensive quality report
├── quality_summary.json    # Machine-readable summary
└── pipeline_info/          # Execution reports
    ├── execution_report.html
    ├── execution_timeline.html
    └── execution_trace.txt
```

## Quality Value Interpretation

The pipeline calculates Quality Values (QV) that indicate sequencing accuracy:

- **QV ≥ 30**: High quality (≥99.9% accuracy)
- **QV 20-30**: Good quality (99-99.9% accuracy)  
- **QV 10-20**: Moderate quality (90-99% accuracy)
- **QV < 10**: Low quality (<90% accuracy)

## Profiles

The pipeline supports multiple execution profiles:

- `local` (default): Local execution
- `slurm`: SLURM cluster execution
- `conda`: Use conda for dependencies
- `docker`: Use Docker containers
- `singularity`: Use Singularity containers

Example:
```bash
nextflow run main.nf -profile slurm,conda
```

## Configuration

### Resource Limits

Modify `nextflow.config` to adjust resource limits:

```groovy
params {
    max_memory = '64.GB'
    max_cpus = 32
    max_time = '72.h'
}
```

### Process-Specific Settings

Customize resource allocation for specific processes:

```groovy
process {
    withName: 'YAK_COUNT_ILLUMINA' {
        cpus = 16
        memory = '32.GB'
        time = '12.h'
    }
}
```

## Troubleshooting

### Common Issues

1. **Memory errors**: Increase `max_memory` or reduce `yak_bloomfilter_bits`
2. **Time limits**: Increase `max_time` for large datasets
3. **Missing dependencies**: Use `-profile conda` or `-profile docker`

### Getting Help

```bash
# Show help message
nextflow run main.nf --help

# Test pipeline with stub runs
nextflow run main.nf -stub
```

## Citation

If you use this pipeline, please cite:

- **Nextflow**: Di Tommaso, P. et al. Nextflow enables reproducible computational workflows. Nat Biotechnol 35, 316–319 (2017).
- **Yak**: Li, H. (2019). Yak: yet another k-mer analyzer. *Bioinformatics*.

## License

This pipeline is released under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

**Pipeline Version**: 1.0.0  
**Last Updated**: 2024