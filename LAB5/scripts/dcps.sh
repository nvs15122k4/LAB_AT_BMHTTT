#!/usr/bin/env bash
# dcps.sh <VM> <shot.png|-> <wait_s> '<lệnh PowerShell>' — gõ lệnh vào cửa sổ PowerShell đang mở, chờ, chụp
VM=$1; OUT=$2; W=$3; shift 3
V=$(dirname "$0")/vk.sh
$V "$VM" 's:cls' ENTER w:1
for c in "$@"; do $V "$VM" "s:$c" ENTER; done
sleep "$W"
[[ "$OUT" != "-" ]] && VBoxManage controlvm "$VM" screenshotpng "$OUT"
