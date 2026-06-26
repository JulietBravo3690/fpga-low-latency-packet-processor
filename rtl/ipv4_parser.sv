module ipv4_parser (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        sop_in,
    input  logic        eop_in,

    output logic [7:0]  data_out,
    output logic        valid_out,
    output logic        sop_out,
    output logic        eop_out,

    output logic [3:0]  ip_version,
    output logic [3:0]  ip_ihl,
    output logic [15:0] ip_total_length,
    output logic [7:0]  ip_protocol,
    output logic [31:0] src_ip,
    output logic [31:0] dst_ip,

    output logic        ipv4_header_valid,
    output logic        udp_packet,
    output logic        tcp_packet,
    output logic        icmp_packet,

    output logic        not_ipv4,
    output logic        unsupported_ihl,
    output logic        invalid_version,
    output logic        parser_error,

    output logic [7:0]  packet_byte_index
);

    typedef enum logic [1:0] {
        IDLE,
        PARSE_FRAME,
        SKIP_PACKET
    } state_t;

    state_t state;

    logic [15:0] ethertype_temp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= IDLE;

            data_out           <= 8'h00;
            valid_out          <= 1'b0;
            sop_out            <= 1'b0;
            eop_out            <= 1'b0;

            ip_version         <= 4'd0;
            ip_ihl             <= 4'd0;
            ip_total_length    <= 16'd0;
            ip_protocol        <= 8'd0;
            src_ip             <= 32'd0;
            dst_ip             <= 32'd0;

            ipv4_header_valid  <= 1'b0;
            udp_packet         <= 1'b0;
            tcp_packet         <= 1'b0;
            icmp_packet        <= 1'b0;

            not_ipv4           <= 1'b0;
            unsupported_ihl    <= 1'b0;
            invalid_version    <= 1'b0;
            parser_error       <= 1'b0;

            packet_byte_index  <= 8'd0;
            ethertype_temp     <= 16'd0;
        end else begin
            // Default one-cycle pulse outputs
            ipv4_header_valid <= 1'b0;
            udp_packet        <= 1'b0;
            tcp_packet        <= 1'b0;
            icmp_packet       <= 1'b0;

            not_ipv4          <= 1'b0;
            unsupported_ihl   <= 1'b0;
            invalid_version   <= 1'b0;
            parser_error      <= 1'b0;

            // Pass-through stream
            data_out  <= data_in;
            valid_out <= valid_in;
            sop_out   <= sop_in;
            eop_out   <= eop_in;

            case (state)

                IDLE: begin
                    packet_byte_index <= 8'd0;

                    if (valid_in) begin
                        if (sop_in) begin
                            // Start of a new Ethernet frame
                            ip_version      <= 4'd0;
                            ip_ihl          <= 4'd0;
                            ip_total_length <= 16'd0;
                            ip_protocol     <= 8'd0;
                            src_ip          <= 32'd0;
                            dst_ip          <= 32'd0;
                            ethertype_temp  <= 16'd0;

                            if (eop_in) begin
                                parser_error      <= 1'b1;
                                packet_byte_index <= 8'd0;
                                state             <= IDLE;
                            end else begin
                                packet_byte_index <= 8'd1;
                                state             <= PARSE_FRAME;
                            end
                        end else begin
                            parser_error <= 1'b1;
                            state        <= IDLE;
                        end
                    end
                end

                PARSE_FRAME: begin
                    if (valid_in) begin
                        if (sop_in) begin
                            // New packet started before old packet ended
                            parser_error      <= 1'b1;
                            packet_byte_index <= 8'd1;
                            ethertype_temp    <= 16'd0;
                            state             <= PARSE_FRAME;
                        end else begin

                            case (packet_byte_index)

                                // Ethernet EtherType field
                                8'd12: ethertype_temp[15:8] <= data_in;

                                8'd13: begin
                                    ethertype_temp[7:0] <= data_in;
                                end

                                // IPv4 header starts at byte 14
                                8'd14: begin
                                    ip_version <= data_in[7:4];
                                    ip_ihl     <= data_in[3:0];
                                end

                                8'd16: ip_total_length[15:8] <= data_in;
                                8'd17: ip_total_length[7:0]  <= data_in;

                                8'd23: ip_protocol <= data_in;

                                8'd26: src_ip[31:24] <= data_in;
                                8'd27: src_ip[23:16] <= data_in;
                                8'd28: src_ip[15:8]  <= data_in;
                                8'd29: src_ip[7:0]   <= data_in;

                                8'd30: dst_ip[31:24] <= data_in;
                                8'd31: dst_ip[23:16] <= data_in;
                                8'd32: dst_ip[15:8]  <= data_in;
                                8'd33: begin
                                    dst_ip[7:0]          <= data_in;
                                    ipv4_header_valid    <= 1'b1;

                                    if (ip_protocol == 8'd17) begin
                                        udp_packet <= 1'b1;
                                    end else if (ip_protocol == 8'd6) begin
                                        tcp_packet <= 1'b1;
                                    end else if (ip_protocol == 8'd1) begin
                                        icmp_packet <= 1'b1;
                                    end
                                end

                                default: begin
                                    // Other bytes are ignored for now
                                end

                            endcase

                            // Decision logic after processing current byte

                            if ((packet_byte_index == 8'd13) &&
                                ({ethertype_temp[15:8], data_in} != 16'h0800)) begin

                                // Ethernet frame is not IPv4
                                not_ipv4          <= 1'b1;
                                packet_byte_index <= 8'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end

                            end else if ((packet_byte_index == 8'd13) && eop_in) begin

                                // EtherType says IPv4, but packet ended before IPv4 header
                                parser_error      <= 1'b1;
                                packet_byte_index <= 8'd0;
                                state             <= IDLE;

                            end else if ((packet_byte_index == 8'd14) &&
                                         ((data_in[7:4] != 4'd4) || (data_in[3:0] != 4'd5))) begin

                                // Only IPv4 with IHL = 5 is supported right now
                                if (data_in[7:4] != 4'd4) begin
                                    invalid_version <= 1'b1;
                                end

                                if (data_in[3:0] != 4'd5) begin
                                    unsupported_ihl <= 1'b1;
                                end

                                packet_byte_index <= 8'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end

                            end else if (packet_byte_index == 8'd33) begin

                                // IPv4 header complete
                                packet_byte_index <= 8'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end

                            end else if (eop_in) begin

                                // Packet ended before IPv4 header completed
                                parser_error      <= 1'b1;
                                packet_byte_index <= 8'd0;
                                state             <= IDLE;

                            end else begin

                                packet_byte_index <= packet_byte_index + 8'd1;
                                state             <= PARSE_FRAME;

                            end
                        end
                    end
                end

                SKIP_PACKET: begin
                    if (valid_in) begin
                        if (sop_in) begin
                            parser_error      <= 1'b1;
                            packet_byte_index <= 8'd1;
                            state             <= PARSE_FRAME;
                        end else if (eop_in) begin
                            packet_byte_index <= 8'd0;
                            state             <= IDLE;
                        end
                    end
                end

                default: begin
                    packet_byte_index <= 8'd0;
                    state             <= IDLE;
                end

            endcase
        end
    end

endmodule