// =======================================================
// Module: fuel_estimator.v
// Purpose: Estimate total fuel usage based on velocity
// =======================================================
module fuel_estimator #(
    parameter integer K1 = 1,    // proportional constant
    parameter integer K2 = 1
)(
    input clk,
    input reset,
    input [31:0] velocity,
    output reg [63:0] total_fuel
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            total_fuel <= 0;
        else
            total_fuel <= total_fuel + (K1 * velocity + K2);
    end
endmodule
