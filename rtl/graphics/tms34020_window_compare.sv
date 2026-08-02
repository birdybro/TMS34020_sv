`default_nettype none

module tms34020_window_compare (
    input  logic [31:0] point_i,
    input  logic [31:0] window_start_i,
    input  logic [31:0] window_end_i,
    output logic [31:0] outcode_o,
    output logic        outside_o
);

    logic signed [15:0] point_x;
    logic signed [15:0] point_y;
    logic signed [15:0] start_x;
    logic signed [15:0] start_y;
    logic signed [15:0] end_x;
    logic signed [15:0] end_y;

    always_comb begin
        point_x = $signed(point_i[15:0]);
        point_y = $signed(point_i[31:16]);
        start_x = $signed(window_start_i[15:0]);
        start_y = $signed(window_start_i[31:16]);
        end_x = $signed(window_end_i[15:0]);
        end_y = $signed(window_end_i[31:16]);

        outcode_o = 32'd0;
        outcode_o[5] = start_x > point_x;
        outcode_o[6] = point_x > end_x;
        outcode_o[7] = start_y > point_y;
        outcode_o[8] = point_y > end_y;
        outside_o = |outcode_o[8:5];
    end

endmodule

`default_nettype wire
