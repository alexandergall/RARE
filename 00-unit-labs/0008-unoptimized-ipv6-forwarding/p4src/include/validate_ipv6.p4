/* Validate an IPv6 packet, currently only the hop_limit.  Maybe also
   check for multicast in the source address, for example */

control ctl_validate_ipv6(inout headers hdr,
inout standard_metadata_t standard_metadata) {
    action malformed() {
        mark_to_drop(standard_metadata);
    }
    
    table tbl_validate_ipv6 {
        key = {
            hdr.ipv6.hop_limit: exact;
        }
        actions = {
            malformed;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            ( 0 ) : malformed();
        }
    }
    
    apply {
        tbl_validate_ipv6.apply();
    }
}
