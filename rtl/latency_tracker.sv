module latency_tracker #(
    parameter COUNTER_WIDTH = 16
) (
    input  logic                     clk,
    input  logic                     rst_n,

    input  logic                     sop_event,
    input  logic                     ethernet_event,
    input  logic                     ipv4_event,
    input  logic                     udp_event,
    input  logic                     classification_event,
    input  logic                     statistics_event,

    output logic                     measurement_active,
    output logic [COUNTER_WIDTH-1:0] ethernet_latency,
    output logic [COUNTER_WIDTH-1:0] ipv4_latency,
    output logic [COUNTER_WIDTH-1:0] udp_latency,
    output logic [COUNTER_WIDTH-1:0] classification_latency,
    output logic [COUNTER_WIDTH-1:0] statistics_latency,
    output logic                     ethernet_latency_valid,
    output logic                     ipv4_latency_valid,
    output logic                     udp_latency_valid,
    output logic                     classification_latency_valid,
    output logic                     statistics_latency_valid,
    output logic                     counter_overflow
);

    logic [COUNTER_WIDTH-1:0] cycle_count;
    logic [COUNTER_WIDTH-1:0] elapsed_count;

    // cycle_count is zero on the edge that accepts SOP. On every later active
    // edge, elapsed_count is the saturated number of rising-edge intervals
    // since SOP. An event coincident with SOP therefore records zero; an event
    // on the immediately following edge records one.
    always_comb begin
        if (&cycle_count)
            elapsed_count = cycle_count;
        else
            elapsed_count = cycle_count + {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            measurement_active           <= 1'b0;
            cycle_count                  <= '0;
            ethernet_latency             <= '0;
            ipv4_latency                 <= '0;
            udp_latency                  <= '0;
            classification_latency       <= '0;
            statistics_latency           <= '0;
            ethernet_latency_valid       <= 1'b0;
            ipv4_latency_valid           <= 1'b0;
            udp_latency_valid            <= 1'b0;
            classification_latency_valid <= 1'b0;
            statistics_latency_valid     <= 1'b0;
            counter_overflow             <= 1'b0;
        end else begin
            ethernet_latency_valid       <= 1'b0;
            ipv4_latency_valid           <= 1'b0;
            udp_latency_valid            <= 1'b0;
            classification_latency_valid <= 1'b0;
            statistics_latency_valid     <= 1'b0;

            if (sop_event) begin
                measurement_active <= !statistics_event;
                cycle_count        <= '0;
                counter_overflow   <= 1'b0;

                if (ethernet_event) begin
                    ethernet_latency       <= '0;
                    ethernet_latency_valid <= 1'b1;
                end
                if (ipv4_event) begin
                    ipv4_latency       <= '0;
                    ipv4_latency_valid <= 1'b1;
                end
                if (udp_event) begin
                    udp_latency       <= '0;
                    udp_latency_valid <= 1'b1;
                end
                if (classification_event) begin
                    classification_latency       <= '0;
                    classification_latency_valid <= 1'b1;
                end
                if (statistics_event) begin
                    statistics_latency       <= '0;
                    statistics_latency_valid <= 1'b1;
                end
            end else if (measurement_active) begin
                cycle_count <= elapsed_count;
                if (&cycle_count)
                    counter_overflow <= 1'b1;

                if (ethernet_event) begin
                    ethernet_latency       <= elapsed_count;
                    ethernet_latency_valid <= 1'b1;
                end
                if (ipv4_event) begin
                    ipv4_latency       <= elapsed_count;
                    ipv4_latency_valid <= 1'b1;
                end
                if (udp_event) begin
                    udp_latency       <= elapsed_count;
                    udp_latency_valid <= 1'b1;
                end
                if (classification_event) begin
                    classification_latency       <= elapsed_count;
                    classification_latency_valid <= 1'b1;
                end
                if (statistics_event) begin
                    statistics_latency       <= elapsed_count;
                    statistics_latency_valid <= 1'b1;
                    measurement_active       <= 1'b0;
                end
            end
        end
    end

endmodule
