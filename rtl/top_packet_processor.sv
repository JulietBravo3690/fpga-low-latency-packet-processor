module top_packet_processor (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        sop_in,
    input  logic        eop_in,

    input  logic        drop_unknown,

    input  logic        clear_counters,
    input  logic        stats_rd_en,
    input  logic [3:0]  stats_addr,

    output logic [7:0]  data_out,
    output logic        valid_out,
    output logic        sop_out,
    output logic        eop_out,

    output logic [47:0] dest_mac,
    output logic [47:0] src_mac,
    output logic [15:0] ethertype,

    output logic [3:0]  ip_version,
    output logic [3:0]  ip_ihl,
    output logic [15:0] ip_total_length,
    output logic [7:0]  ip_protocol,
    output logic [31:0] src_ip,
    output logic [31:0] dst_ip,

    output logic [15:0] udp_src_port,
    output logic [15:0] udp_dst_port,
    output logic [15:0] udp_length,
    output logic [15:0] udp_checksum,

    output logic        metadata_ready,
    output logic        parser_error_any,

    output logic        class_valid,
    output logic [2:0]  packet_class,

    output logic        allow_packet,
    output logic        drop_packet,

    output logic        malformed_packet,
    output logic        non_ipv4_packet,
    output logic        market_data_packet,
    output logic        dns_packet,
    output logic        web_packet,
    output logic        control_packet,
    output logic        trusted_packet,
    output logic        unknown_packet,

    output logic        stats_rd_valid,
    output logic [31:0] stats_rd_data,

    output logic [31:0] total_packets,
    output logic [31:0] allowed_packets,
    output logic [31:0] dropped_packets,
    output logic [31:0] malformed_packets,
    output logic [31:0] non_ipv4_packets,
    output logic [31:0] market_data_packets_count,
    output logic [31:0] dns_packets_count,
    output logic [31:0] web_packets_count,
    output logic [31:0] control_packets_count,
    output logic [31:0] trusted_packets_count,
    output logic [31:0] unknown_packets_count,
    output logic [31:0] total_ipv4_bytes,
    output logic [15:0] last_packet_length
);

    localparam [2:0] CLASS_MALFORMED   = 3'd0;
    localparam [2:0] CLASS_NON_IPV4    = 3'd1;

    // ------------------------------------------------------------
    // Ethernet parser wires
    // ------------------------------------------------------------

    logic [7:0]  eth_data_out;
    logic        eth_valid_out;
    logic        eth_sop_out;
    logic        eth_eop_out;

    logic [47:0] eth_dest_mac;
    logic [47:0] eth_src_mac;
    logic [15:0] eth_ethertype;

    logic        eth_header_valid;
    logic        eth_ipv4_frame;
    logic        eth_unsupported_ethertype;
    logic        eth_parser_error;
    logic [4:0]  eth_header_byte_index;

    // ------------------------------------------------------------
    // IPv4 parser wires
    // ------------------------------------------------------------

    logic [7:0]  ipv4_data_out;
    logic        ipv4_valid_out;
    logic        ipv4_sop_out;
    logic        ipv4_eop_out;

    logic [3:0]  ipv4_ip_version;
    logic [3:0]  ipv4_ip_ihl;
    logic [15:0] ipv4_ip_total_length;
    logic [7:0]  ipv4_ip_protocol;
    logic [31:0] ipv4_src_ip;
    logic [31:0] ipv4_dst_ip;

    logic        ipv4_header_valid;
    logic        ipv4_udp_packet;
    logic        ipv4_tcp_packet;
    logic        ipv4_icmp_packet;

    logic        ipv4_not_ipv4;
    logic        ipv4_unsupported_ihl;
    logic        ipv4_invalid_version;
    logic        ipv4_parser_error;
    logic [7:0]  ipv4_packet_byte_index;

    // ------------------------------------------------------------
    // UDP parser wires
    // ------------------------------------------------------------

    logic [7:0]  udp_data_out;
    logic        udp_valid_out;
    logic        udp_sop_out;
    logic        udp_eop_out;

    logic [15:0] udp_src_port_w;
    logic [15:0] udp_dst_port_w;
    logic [15:0] udp_length_w;
    logic [15:0] udp_checksum_w;

    logic        udp_header_valid;
    logic        udp_market_data_detected;
    logic        udp_dns_detected;

    logic        udp_not_ipv4;
    logic        udp_not_udp;
    logic        udp_invalid_version;
    logic        udp_unsupported_ihl;
    logic        udp_parser_error;
    logic [7:0]  udp_packet_byte_index;

    // ------------------------------------------------------------
    // Classifier control
    // ------------------------------------------------------------

    logic classifier_metadata_valid;
    logic classifier_parser_error;

    logic stats_packet_length_valid;

    assign metadata_ready   = classifier_metadata_valid;
    assign parser_error_any = eth_parser_error | ipv4_parser_error | udp_parser_error;

    assign data_out  = data_in;
    assign valid_out = valid_in;
    assign sop_out   = sop_in;
    assign eop_out   = eop_in;

    assign stats_packet_length_valid =
        class_valid &&
        (packet_class != CLASS_MALFORMED) &&
        (packet_class != CLASS_NON_IPV4);

    // ------------------------------------------------------------
    // Parser instances
    // ------------------------------------------------------------

    ethernet_parser u_ethernet_parser (
        .clk(clk),
        .rst_n(rst_n),

        .data_in(data_in),
        .valid_in(valid_in),
        .sop_in(sop_in),
        .eop_in(eop_in),

        .data_out(eth_data_out),
        .valid_out(eth_valid_out),
        .sop_out(eth_sop_out),
        .eop_out(eth_eop_out),

        .dest_mac(eth_dest_mac),
        .src_mac(eth_src_mac),
        .ethertype(eth_ethertype),

        .eth_header_valid(eth_header_valid),
        .ipv4_frame(eth_ipv4_frame),
        .unsupported_ethertype(eth_unsupported_ethertype),
        .parser_error(eth_parser_error),

        .header_byte_index(eth_header_byte_index)
    );

    ipv4_parser u_ipv4_parser (
        .clk(clk),
        .rst_n(rst_n),

        .data_in(data_in),
        .valid_in(valid_in),
        .sop_in(sop_in),
        .eop_in(eop_in),

        .data_out(ipv4_data_out),
        .valid_out(ipv4_valid_out),
        .sop_out(ipv4_sop_out),
        .eop_out(ipv4_eop_out),

        .ip_version(ipv4_ip_version),
        .ip_ihl(ipv4_ip_ihl),
        .ip_total_length(ipv4_ip_total_length),
        .ip_protocol(ipv4_ip_protocol),
        .src_ip(ipv4_src_ip),
        .dst_ip(ipv4_dst_ip),

        .ipv4_header_valid(ipv4_header_valid),
        .udp_packet(ipv4_udp_packet),
        .tcp_packet(ipv4_tcp_packet),
        .icmp_packet(ipv4_icmp_packet),

        .not_ipv4(ipv4_not_ipv4),
        .unsupported_ihl(ipv4_unsupported_ihl),
        .invalid_version(ipv4_invalid_version),
        .parser_error(ipv4_parser_error),

        .packet_byte_index(ipv4_packet_byte_index)
    );

    udp_parser u_udp_parser (
        .clk(clk),
        .rst_n(rst_n),

        .data_in(data_in),
        .valid_in(valid_in),
        .sop_in(sop_in),
        .eop_in(eop_in),

        .data_out(udp_data_out),
        .valid_out(udp_valid_out),
        .sop_out(udp_sop_out),
        .eop_out(udp_eop_out),

        .udp_src_port(udp_src_port_w),
        .udp_dst_port(udp_dst_port_w),
        .udp_length(udp_length_w),
        .udp_checksum(udp_checksum_w),

        .udp_header_valid(udp_header_valid),
        .market_data_packet(udp_market_data_detected),
        .dns_packet(udp_dns_detected),

        .not_ipv4(udp_not_ipv4),
        .not_udp(udp_not_udp),
        .invalid_version(udp_invalid_version),
        .unsupported_ihl(udp_unsupported_ihl),
        .parser_error(udp_parser_error),

        .packet_byte_index(udp_packet_byte_index)
    );

    // ------------------------------------------------------------
    // Metadata completion unit
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dest_mac                  <= 48'd0;
            src_mac                   <= 48'd0;
            ethertype                 <= 16'd0;

            ip_version                <= 4'd0;
            ip_ihl                    <= 4'd0;
            ip_total_length           <= 16'd0;
            ip_protocol               <= 8'd0;
            src_ip                    <= 32'd0;
            dst_ip                    <= 32'd0;

            udp_src_port              <= 16'd0;
            udp_dst_port              <= 16'd0;
            udp_length                <= 16'd0;
            udp_checksum              <= 16'd0;

            classifier_metadata_valid <= 1'b0;
            classifier_parser_error   <= 1'b0;
        end else begin
            classifier_metadata_valid <= 1'b0;
            classifier_parser_error   <= 1'b0;

            if (eth_header_valid) begin
                dest_mac  <= eth_dest_mac;
                src_mac   <= eth_src_mac;
                ethertype <= eth_ethertype;
            end

            if (ipv4_header_valid) begin
                ip_version      <= ipv4_ip_version;
                ip_ihl          <= ipv4_ip_ihl;
                ip_total_length <= ipv4_ip_total_length;
                ip_protocol     <= ipv4_ip_protocol;
                src_ip          <= ipv4_src_ip;
                dst_ip          <= ipv4_dst_ip;
            end

            if (udp_header_valid) begin
                udp_src_port <= udp_src_port_w;
                udp_dst_port <= udp_dst_port_w;
                udp_length   <= udp_length_w;
                udp_checksum <= udp_checksum_w;
            end

            if (eth_parser_error || ipv4_parser_error || udp_parser_error) begin
                classifier_metadata_valid <= 1'b1;
                classifier_parser_error   <= 1'b1;
            end else if (udp_not_ipv4) begin
                classifier_metadata_valid <= 1'b1;
                classifier_parser_error   <= 1'b0;
            end else if (udp_header_valid) begin
                classifier_metadata_valid <= 1'b1;
                classifier_parser_error   <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // Packet classifier
    // ------------------------------------------------------------

    packet_classifier u_packet_classifier (
        .clk(clk),
        .rst_n(rst_n),

        .metadata_valid(classifier_metadata_valid),
        .parser_error(classifier_parser_error),

        .ethertype(ethertype),
        .ip_protocol(ip_protocol),
        .src_ip(src_ip),
        .dst_ip(dst_ip),
        .src_port(udp_src_port),
        .dst_port(udp_dst_port),

        .drop_unknown(drop_unknown),

        .class_valid(class_valid),
        .packet_class(packet_class),

        .allow_packet(allow_packet),
        .drop_packet(drop_packet),

        .malformed_packet(malformed_packet),
        .non_ipv4_packet(non_ipv4_packet),
        .market_data_packet(market_data_packet),
        .dns_packet(dns_packet),
        .web_packet(web_packet),
        .control_packet(control_packet),
        .trusted_packet(trusted_packet),
        .unknown_packet(unknown_packet)
    );

    // ------------------------------------------------------------
    // Traffic statistics engine
    // ------------------------------------------------------------

    traffic_stats u_traffic_stats (
        .clk(clk),
        .rst_n(rst_n),

        .clear_counters(clear_counters),

        .event_valid(class_valid),
        .packet_class(packet_class),
        .allow_packet(allow_packet),
        .drop_packet(drop_packet),

        .packet_length(ip_total_length),
        .packet_length_valid(stats_packet_length_valid),

        .stats_rd_en(stats_rd_en),
        .stats_addr(stats_addr),
        .stats_rd_valid(stats_rd_valid),
        .stats_rd_data(stats_rd_data),

        .total_packets(total_packets),
        .allowed_packets(allowed_packets),
        .dropped_packets(dropped_packets),

        .malformed_packets(malformed_packets),
        .non_ipv4_packets(non_ipv4_packets),
        .market_data_packets(market_data_packets_count),
        .dns_packets(dns_packets_count),
        .web_packets(web_packets_count),
        .control_packets(control_packets_count),
        .trusted_packets(trusted_packets_count),
        .unknown_packets(unknown_packets_count),

        .total_ipv4_bytes(total_ipv4_bytes),
        .last_packet_length(last_packet_length)
    );

endmodule