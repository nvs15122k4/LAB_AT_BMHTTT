#!/usr/bin/env bash
# vk.sh VM token...  — gửi phím vào VM. token: ENTER SPACE LEFT RIGHT UP DOWN TAB ESC, "s:text" (gõ chuỗi), "w:N" (chờ N giây), "shot:file" (chụp màn hình)
VM=$1; shift
for t in "$@"; do
  case $t in
    ENTER) VBoxManage controlvm "$VM" keyboardputscancode 1c 9c ;;
    SPACE) VBoxManage controlvm "$VM" keyboardputscancode 39 b9 ;;
    TAB)   VBoxManage controlvm "$VM" keyboardputscancode 0f 8f ;;
    ESC)   VBoxManage controlvm "$VM" keyboardputscancode 01 81 ;;
    LEFT)  VBoxManage controlvm "$VM" keyboardputscancode e0 4b e0 cb ;;
    RIGHT) VBoxManage controlvm "$VM" keyboardputscancode e0 4d e0 cd ;;
    UP)    VBoxManage controlvm "$VM" keyboardputscancode e0 48 e0 c8 ;;
    DOWN)  VBoxManage controlvm "$VM" keyboardputscancode e0 50 e0 d0 ;;
    s:*)   VBoxManage controlvm "$VM" keyboardputstring "${t#s:}" ;;
    w:*)   sleep "${t#w:}" ;;
    shot:*) VBoxManage controlvm "$VM" screenshotpng "${t#shot:}" ;;
  esac
  sleep 0.4
done
