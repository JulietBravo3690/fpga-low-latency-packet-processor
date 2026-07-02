module traffic_stats (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        clear_counters,

    input  logic        event_valid,
    input  logic [2:0]  packet_class,
    input  logic        allow_packet,
    input  logic        drop_packet,

    input  logic [15:0] packet_length,
    input  logic        packet_length_valid,

    input  logic        stats_rd_en,
    input  logic [3:0]  stats_addr,
    output logic        stats_rd_valid,
    output logic [31:0] stats_rd_data,

    output logic [31:0] total_packets,
    output logic [31:0] allowed_packets,
    output logic [31:0] dropped_packets,

    output logic [31:0] malformed_packets,
    output logic [31:0] non_ipv4_packets,
    output logic [31:0] market_data_packets,
    output logic [31:0] dns_packets,
    output logic [31:0] web_packets,
    output logic [31:0] control_packets,
    output logic [31:0] trusted_packets,
    output logic [31:0] unknown_packets,

    output logic [31:0] total_ipv4_bytes,
    output logic [15:0] last_packet_length
);

    localparam [2:0] CLASS_MALFORMED   = 3'd0;
    localparam [2:0] CLASS_NON_IPV4    = 3'd1;
    localparam [2:0] CLASS_MARKET_DATA = 3'd2;
    localparam [2:0] CLASS_DNS         = 3'd3;
    localparam [2:0] CLASS_WEB         = 3'd4;
    localparam [2:0] CLASS_CONTROL     = 3'd5;
    localparam [2:0] CLASS_TRUSTED     = 3'd6;
    localparam [2:0] CLASS_UNKNOWN     = 3'd7;

    localparam [3:0] STAT_TOTAL_PACKETS      = 4'd0;
    localparam [3:0] STAT_ALLOWED_PACKETS    = 4'd1;
    localparam [3:0] STAT_DROPPED_PACKETS    = 4'd2;
    localparam [3:0] STAT_MALFORMED_PACKETS  = 4'd3;
    localparam [3:0] STAT_NON_IPV4_PACKETS   = 4'd4;
    localparam [3:0] STAT_MARKET_PACKETS     = 4'd5;
    localparam [3:0] STAT_DNS_PACKETS        = 4'd6;
    localparam [3:0] STAT_WEB_PACKETS        = 4'd7;
    localparam [3:0] STAT_CONTROL_PACKETS    = 4'd8;
    localparam [3:0] STAT_TRUSTED_PACKETS    = 4'd9;
    localparam [3:0] STAT_UNKNOWN_PACKETS    = 4'd10;
    localparam [3:0] STAT_TOTAL_IPV4_BYTES   = 4'd11;
    localparam [3:0] STAT_LAST_PACKET_LENGTH = 4'd12;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_packets       <= 32'd0;
            allowed_packets     <= 32'd0;
            dropped_packets     <= 32'd0;

            malformed_packets   <= 32'd0;
            non_ipv4_packets    <= 32'd0;
            market_data_packets <= 32'd0;
            dns_packets         <= 32'd0;
            web_packets         <= 32'd0;
            control_packets     <= 32'd0;
            trusted_packets     <= 32'd0;
            unknown_packets     <= 32'd0;

            total_ipv4_bytes    <= 32'd0;
            last_packet_length  <= 16'd0;

            stats_rd_valid      <= 1'b0;
            stats_rd_data       <= 32'd0;
        end else begin
            stats_rd_valid <= 1'b0;
            stats_rd_data  <= 32'd0;

            if (clear_counters) begin
                total_packets       <= 32'd0;
                allowed_packets     <= 32'd0;
                dropped_packets     <= 32'd0;

                malformed_packets   <= 32'd0;
                non_ipv4_packets    <= 32'd0;
                market_data_packets <= 32'd0;
                dns_packets         <= 32'd0;
                web_packets         <= 32'd0;
                control_packets     <= 32'd0;
                trusted_packets     <= 32'd0;
                unknown_packets     <= 32'd0;

                total_ipv4_bytes    <= 32'd0;
                last_packet_length  <= 16'd0;
            end else begin

                if (event_valid) begin
                    total_packets <= total_packets + 32'd1;

                    if (allow_packet) begin
                        allowed_packets <= allowed_packets + 32'd1;
                    end

                    if (drop_packet) begin
                        dropped_packets <= dropped_packets + 32'd1;
                    end

                    if (packet_length_valid) begin
                        total_ipv4_bytes   <= total_ipv4_bytes + {16'd0, packet_length};
                        last_packet_length <= packet_length;
                    end else begin
                        last_packet_length <= 16'd0;
                    end

                    case (packet_class)

                        CLASS_MALFORMED: begin
                            malformed_packets <= malformed_packets + 32'd1;
                        end

                        CLASS_NON_IPV4: begin
                            non_ipv4_packets <= non_ipv4_packets + 32'd1;
                        end

                        CLASS_MARKET_DATA: begin
                            market_data_packets <= market_data_packets + 32'd1;
                        end

                        CLASS_DNS: begin
                            dns_packets <= dns_packets + 32'd1;
                        end

                        CLASS_WEB: begin
                            web_packets <= web_packets + 32'd1;
                        end

                        CLASS_CONTROL: begin
                            control_packets <= control_packets + 32'd1;
                        end

                        CLASS_TRUSTED: begin
                            trusted_packets <= trusted_packets + 32'd1;
                        end

                        CLASS_UNKNOWN: begin
                            unknown_packets <= unknown_packets + 32'd1;
                        end

                        default: begin
                            unknown_packets <= unknown_packets + 32'd1;
                        end

                    endcase
                end

                if (stats_rd_en) begin
                    stats_rd_valid <= 1'b1;

                    case (stats_addr)

                        STAT_TOTAL_PACKETS: begin
                            stats_rd_data <= total_packets;
                        end

                        STAT_ALLOWED_PACKETS: begin
                            stats_rd_data <= allowed_packets;
                        end

                        STAT_DROPPED_PACKETS: begin
                            stats_rd_data <= dropped_packets;
                        end

                        STAT_MALFORMED_PACKETS: begin
                            stats_rd_data <= malformed_packets;
                        end

                        STAT_NON_IPV4_PACKETS: begin
                            stats_rd_data <= non_ipv4_packets;
                        end

                        STAT_MARKET_PACKETS: begin
                            stats_rd_data <= market_data_packets;
                        end

                        STAT_DNS_PACKETS: begin
                            stats_rd_data <= dns_packets;
                        end

                        STAT_WEB_PACKETS: begin
                            stats_rd_data <= web_packets;
                        end

                        STAT_CONTROL_PACKETS: begin
                            stats_rd_data <= control_packets;
                        end

                        STAT_TRUSTED_PACKETS: begin
                            stats_rd_data <= trusted_packets;
                        end

                        STAT_UNKNOWN_PACKETS: begin
                            stats_rd_data <= unknown_packets;
                        end

                        STAT_TOTAL_IPV4_BYTES: begin
                            stats_rd_data <= total_ipv4_bytes;
                        end

                        STAT_LAST_PACKET_LENGTH: begin
                            stats_rd_data <= {16'd0, last_packet_length};
                        end

                        default: begin
                            stats_rd_data <= 32'hDEAD_BEEF;
                        end

                    endcase
                end
            end
        end
    end

endmodule