// =======================================================
// Module: position_reg.v
// Purpose: Register current and previous positions
// =======================================================
module position_reg(
    input clk,
    input reset,
    input [15:0] position_in,
    output reg [15:0] pos_curr,
    output reg [15:0] pos_prev
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pos_curr <= 16'd0;
            pos_prev <= 16'd0;
        end else begin
            pos_prev <= pos_curr;
            pos_curr <= position_in;
        end
    end
endmodule
