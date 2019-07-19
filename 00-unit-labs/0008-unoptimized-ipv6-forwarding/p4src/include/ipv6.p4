/*
 * IPv6 address encoded using 128 bits
 */
typedef bit<128> ipv6_addr_t;

/*
 * IPv6 header: as a header type
 */
header ipv6_t {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_ipv6_addr;
    ipv6_addr_t dst_ipv6_addr;
}
