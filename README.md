# Ceph IOPS Performance Testing Script

A comprehensive Ceph storage performance testing script that measures IOPS and throughput across different storage pools and generates detailed reports for analysis.

## Overview

This script performs thorough performance testing on Ceph storage clusters by testing individual pools, OSDs, and RBD devices. All results are automatically saved to timestamped directories for historical comparison and analysis.

## Features

- **Pool Performance Testing**: Tests all configured Ceph pools using `rados bench`
- **OSD-Level Testing**: Individual OSD performance analysis
- **RBD Direct Testing**: Tests RBD devices using `fio` with librbd engine
- **Automated Reporting**: Generates summary reports and detailed logs
- **Historical Data**: Timestamped output directories for trend analysis
- **Multiple Output Formats**: Text logs, CSV data, and JSON results

## Prerequisites

### Required Packages
```bash
# Debian/Ubuntu/Proxmox
apt update
apt install fio

# RHEL/CentOS
yum install fio
```

### Required Permissions
- Root or sudo access
- Ceph admin keyring access
- Write permissions to `/tmp/` directory

### Ceph Cluster Requirements
- Healthy Ceph cluster with accessible pools
- Sufficient free space for test data (script creates temporary 5GB RBD images)
- Network connectivity between cluster nodes

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd ceph-performance-testing
```

2. Make the script executable:
```bash
chmod +x ceph_iops_test.sh
```

3. Verify Ceph cluster access:
```bash
ceph -s
```

## Usage

### Basic Usage
```bash
sudo ./ceph_iops_test.sh
```

### Example Output
```
=== Ceph IOPS Testing Suite ===
Results will be saved to: /tmp/ceph_iops_test_20250706_143022

1. Testing pools with rados bench...
Testing pool: fast-storage-pool
Testing pool: big-rust
Testing pool: media

2. Testing fast-storage OSDs...
Testing OSD.0:
Testing OSD.1:
Testing OSD.2:
Testing OSD.3:

3. Creating test RBD image...
4. Testing RBD with fio...
5. Cleaning up test image...
6. Generating summary report...

=== IOPS Testing Complete ===
All results saved to: /tmp/ceph_iops_test_20250706_143022
```

## Output Files

The script generates a timestamped directory containing:

| File | Description |
|------|-------------|
| `performance_summary.txt` | High-level performance summary and key metrics |
| `system_info.txt` | Cluster status, OSD tree, and system information |
| `rados_bench_<pool>.txt` | Detailed rados bench results for each pool |
| `rbd_fio_results.txt` | FIO test results for RBD performance |
| `osd_bench_results.txt` | Individual OSD benchmark results |

### Sample Output Structure
```
/tmp/ceph_iops_test_20250706_143022/
├── performance_summary.txt
├── system_info.txt
├── rados_bench_fast-storage-pool.txt
├── rados_bench_big-rust.txt
├── rados_bench_media.txt
├── rbd_fio_results.txt
└── osd_bench_results.txt
```

## Performance Metrics

### Measured Parameters
- **IOPS**: Input/Output Operations Per Second
- **Bandwidth**: Throughput in MB/s
- **Latency**: Average, minimum, and maximum response times
- **Queue Depth**: I/O queue depth performance
- **Read/Write Mix**: Performance under different workload patterns

### Test Types
1. **Sequential Write**: Large block sequential writes to measure throughput
2. **Random Read**: 4K random reads to measure IOPS capability
3. **Random Write**: 4K random writes to measure write IOPS
4. **Mixed Workload**: 70% read, 30% write mixed operations

## Configuration

### Customizing Test Parameters

Edit the script to modify test parameters:

```bash
# Test duration (seconds)
RUNTIME=30

# Block size for random I/O tests
BLOCKSIZE=4k

# Queue depth for FIO tests
IODEPTH=16

# Number of parallel jobs
NUMJOBS=2
```

### Pool Selection

Modify the pool list to match your environment:

```bash
# Edit this line in the script
for pool in your-pool1 your-pool2 your-pool3; do
```

### OSD Selection

Update OSD numbers to match your fast storage OSDs:

```bash
# Edit this line for your fast storage OSDs
for osd in 0 1 2 3; do
```

## Performance Baselines

### Expected Performance (Hardware Dependent)

| Storage Type | Random Read IOPS | Random Write IOPS | Sequential MB/s |
|--------------|------------------|-------------------|-----------------|
| NVMe SSD | 10,000-50,000+ | 5,000-30,000+ | 500-3,000+ |
| SATA SSD | 5,000-15,000 | 3,000-10,000 | 200-500 |
| 7200 RPM HDD | 100-300 | 100-300 | 100-200 |
| 5400 RPM HDD | 75-150 | 75-150 | 80-120 |

### Network Considerations
- 1Gbps network: ~125MB/s theoretical maximum
- 2.5Gbps network: ~312MB/s theoretical maximum
- 10Gbps network: ~1,250MB/s theoretical maximum

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   sudo ./ceph_iops_test.sh
   ```

2. **FIO Not Found**
   ```bash
   apt install fio  # Debian/Ubuntu
   yum install fio  # RHEL/CentOS
   ```

3. **Pool Not Found**
   ```bash
   ceph osd pool ls  # List available pools
   # Update script with correct pool names
   ```

4. **Low Performance**
   - Check cluster health: `ceph health detail`
   - Monitor during test: `watch ceph -s`
   - Check network connectivity between nodes
   - Verify OSD performance: `ceph osd perf`

### Monitoring During Tests

Run in separate terminal to monitor cluster during testing:

```bash
# Monitor cluster status
watch -n 2 'ceph -s'

# Monitor OSD performance
watch -n 2 'ceph osd perf'

# Monitor pool usage
watch -n 2 'ceph df detail'
```

## Safety Considerations

### Test Impact
- Tests create temporary load on storage cluster
- May impact production workloads during testing
- Uses cluster bandwidth and IOPS capacity
- Creates temporary 5GB test images (automatically cleaned up)

### Best Practices
- Run during maintenance windows for production clusters
- Monitor cluster health before and during tests
- Ensure adequate free space (>10GB) in test pools
- Test during low-activity periods

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and add tests
4. Commit your changes: `git commit -am 'Add feature'`
5. Push to the branch: `git push origin feature-name`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Open an issue on Github
- Check Ceph documentation: https://docs.ceph.com/
- Proxmox Ceph guide: https://pve.proxmox.com/wiki/Ceph_Server

## Changelog

### v1.0.0
- Initial release with basic pool and OSD testing
- Automated report generation
- RBD performance testing with FIO

### v1.1.0 (Planned)
- CSV export functionality
- JSON output format
- Historical performance comparison
- Automated baseline detection
