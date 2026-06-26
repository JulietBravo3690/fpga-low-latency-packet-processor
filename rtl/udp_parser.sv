module udp_parser (
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

    output logic [15:0] udp_src_port,
    output logic [15:0] udp_dst_port,
    output logic [15:0] udp_length,
    output logic [15:0] udp_checksum,

    output logic        udp_header_valid,
    output logic        market_data_packet,
    output logic        dns_packet,

    output logic        not_ipv4,
    output logic        not_udp,
    output logic        invalid_version,
    output logic        unsupported_ihl,
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

            udp_src_port       <= 16'd0;
            udp_dst_port       <= 16'd0;
            udp_length         <= 16'd0;
            udp_checksum       <= 16'd0;

            udp_header_valid   <= 1'b0;
            market_data_packet <= 1'b0;
            dns_packet         <= 1'b0;

            not_ipv4           <= 1'b0;
            not_udp            <= 1'b0;
            invalid_version    <= 1'b0;
            unsupported_ihl    <= 1'b0;
            parser_error       <= 1'b0;

            packet_byte_index  <= 8'd0;
            ethertype_temp     <= 16'd0;
        end else begin
            // Default one-cycle pulse outputs
            udp_header_valid   <= 1'b0;
            market_data_packet <= 1'b0;
            dns_packet         <= 1'b0;

            not_ipv4           <= 1'b0;
            not_udp            <= 1'b0;
            invalid_version    <= 1'b0;
            unsupported_ihl    <= 1'b0;
            parser_error       <= 1'b0;

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
                            udp_src_port   <= 16'd0;
                            udp_dst_port   <= 16'd0;
                            udp_length     <= 16'd0;
                            udp_checksum   <= 16'd0;
                            ethertype_temp <= 16'd0;

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
                            parser_error      <= 1'b1;
                            packet_byte_index <= 8'd1;
                            ethertype_temp    <= 16'd0;
                            state             <= PARSE_FRAME;
                        end else begin

                            case (packet_byte_index)

                                // Ethernet EtherType
                                8'd12: ethertype_temp[15:8] <= data_in;

                                8'd13: ethertype_temp[7:0] <= data_in;

                                // IPv4 version + IHL
                                8'd14: begin
                                    // Checked below
                                end

                                // IPv4 protocol byte
                                8'd23: begin
                                    // Checked below
                                end

                                // UDP header starts at byte 34
                                8'd34: udp_src_port[15:8] <= data_in;
                                8'd35: udp_src_port[7:0]  <= data_in;

                                8'd36: udp_dst_port[15:8] <= data_in;
                                8'd37: udp_dst_port[7:0]  <= data_in;

                                8'd38: udp_length[15:8]   <= data_in;
                                8'd39: udp_length[7:0]    <= data_in;

                                8'd40: udp_checksum[15:8] <= data_in;

                                8'd41: begin
                                    udp_checksum[7:0] <= data_in;
                                    udp_header_valid  <= 1'b1;

                                    if ((udp_dst_port >= 16'd5000) && (udp_dst_port <= 16'd6000)) begin
                                        market_data_packet <= 1'b1;
                                    end

                                    if ((udp_src_port == 16'd53) || (udp_dst_port == 16'd53)) begin
                                        dns_packet <= 1'b1;
                                    end
                                end

                                default: begin
                                    // Other bytes ignored for now
                                end

                            endcase

                            // Decision logic after processing current byte

                            if ((packet_byte_index == 8'd13) &&
                                ({ethertype_temp[15:8], data_in} != 16'h0800)) begin

                                not_ipv4          <= 1'b1;
                                packet_byte_index <= 8'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end

                            end else if ((packet_byte_index == 8'd14) &&
                                         ((data_in[7:4] != 4'd4) || (data_in[3:0] != 4'd5))) begin

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

                            end else if ((packet_byte_index == 8'd23) &&
                                         (data_in != 8'd17)) begin

                                not_udp           <= 1'b1;
                                packet_byte_index <= 8'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end

                            end else if (packet_byte_index == 8'd41) begin

                                packet_byte_index <= 8'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end

                            end else if (eop_in) begin

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
                            ethertype_temp    <= 16'd0;
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