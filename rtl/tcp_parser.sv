module tcp_parser (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        sop_in,
    input  logic        eop_in,

    output logic [15:0] tcp_src_port,
    output logic [15:0] tcp_dst_port,
    output logic [3:0]  tcp_data_offset,
    output logic [7:0]  tcp_flags,
    output logic        tcp_header_valid,
    output logic        not_tcp,
    output logic        parser_error,
    output logic [7:0]  packet_byte_index
);

    typedef enum logic [1:0] {IDLE, PARSE_FRAME, SKIP_PACKET} state_t;
    state_t state;
    logic [15:0] ethertype_temp;
    logic [7:0] protocol_temp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= IDLE;
            tcp_src_port      <= 16'd0;
            tcp_dst_port      <= 16'd0;
            tcp_data_offset   <= 4'd0;
            tcp_flags         <= 8'd0;
            tcp_header_valid  <= 1'b0;
            not_tcp           <= 1'b0;
            parser_error      <= 1'b0;
            packet_byte_index <= 8'd0;
            ethertype_temp    <= 16'd0;
            protocol_temp     <= 8'd0;
        end else begin
            tcp_header_valid <= 1'b0;
            not_tcp          <= 1'b0;
            parser_error     <= 1'b0;

            case (state)
                IDLE: begin
                    packet_byte_index <= 8'd0;
                    if (valid_in) begin
                        if (sop_in) begin
                            tcp_src_port    <= 16'd0;
                            tcp_dst_port    <= 16'd0;
                            tcp_data_offset <= 4'd0;
                            tcp_flags       <= 8'd0;
                            ethertype_temp  <= 16'd0;
                            protocol_temp   <= 8'd0;
                            if (eop_in) begin
                                parser_error <= 1'b1;
                            end else begin
                                packet_byte_index <= 8'd1;
                                state             <= PARSE_FRAME;
                            end
                        end else begin
                            parser_error <= 1'b1;
                        end
                    end
                end

                PARSE_FRAME: begin
                    if (valid_in) begin
                        if (sop_in) begin
                            parser_error      <= 1'b1;
                            packet_byte_index <= 8'd1;
                            tcp_src_port      <= 16'd0;
                            tcp_dst_port      <= 16'd0;
                        end else begin
                            case (packet_byte_index)
                                8'd12: ethertype_temp[15:8] <= data_in;
                                8'd13: ethertype_temp[7:0]  <= data_in;
                                8'd14: begin
                                    if ((data_in[7:4] != 4'd4) ||
                                        (data_in[3:0] != 4'd5)) begin
                                        state <= SKIP_PACKET;
                                    end
                                end
                                8'd23: begin
                                    protocol_temp <= data_in;
                                    if (data_in != 8'd6) begin
                                        not_tcp <= 1'b1;
                                        state   <= SKIP_PACKET;
                                    end
                                end
                                8'd34: tcp_src_port[15:8] <= data_in;
                                8'd35: tcp_src_port[7:0]  <= data_in;
                                8'd36: tcp_dst_port[15:8] <= data_in;
                                8'd37: tcp_dst_port[7:0]  <= data_in;
                                8'd46: begin
                                    tcp_data_offset <= data_in[7:4];
                                    // TCP options are outside this fixed-header
                                    // fast path, so require exactly 20 bytes.
                                    if (data_in[7:4] != 4'd5) begin
                                        parser_error <= 1'b1;
                                        state        <= SKIP_PACKET;
                                    end
                                end
                                8'd47: tcp_flags <= data_in;
                                8'd53: begin
                                    tcp_header_valid <= 1'b1;
                                    state <= eop_in ? IDLE : SKIP_PACKET;
                                end
                                default: begin end
                            endcase

                            if ((packet_byte_index == 8'd13) &&
                                ({ethertype_temp[15:8], data_in} != 16'h0800)) begin
                                state <= eop_in ? IDLE : SKIP_PACKET;
                            end else if (eop_in && (packet_byte_index < 8'd53)) begin
                                if (((packet_byte_index == 8'd23) &&
                                     (data_in == 8'd6)) ||
                                    ((packet_byte_index > 8'd23) &&
                                     (protocol_temp == 8'd6)))
                                    parser_error <= 1'b1;
                                state <= IDLE;
                            end

                            if (state == PARSE_FRAME)
                                packet_byte_index <= packet_byte_index + 8'd1;
                        end
                    end
                end

                SKIP_PACKET: begin
                    if (valid_in && eop_in) begin
                        state             <= IDLE;
                        packet_byte_index <= 8'd0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
