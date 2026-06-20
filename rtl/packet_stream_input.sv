module packet_stream_input #(
    parameter MAX_PACKET_BYTES = 2048
)(
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

    output logic        in_packet,
    output logic        packet_done,
    output logic        packet_error,
    output logic [15:0] byte_count,
    output logic [15:0] last_packet_length
);

    typedef enum logic {
        IDLE,
        RECEIVE
    } state_t;

    state_t state;

    assign in_packet = (state == RECEIVE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= IDLE;

            data_out           <= 8'h00;
            valid_out          <= 1'b0;
            sop_out            <= 1'b0;
            eop_out            <= 1'b0;

            packet_done        <= 1'b0;
            packet_error       <= 1'b0;
            byte_count         <= 16'd0;
            last_packet_length <= 16'd0;
        end else begin
            // Default one-cycle pulse outputs
            packet_done  <= 1'b0;
            packet_error <= 1'b0;

            // Pass-through stream signals
            data_out  <= data_in;
            valid_out <= valid_in;
            sop_out   <= sop_in;
            eop_out   <= eop_in;

            case (state)

                IDLE: begin
                    byte_count <= 16'd0;

                    if (valid_in) begin
                        if (sop_in) begin
                            // Start receiving a new packet
                            if (eop_in) begin
                                // Single-byte packet
                                last_packet_length <= 16'd1;
                                packet_done        <= 1'b1;
                                state              <= IDLE;
                                byte_count         <= 16'd0;
                            end else begin
                                byte_count <= 16'd1;
                                state      <= RECEIVE;
                            end
                        end else begin
                            // Valid data appeared without start-of-packet
                            packet_error <= 1'b1;
                            state        <= IDLE;
                        end
                    end
                end

                RECEIVE: begin
                    if (valid_in) begin
                        if (sop_in) begin
                            // A new packet started before the previous one ended
                            packet_error <= 1'b1;
                            byte_count   <= 16'd1;
                            state        <= RECEIVE;
                        end else if (eop_in) begin
                            // End of packet
                            last_packet_length <= byte_count + 16'd1;
                            packet_done        <= 1'b1;
                            byte_count         <= 16'd0;
                            state              <= IDLE;
                        end else begin
                            // Normal packet byte
                            if (byte_count >= MAX_PACKET_BYTES) begin
                                packet_error <= 1'b1;
                                byte_count   <= 16'd0;
                                state        <= IDLE;
                            end else begin
                                byte_count <= byte_count + 16'd1;
                                state      <= RECEIVE;
                            end
                        end
                    end
                end

                default: begin
                    state      <= IDLE;
                    byte_count <= 16'd0;
                end

            endcase
        end
    end

endmodule