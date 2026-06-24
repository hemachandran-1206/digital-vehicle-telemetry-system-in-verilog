// =======================================================
// Module: velocity_calc.v
// Purpose: Compute velocity from delta position
// =======================================================
module velocity_calc #(
    parameter integer TIME_STEP = 10
)(
    input clk,
    input reset,
    input [15:0] delta_pos,
    output reg [15:0] velocity,
    output reg [15:0] vel_prev
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            velocity <= 16'd0;
            vel_prev <= 16'd0;
        end else begin
            vel_prev <= velocity;
            velocity <= delta_pos / TIME_STEP;
        end
    end
endmodule
