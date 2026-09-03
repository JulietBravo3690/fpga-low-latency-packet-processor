module hardware_status (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clear,

    input  logic        class_valid,
    input  logic        allow_packet,
    input  logic        drop_packet,
    input  logic        market_packet,
    input  logic        message_valid,
    input  logic        decoder_error,
    input  logic        latency_overflow,
    input  logic [7:0]  message_type,
    input  logic [31:0] symbol,
    input  logic [31:0] price,
    input  logic [31:0] quantity,
    input  logic [31:0] sequence_number,
    input  logic [15:0] ethernet_latency,
    input  logic [15:0] ipv4_latency,
    input  logic [15:0] udp_latency,
    input  logic [15:0] classification_latency,
    input  logic [15:0] statistics_latency,
    input  logic        statistics_latency_valid,

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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_seen                <= 1'b0;
            allowed_seen               <= 1'b0;
            dropped_seen               <= 1'b0;
            market_seen                <= 1'b0;
            message_seen               <= 1'b0;
            decoder_error_seen         <= 1'b0;
            latency_overflow_seen      <= 1'b0;
            last_message_type          <= 8'd0;
            last_symbol                <= 32'd0;
            last_price                 <= 32'd0;
            last_quantity              <= 32'd0;
            last_sequence_number       <= 32'd0;
            last_ethernet_latency      <= 16'd0;
            last_ipv4_latency          <= 16'd0;
            last_udp_latency           <= 16'd0;
            last_classification_latency <= 16'd0;
            last_statistics_latency    <= 16'd0;
        end else if (clear) begin
            packet_seen                <= 1'b0;
            allowed_seen               <= 1'b0;
            dropped_seen               <= 1'b0;
            market_seen                <= 1'b0;
            message_seen               <= 1'b0;
            decoder_error_seen         <= 1'b0;
            latency_overflow_seen      <= 1'b0;
            last_message_type          <= 8'd0;
            last_symbol                <= 32'd0;
            last_price                 <= 32'd0;
            last_quantity              <= 32'd0;
            last_sequence_number       <= 32'd0;
            last_ethernet_latency      <= 16'd0;
            last_ipv4_latency          <= 16'd0;
            last_udp_latency           <= 16'd0;
            last_classification_latency <= 16'd0;
            last_statistics_latency    <= 16'd0;
        end else begin
            if (class_valid) begin
                packet_seen  <= 1'b1;
                allowed_seen <= allowed_seen | allow_packet;
                dropped_seen <= dropped_seen | drop_packet;
                market_seen  <= market_seen | market_packet;
            end
            if (message_valid) begin
                message_seen         <= 1'b1;
                last_message_type    <= message_type;
                last_symbol          <= symbol;
                last_price           <= price;
                last_quantity        <= quantity;
                last_sequence_number <= sequence_number;
            end
            if (decoder_error)
                decoder_error_seen <= 1'b1;
            if (latency_overflow)
                latency_overflow_seen <= 1'b1;
            if (statistics_latency_valid) begin
                last_ethernet_latency       <= ethernet_latency;
                last_ipv4_latency           <= ipv4_latency;
                last_udp_latency            <= udp_latency;
                last_classification_latency <= classification_latency;
                last_statistics_latency     <= statistics_latency;
            end
        end
    end

endmodule
