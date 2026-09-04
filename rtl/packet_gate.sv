module packet_gate #(
    parameter BUFFER_DEPTH = 256,
    parameter INDEX_WIDTH  = $clog2(BUFFER_DEPTH)
) (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [7:0] data_in,
    input  logic       valid_in,
    output logic       in_ready,
    input  logic       sop_in,
    input  logic       eop_in,

    input  logic       decision_valid,
    input  logic       allow_packet,

    output logic [7:0] data_out,
    output logic       valid_out,
    input  logic       out_ready,
    output logic       sop_out,
    output logic       eop_out,

    output logic       overflow_error
);

    typedef enum logic [1:0] {
        CAPTURE,
        WAIT_DECISION,
        FORWARD,
        DISCARD_OVERFLOW
    } state_t;
    state_t state;

    logic [7:0] buffer [0:BUFFER_DEPTH-1];
    logic [INDEX_WIDTH-1:0] write_index;
    logic [INDEX_WIDTH-1:0] read_index;
    logic [INDEX_WIDTH:0] packet_length;
    logic decision_seen;
    logic decision_allow;

    wire ingress_fire = valid_in && in_ready;
    wire egress_fire  = valid_out && out_ready;

    always_comb begin
        in_ready = ((state == CAPTURE) &&
                    (packet_length < BUFFER_DEPTH[INDEX_WIDTH:0])) ||
                   (state == DISCARD_OVERFLOW);
        valid_out = (state == FORWARD);
        data_out = buffer[read_index];
        sop_out = valid_out && (read_index == {INDEX_WIDTH{1'b0}});
        eop_out = valid_out && ({1'b0, read_index} == (packet_length - 1'b1));
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= CAPTURE;
            write_index    <= '0;
            read_index     <= '0;
            packet_length  <= '0;
            decision_seen  <= 1'b0;
            decision_allow <= 1'b0;
            overflow_error <= 1'b0;
        end else begin
            if (decision_valid && ((state == CAPTURE) ||
                                   (state == WAIT_DECISION))) begin
                decision_seen  <= 1'b1;
                decision_allow <= allow_packet;
            end

            case (state)
                CAPTURE: begin
                    if (valid_in && !in_ready)
                        overflow_error <= 1'b1;

                    if (ingress_fire) begin
                        buffer[write_index] <= data_in;
                        write_index         <= write_index + 1'b1;
                        packet_length       <= packet_length + 1'b1;

                        if (!eop_in &&
                            (packet_length == (BUFFER_DEPTH - 1))) begin
                            overflow_error <= 1'b1;
                            write_index    <= '0;
                            packet_length  <= '0;
                            decision_seen  <= 1'b0;
                            decision_allow <= 1'b0;
                            state          <= DISCARD_OVERFLOW;
                        end else if (eop_in) begin
                            read_index <= '0;
                            if (decision_valid ? allow_packet :
                                (decision_seen && decision_allow)) begin
                                state <= FORWARD;
                            end else if (decision_valid || decision_seen) begin
                                state          <= CAPTURE;
                                write_index    <= '0;
                                packet_length  <= '0;
                                decision_seen  <= 1'b0;
                                decision_allow <= 1'b0;
                            end else begin
                                state <= WAIT_DECISION;
                            end
                        end
                    end
                end

                WAIT_DECISION: begin
                    if (decision_valid) begin
                        if (allow_packet) begin
                            read_index <= '0;
                            state      <= FORWARD;
                        end else begin
                            state          <= CAPTURE;
                            write_index    <= '0;
                            packet_length  <= '0;
                            decision_seen  <= 1'b0;
                            decision_allow <= 1'b0;
                        end
                    end
                end

                FORWARD: begin
                    if (egress_fire) begin
                        if ({1'b0, read_index} == (packet_length - 1'b1)) begin
                            state          <= CAPTURE;
                            write_index    <= '0;
                            read_index     <= '0;
                            packet_length  <= '0;
                            decision_seen  <= 1'b0;
                            decision_allow <= 1'b0;
                        end else begin
                            read_index <= read_index + 1'b1;
                        end
                    end
                end

                DISCARD_OVERFLOW: begin
                    if (ingress_fire && eop_in)
                        state <= CAPTURE;
                end

                default: begin
                    state          <= CAPTURE;
                    write_index    <= '0;
                    read_index     <= '0;
                    packet_length  <= '0;
                    decision_seen  <= 1'b0;
                    decision_allow <= 1'b0;
                end
            endcase
        end
    end

endmodule
