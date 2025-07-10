process QUALITY_REPORT {
    label 'process_low'
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path illumina_yak_files
    path nanopore_yak_files
    path qv_files
    path fastqc_files

    output:
    path "quality_report.html", emit: report
    path "quality_summary.json", emit: summary
    path "versions.yml", emit: versions

    script:
    """
    #!/usr/bin/env python3

    import json
    import os
    import glob
    from datetime import datetime
    import re

    def parse_qv_summary(file_path):
        '''Parse QV summary file and extract statistics'''
        stats = {}
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                
            # Extract sample name
            sample_match = re.search(r'Sample: (.+)', content)
            if sample_match:
                stats['sample'] = sample_match.group(1)
            
            # Extract QV statistics
            mean_match = re.search(r'Mean QV: ([0-9.]+)', content)
            min_match = re.search(r'Min QV: ([0-9.]+)', content)
            max_match = re.search(r'Max QV: ([0-9.]+)', content)
            reads_match = re.search(r'Total reads analyzed: ([0-9]+)', content)
            
            if mean_match:
                stats['mean_qv'] = float(mean_match.group(1))
            if min_match:
                stats['min_qv'] = float(min_match.group(1))
            if max_match:
                stats['max_qv'] = float(max_match.group(1))
            if reads_match:
                stats['total_reads'] = int(reads_match.group(1))
                
        except Exception as e:
            print(f"Error parsing {file_path}: {e}")
            
        return stats

    def generate_html_report(qv_stats, illumina_files, nanopore_files, fastqc_files):
        '''Generate HTML quality report'''
        
        html_content = f'''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Yak Quality Assessment Report</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                margin: 40px;
                background-color: #f5f5f5;
            }}
            .container {{
                max-width: 1200px;
                margin: 0 auto;
                background-color: white;
                padding: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }}
            h1 {{
                color: #2c3e50;
                border-bottom: 3px solid #3498db;
                padding-bottom: 10px;
            }}
            h2 {{
                color: #34495e;
                border-left: 4px solid #3498db;
                padding-left: 15px;
                margin-top: 30px;
            }}
            .stats-grid {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin: 20px 0;
            }}
            .stats-card {{
                background-color: #ecf0f1;
                padding: 20px;
                border-radius: 6px;
                border-left: 4px solid #3498db;
            }}
            .stats-card h3 {{
                margin: 0 0 10px 0;
                color: #2c3e50;
            }}
            .metric {{
                display: flex;
                justify-content: space-between;
                margin: 8px 0;
            }}
            .metric-value {{
                font-weight: bold;
                color: #27ae60;
            }}
            .file-list {{
                background-color: #f8f9fa;
                padding: 15px;
                border-radius: 4px;
                margin: 10px 0;
            }}
            .file-list ul {{
                margin: 0;
                padding-left: 20px;
            }}
            .timestamp {{
                color: #7f8c8d;
                font-style: italic;
                text-align: right;
                margin-top: 30px;
            }}
            .quality-interpretation {{
                background-color: #e8f5e8;
                border: 1px solid #4caf50;
                border-radius: 4px;
                padding: 15px;
                margin: 15px 0;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>📊 Yak Quality Assessment Report</h1>
            
            <div class="quality-interpretation">
                <h3>🔬 Analysis Overview</h3>
                <p>This report compares nanopore long-read sequencing quality against Illumina short-read references using k-mer analysis with Yak.</p>
                <p><strong>Quality Value (QV) Interpretation:</strong></p>
                <ul>
                    <li>QV ≥ 30: High quality (≥99.9% accuracy)</li>
                    <li>QV 20-30: Good quality (99-99.9% accuracy)</li>
                    <li>QV 10-20: Moderate quality (90-99% accuracy)</li>
                    <li>QV < 10: Low quality (<90% accuracy)</li>
                </ul>
            </div>

            <h2>📈 Quality Value Statistics</h2>
            <div class="stats-grid">
    '''
        
        # Add QV statistics for each sample
        for sample_stats in qv_stats:
            if 'sample' in sample_stats:
                html_content += f'''
                <div class="stats-card">
                    <h3>Sample: {sample_stats.get('sample', 'Unknown')}</h3>
                    <div class="metric">
                        <span>Mean QV:</span>
                        <span class="metric-value">{sample_stats.get('mean_qv', 'N/A')}</span>
                    </div>
                    <div class="metric">
                        <span>Min QV:</span>
                        <span class="metric-value">{sample_stats.get('min_qv', 'N/A')}</span>
                    </div>
                    <div class="metric">
                        <span>Max QV:</span>
                        <span class="metric-value">{sample_stats.get('max_qv', 'N/A')}</span>
                    </div>
                    <div class="metric">
                        <span>Reads Analyzed:</span>
                        <span class="metric-value">{sample_stats.get('total_reads', 'N/A'):,}</span>
                    </div>
                </div>
                '''
        
        html_content += f'''
            </div>

            <h2>📁 Analysis Files</h2>
            
            <h3>🧬 Illumina K-mer Databases</h3>
            <div class="file-list">
                <ul>
    '''
        
        for file in illumina_files:
            html_content += f'<li>{os.path.basename(file)}</li>'
        
        html_content += f'''
                </ul>
            </div>
            
            <h3>🔬 Nanopore K-mer Databases</h3>
            <div class="file-list">
                <ul>
    '''
        
        for file in nanopore_files:
            html_content += f'<li>{os.path.basename(file)}</li>'
        
        html_content += f'''
                </ul>
            </div>
            
            <h3>📊 FastQC Reports</h3>
            <div class="file-list">
                <ul>
    '''
        
        for file in fastqc_files:
            if file.endswith('.html'):
                html_content += f'<li><a href="fastqc/{os.path.basename(file)}" target="_blank">{os.path.basename(file)}</a></li>'
        
        html_content += f'''
                </ul>
            </div>
            
            <div class="timestamp">
                Report generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            </div>
        </div>
    </body>
    </html>
        '''
        
        return html_content

    # Main execution
    try:
        # Parse QV summary files
        qv_summary_files = glob.glob('*_qv_summary.txt')
        qv_stats = []
        
        for qv_file in qv_summary_files:
            stats = parse_qv_summary(qv_file)
            if stats:
                qv_stats.append(stats)
        
        # Get file lists
        illumina_files = [f for f in glob.glob('*.yak') if 'illumina' in f]
        nanopore_files = [f for f in glob.glob('*.yak') if 'nanopore' in f]
        fastqc_files = glob.glob('*.html') + glob.glob('*.zip')
        
        # Generate HTML report
        html_report = generate_html_report(qv_stats, illumina_files, nanopore_files, fastqc_files)
        
        with open('quality_report.html', 'w') as f:
            f.write(html_report)
        
        # Generate JSON summary
        summary_data = {
            'analysis_date': datetime.now().isoformat(),
            'pipeline_version': '1.0.0',
            'parameters': {
                'kmer_size': ${params.kmer_size},
                'bloom_filter_bits': ${params.yak_bloomfilter_bits}
            },
            'samples': qv_stats,
            'file_counts': {
                'illumina_databases': len(illumina_files),
                'nanopore_databases': len(nanopore_files),
                'fastqc_reports': len([f for f in fastqc_files if f.endswith('.html')])
            }
        }
        
        with open('quality_summary.json', 'w') as f:
            json.dump(summary_data, f, indent=2)
            
        print("Quality report generated successfully!")
        
    except Exception as e:
        print(f"Error generating quality report: {e}")
        # Create minimal fallback report
        with open('quality_report.html', 'w') as f:
            f.write(f'<html><body><h1>Quality Report Generation Failed</h1><p>Error: {e}</p></body></html>')
        
        with open('quality_summary.json', 'w') as f:
            json.dump({'error': str(e)}, f)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    touch quality_report.html
    touch quality_summary.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
    END_VERSIONS
    """
}