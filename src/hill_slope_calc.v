// =======================================================
// Module: hill_slope_calc.v
// Purpose: Simulate slope (uphill/downhill) impact on acceleration
// =======================================================
module hill_slope_calc #(
    parameter signed [15:0] SLOPE_FACTOR = 16'sd1
)(
    input  signed [31:0] acceleration_in,
    input  signed [15:0] slope_angle,
    output reg   signed [31:0] acceleration_out
);
    always @(*) begin
        // Uphill reduces acceleration, downhill increases it
        acceleration_out = acceleration_in - (slope_angle * SLOPE_FACTOR);
    end
endmodule
