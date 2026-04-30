#!/bin/bash

NFT_TABLE="ip nat"

ensure_base() {
    nft list table $NFT_TABLE >/dev/null 2>&1 || nft add table $NFT_TABLE

    nft list chain $NFT_TABLE prerouting >/dev/null 2>&1 || \
    nft 'add chain ip nat prerouting { type nat hook prerouting priority dstnat; }'

    nft list chain $NFT_TABLE postrouting >/dev/null 2>&1 || \
    nft 'add chain ip nat postrouting { type nat hook postrouting priority srcnat; }'
}

add_rule() {
    read -p "本机端口: " sport
    read -p "目标IP: " dip
    read -p "目标端口: " dport

    ensure_base

    nft add rule ip nat prerouting tcp dport $sport dnat to $dip:$dport
    nft add rule ip nat postrouting masquerade

    echo "✔ 已添加: $sport → $dip:$dport"
}

list_rule() {
    echo "===== NAT RULES ====="
    nft list ruleset | sed -n '/table ip nat/,/}/p'
}

del_rule() {
    read -p "删除本机端口: " sport

    handle=$(nft -a list chain ip nat prerouting | grep "dport $sport" | awk '{print $NF}')

    if [ -z "$handle" ]; then
        echo "❌ 未找到规则"
        exit 1
    fi

    nft delete rule ip nat prerouting handle $handle
    echo "✔ 已删除端口: $sport"
}

save_rules() {
    nft list ruleset > /etc/nftables.conf
    echo "✔ 已保存到 /etc/nftables.conf"
}

while true; do
echo ""
echo "===== NAT TOOL ====="
echo "1) 添加转发"
echo "2) 查看规则"
echo "3) 删除转发"
echo "4) 保存规则"
echo "0) 退出"
read -p "选择: " opt

case $opt in
1) add_rule ;;
2) list_rule ;;
3) del_rule ;;
4) save_rules ;;
0) exit ;;
*) echo "无效选项" ;;
esac
done
