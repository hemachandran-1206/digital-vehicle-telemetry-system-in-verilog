// =======================================================
// Module: alert_unit.v
// Purpose: Raise alerts for overspeed and harsh braking
// =======================================================
module alert_unit(
    input [15:0] velocity,
    input signed [15:0] acceleration,
    output reg [1:0] alert_flags
);
    parameter OVERSPEED_LIMIT = 16'd100;
    parameter BRAKE_LIMIT     = -16'sd20;

    reg overspeed;
    reg harsh_brake;

    always @(*) begin
        overspeed   = (velocity > OVERSPEED_LIMIT);
        harsh_brake = (acceleration < BRAKE_LIMIT);
        alert_flags = {overspeed, harsh_brake};
    end
endmodule
