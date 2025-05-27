#!/bin/sh

set -e

if [ "$#" -ne 4 ]; then
    exit 1
fi

stage1_elf=$1
stage2_bin=$2
bin=$3
sector=$4

size="$(stat -c %s $stage2_bin)"
length="$((size / 512))"

sector_offset="$(objdump -D $stage1_elf | grep stage2_sector | gawk -n '{printf "0x%04X\n", "0x" $1}')"
length_offset="$(objdump -D $stage1_elf | grep stage2_length | gawk -n '{printf "0x%04X\n", "0x" $1}')"
start_offset="$(objdump -D $stage1_elf | grep _start | gawk -n '{printf "0x%04X\n", "0x" $1}')"

sector_offset=$((sector_offset - start_offset))
length_offset=$((length_offset - start_offset))

perl -e "print pack('S', $sector)" | dd of=$bin bs=1 seek=$sector_offset conv=notrunc status=none
perl -e "print pack('S', $length)" | dd of=$bin bs=1 seek=$length_offset conv=notrunc status=none
