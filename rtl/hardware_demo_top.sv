module hardware_demo_top #(
    parameter PACKET_BUFFER_DEPTH = 128,
    parameter PACKET_INDEX_WIDTH  = $clog2(PACKET_BUFFER_DEPTH)
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic        clear_status,
    input  logic        clear_counters,

    output logic        source_busy,
    output logic        source_done,
    output logic        start_ready,
    output logic [7:0]  stream_data,
    output logic        stream_valid,
    output logic        stream_sop,
    output logic        stream_eop,

    output logic        class_valid,
    output logic        packet_allowed,
    output logic        packet_dropped,
    output logic        market_packet_detected,
    output logic        market_message_valid,
    output logic        market_decoder_error,
    output logic [7:0]  market_message_type,
    output logic [31:0] market_symbol,
    output logic [31:0] market_price,
    output logic [31:0] market_quantity,
    output logic [31:0] market_sequence_number,

    output logic [15:0] ethernet_latency,
    output logic [15:0] ipv4_latency,
    output logic [15:0] udp_latency,
    output logic [15:0] classification_latency,
    output logic [15:0] statistics_latency,
    output logic        ethernet_latency_valid,
    output logic        ipv4_latency_valid,
    output logic        udp_latency_valid,
    output logic        classification_latency_valid,
    output logic        statistics_latency_valid,
    output logic        latency_counter_overflow,
    output logic        packet_buffer_overflow,

    output logic [31:0] total_packets,
    output logic [31:0] market_data_packets_count,
    output logic [31:0] total_ipv4_bytes,

    output logic        packet_seen,
    output logic        allowed_seen,
    output logic        dropped_seen,
    output logic        market_seen,
    output logic        message_seen,
    output logic        decoder_error_seen,
    output logic        latency_overflow_seen,
    output logic [7:0]  last_message_type,
    output logic [31:0] last_symbol,
    output logic [31:0] last_price,
    output logic [31:0] last_quantity,
    output logic [31:0] last_sequence_number,
    output logic [15:0] last_ethernet_latency,
    output logic [15:0] last_ipv4_latency,
    output logic [15:0] last_udp_latency,
    output logic [15:0] last_classification_latency,
    output logic [15:0] last_statistics_latency
);

    logic processor_in_ready;

    assign start_ready = !source_busy && processor_in_ready;

    packet_rom_source u_packet_rom_source (
        .clk(clk), .rst_n(rst_n), .start(start && start_ready),
        .data_out(stream_data), .valid_out(stream_valid),
        .sop_out(stream_sop), .eop_out(stream_eop),
        .busy(source_busy), .done(source_done)
    );

    top_packet_processor #(
        .PACKET_BUFFER_DEPTH(PACKET_BUFFER_DEPTH),
        .PACKET_INDEX_WIDTH(PACKET_INDEX_WIDTH)
    ) u_packet_processor (
        .clk(clk), .rst_n(rst_n),
        .data_in(stream_data), .valid_in(stream_valid),
        .in_ready(processor_in_ready),
        .sop_in(stream_sop), .eop_in(stream_eop),
        .out_ready(1'b1),
        .drop_unknown(1'b1),
        .clear_counters(clear_counters),
        .stats_rd_en(1'b0), .stats_addr(4'd0),
        .class_valid(class_valid),
        .allow_packet(packet_allowed), .drop_packet(packet_dropped),
        .market_data_packet(market_packet_detected),
        .market_message_valid(market_message_valid),
        .market_decoder_error(market_decoder_error),
        .market_message_type(market_message_type),
        .market_symbol(market_symbol), .market_price(market_price),
        .market_quantity(market_quantity),
        .market_sequence_number(market_sequence_number),
        .ethernet_latency(ethernet_latency),
        .ipv4_latency(ipv4_latency), .udp_latency(udp_latency),
        .classification_latency(classification_latency),
        .statistics_latency(statistics_latency),
        .ethernet_latency_valid(ethernet_latency_valid),
        .ipv4_latency_valid(ipv4_latency_valid),
        .udp_latency_valid(udp_latency_valid),
        .classification_latency_valid(classification_latency_valid),
        .statistics_latency_valid(statistics_latency_valid),
        .latency_counter_overflow(latency_counter_overflow),
        .packet_buffer_overflow(packet_buffer_overflow),
        .total_packets(total_packets),
        .market_data_packets_count(market_data_packets_count),
        .total_ipv4_bytes(total_ipv4_bytes)
    );

    hardware_status u_hardware_status (
        .clk(clk), .rst_n(rst_n), .clear(clear_status),
        .class_valid(class_valid), .allow_packet(packet_allowed),
        .drop_packet(packet_dropped), .market_packet(market_packet_detected),
        .message_valid(market_message_valid),
        .decoder_error(market_decoder_error),
        .latency_overflow(latency_counter_overflow),
        .message_type(market_message_type), .symbol(market_symbol),
        .price(market_price), .quantity(market_quantity),
        .sequence_number(market_sequence_number),
        .ethernet_latency(ethernet_latency), .ipv4_latency(ipv4_latency),
        .udp_latency(udp_latency),
        .classification_latency(classification_latency),
        .statistics_latency(statistics_latency),
        .statistics_latency_valid(statistics_latency_valid),
        .packet_seen(packet_seen), .allowed_seen(allowed_seen),
        .dropped_seen(dropped_seen), .market_seen(market_seen),
        .message_seen(message_seen), .decoder_error_seen(decoder_error_seen),
        .latency_overflow_seen(latency_overflow_seen),
        .last_message_type(last_message_type), .last_symbol(last_symbol),
        .last_price(last_price), .last_quantity(last_quantity),
        .last_sequence_number(last_sequence_number),
        .last_ethernet_latency(last_ethernet_latency),
        .last_ipv4_latency(last_ipv4_latency),
        .last_udp_latency(last_udp_latency),
        .last_classification_latency(last_classification_latency),
        .last_statistics_latency(last_statistics_latency)
    );

endmodule
