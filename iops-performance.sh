#!/bin/bash

# Create output directory with timestamp
timestamp=$(date '+%Y%m%d_%H%M%S')
output_dir="/tmp/ceph_iops_test_$timestamp"
mkdir -p "$output_dir"

echo "=== Ceph IOPS Testing Suite ==="
echo "Results will be saved to: $output_dir"

# System info
echo "=== System Information ===" > "$output_dir/system_info.txt"
date >> "$output_dir/system_info.txt"
hostname >> "$output_dir/system_info.txt"
ceph -s >> "$output_dir/system_info.txt"
ceph osd tree >> "$output_dir/system_info.txt"
ceph osd df >> "$output_dir/system_info.txt"

# Test pools with rados bench
echo "1. Testing pools with rados bench..."
for pool in fast-storage-pool big-rust media; do
    echo "Testing pool: $pool"
    pool_file="$output_dir/rados_bench_${pool}.txt"
    
    echo "=== Rados Bench Results for Pool: $pool ===" > "$pool_file"
    echo "Date: $(date)" >> "$pool_file"
    echo "" >> "$pool_file"
    
    echo "Write test (30s):" | tee -a "$pool_file"
    rados bench -p $pool 30 write --no-cleanup 2>&1 | tee -a "$pool_file"
    
    echo "" >> "$pool_file"
    echo "Random read test (30s):" | tee -a "$pool_file"
    rados bench -p $pool 30 rand 2>&1 | tee -a "$pool_file"
    
    echo "Cleaning up..." | tee -a "$pool_file"
    rados -p $pool cleanup 2>&1 | tee -a "$pool_file"
    echo "---"
done

# Test individual fast-storage OSDs
echo "2. Testing fast-storage OSDs..."
osd_file="$output_dir/osd_bench_results.txt"
echo "=== OSD Bench Results ===" > "$osd_file"
echo "Date: $(date)" >> "$osd_file"
echo "" >> "$osd_file"

for osd in 0 1 2 3; do
    echo "Testing OSD.$osd:" | tee -a "$osd_file"
    ceph tell osd.$osd bench 2>&1 | tee -a "$osd_file"
    echo "---" >> "$osd_file"
done

# Create RBD for direct testing
echo "3. Creating test RBD image..."
rbd create iops-test --size 5G --pool fast-storage-pool

echo "4. Testing RBD with fio..."
rbd_file="$output_dir/rbd_fio_results.txt"
echo "=== RBD FIO Test Results ===" > "$rbd_file"
echo "Date: $(date)" >> "$rbd_file"
echo "Test: Random Read 4K, 16 depth, 2 jobs, 30s" >> "$rbd_file"
echo "" >> "$rbd_file"

fio --name=rbd-random-read \
    --ioengine=rbd \
    --pool=fast-storage-pool \
    --rbdname=iops-test \
    --direct=1 \
    --rw=randread \
    --bs=4k \
    --iodepth=16 \
    --numjobs=2 \
    --runtime=30 \
    --group_reporting \
    --output-format=normal \
    2>&1 | tee -a "$rbd_file"

# Test random write
echo "" >> "$rbd_file"
echo "Test: Random Write 4K, 16 depth, 2 jobs, 30s" >> "$rbd_file"
fio --name=rbd-random-write \
    --ioengine=rbd \
    --pool=fast-storage-pool \
    --rbdname=iops-test \
    --direct=1 \
    --rw=randwrite \
    --bs=4k \
    --iodepth=16 \
    --numjobs=2 \
    --runtime=30 \
    --group_reporting \
    --output-format=normal \
    2>&1 | tee -a "$rbd_file"

# Cleanup
echo "5. Cleaning up test image..."
rbd rm iops-test --pool fast-storage-pool

# Generate summary report
echo "6. Generating summary report..."
summary_file="$output_dir/performance_summary.txt"
echo "=== Ceph Performance Test Summary ===" > "$summary_file"
echo "Test Date: $(date)" >> "$summary_file"
echo "Cluster: clustrfck" >> "$summary_file"
echo "" >> "$summary_file"

# Extract key metrics from results
echo "Pool Performance Summary:" >> "$summary_file"
for pool in fast-storage-pool big-rust media; do
    pool_file="$output_dir/rados_bench_${pool}.txt"
    if [ -f "$pool_file" ]; then
        echo "--- $pool ---" >> "$summary_file"
        grep -E "(bandwidth|IOPS|Total time|Average|Stddev)" "$pool_file" >> "$summary_file"
        echo "" >> "$summary_file"
    fi
done

# Extract RBD FIO summary
echo "RBD Performance Summary:" >> "$summary_file"
if [ -f "$rbd_file" ]; then
    grep -E "(read:|write:|IOPS=|BW=)" "$rbd_file" >> "$summary_file"
fi

echo "" >> "$summary_file"
echo "Files generated:" >> "$summary_file"
ls -la "$output_dir" >> "$summary_file"

echo "=== IOPS Testing Complete ==="
echo "All results saved to: $output_dir"
echo ""
echo "Key files:"
echo "  - performance_summary.txt : High-level summary"
echo "  - system_info.txt         : Cluster status"
echo "  - rados_bench_*.txt       : Pool-specific results"
echo "  - rbd_fio_results.txt     : RBD performance"
echo "  - osd_bench_results.txt   : Individual OSD tests"
