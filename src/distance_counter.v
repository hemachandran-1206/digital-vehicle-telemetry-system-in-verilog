// =======================================================
// Module: distance_counter.v
// Purpose: Compute total distance from position deltas
// =======================================================
module distance_counter(
    input clk,
    input reset,
    input [15:0] delta_pos,
    output reg [31:0] distance
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            distance <= 32'd0;
        else
            distance <= distance + ((delta_pos < 0) ? -delta_pos : delta_pos);
    end
endmodule
