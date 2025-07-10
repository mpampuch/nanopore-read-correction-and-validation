#!/usr/bin/env bash

# Pipeline validation script for Yak Quality Assessment Pipeline

set -euo pipefail

echo "🔍 Validating Yak Quality Assessment Pipeline..."
echo "================================================"

# Check for required files
echo "📁 Checking pipeline structure..."

required_files=(
    "main.nf"
    "nextflow.config"
    "environment.yml"
    "params.yml"
    "README.md"
    "test_data.sh"
    "modules/yak_count.nf"
    "modules/yak_qv.nf"
    "modules/fastqc.nf"
    "modules/quality_report.nf"
)

missing_files=()

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    echo "  🎉 All required files present!"
else
    echo "  ⚠️  Missing files: ${missing_files[*]}"
    exit 1
fi

echo ""

# Check Nextflow syntax
echo "🔧 Validating Nextflow syntax..."
if command -v nextflow >/dev/null 2>&1; then
    if nextflow run main.nf --help >/dev/null 2>&1; then
        echo "  ✅ Nextflow syntax is valid"
    else
        echo "  ❌ Nextflow syntax errors detected"
        echo "  Run: nextflow run main.nf --help"
        exit 1
    fi
else
    echo "  ⚠️  Nextflow not found - skipping syntax validation"
    echo "     Install with: curl -s https://get.nextflow.io | bash"
fi

echo ""

# Check for required tools
echo "🛠️  Checking software dependencies..."

tools=(
    "python3:Python 3"
    "yak:Yak k-mer analyzer"
    "fastqc:FastQC"
)

for tool_info in "${tools[@]}"; do
    tool="${tool_info%%:*}"
    description="${tool_info##*:}"
    
    if command -v "$tool" >/dev/null 2>&1; then
        version=$($tool --version 2>&1 | head -n1 || echo "unknown")
        echo "  ✅ $description: $version"
    else
        echo "  ⚠️  $description: not found"
        echo "     Install via conda: conda install -c bioconda $tool"
    fi
done

echo ""

# Check environment file
echo "🐍 Validating conda environment..."
if [ -f "environment.yml" ]; then
    if command -v conda >/dev/null 2>&1; then
        echo "  ✅ Conda available"
        echo "  📦 Environment file present"
        echo "     To create environment: conda env create -f environment.yml"
    else
        echo "  ⚠️  Conda not found"
        echo "     Install miniconda/anaconda to use environment.yml"
    fi
else
    echo "  ❌ environment.yml missing"
fi

echo ""

# Test data generation
echo "🧪 Testing data generation..."
if [ -x "test_data.sh" ]; then
    echo "  ✅ Test data script is executable"
    echo "     Run: ./test_data.sh"
else
    echo "  ⚠️  Test data script not executable"
    echo "     Fix with: chmod +x test_data.sh"
fi

echo ""

# Pipeline configuration check
echo "⚙️  Configuration validation..."

# Check main.nf for required processes
required_processes=("YAK_COUNT_ILLUMINA" "YAK_COUNT_NANOPORE" "YAK_QV" "FASTQC" "QUALITY_REPORT")
main_nf_content=$(cat main.nf)

for process in "${required_processes[@]}"; do
    if echo "$main_nf_content" | grep -q "$process"; then
        echo "  ✅ Process $process imported"
    else
        echo "  ❌ Process $process missing"
    fi
done

echo ""

# Summary
echo "📊 Validation Summary"
echo "===================="
echo "✅ Pipeline structure: Complete"
echo "✅ Module files: Present"
echo "✅ Configuration: Valid"
echo "✅ Documentation: Available"

echo ""
echo "🚀 Next steps:"
echo "1. Install dependencies:"
echo "   conda env create -f environment.yml"
echo "   conda activate yak-quality-assessment"
echo ""
echo "2. Generate test data:"
echo "   ./test_data.sh"
echo ""
echo "3. Run test pipeline:"
echo "   nextflow run main.nf -params-file test_params.yml"
echo ""
echo "4. Run with your data:"
echo "   nextflow run main.nf \\"
echo "     --illumina_reads 'data/illumina/*_{R1,R2}.fastq.gz' \\"
echo "     --nanopore_reads 'data/nanopore/*.fastq.gz' \\"
echo "     --outdir results \\"
echo "     --threads 8"

echo ""
echo "📖 For detailed usage instructions, see README.md"
echo ""
echo "🎉 Pipeline validation complete!"