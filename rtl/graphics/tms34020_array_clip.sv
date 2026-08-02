`default_nettype none

module tms34020_array_clip (
    input  logic [31:0] origin_i,
    input  logic [31:0] dimensions_i,
    input  logic [31:0] window_start_i,
    input  logic [31:0] window_end_i,
    output logic        geometry_valid_o,
    output logic        intersection_o,
    output logic [31:0] adjusted_origin_o,
    output logic [31:0] adjusted_dimensions_o,
    output logic        status_z_o,
    output logic        status_v_o
);

    logic signed [15:0] origin_x;
    logic signed [15:0] origin_y;
    logic signed [15:0] window_start_x;
    logic signed [15:0] window_start_y;
    logic signed [15:0] window_end_x;
    logic signed [15:0] window_end_y;
    logic signed [17:0] origin_x_extended;
    logic signed [17:0] origin_y_extended;
    logic signed [17:0] window_start_x_extended;
    logic signed [17:0] window_start_y_extended;
    logic signed [17:0] window_end_x_extended;
    logic signed [17:0] window_end_y_extended;
    logic [15:0] width;
    logic [15:0] height;
    logic signed [17:0] array_end_x;
    logic signed [17:0] array_end_y;
    logic signed [17:0] clipped_start_x;
    logic signed [17:0] clipped_start_y;
    logic signed [17:0] clipped_end_x;
    logic signed [17:0] clipped_end_y;
    logic [17:0] clipped_width;
    logic [17:0] clipped_height;
    logic no_intersection;
    logic any_outside;

    always_comb begin
        origin_x = $signed(origin_i[15:0]);
        origin_y = $signed(origin_i[31:16]);
        window_start_x = $signed(window_start_i[15:0]);
        window_start_y = $signed(window_start_i[31:16]);
        window_end_x = $signed(window_end_i[15:0]);
        window_end_y = $signed(window_end_i[31:16]);
        origin_x_extended = {{2{origin_x[15]}}, origin_x};
        origin_y_extended = {{2{origin_y[15]}}, origin_y};
        window_start_x_extended = {
            {2{window_start_x[15]}}, window_start_x
        };
        window_start_y_extended = {
            {2{window_start_y[15]}}, window_start_y
        };
        window_end_x_extended = {{2{window_end_x[15]}}, window_end_x};
        window_end_y_extended = {{2{window_end_y[15]}}, window_end_y};
        width = dimensions_i[15:0];
        height = dimensions_i[31:16];

        geometry_valid_o =
            (width != 16'd0) &&
            (height != 16'd0) &&
            (window_start_x <= window_end_x) &&
            (window_start_y <= window_end_y);
        array_end_x = origin_x_extended +
            $signed({1'b0, width}) - 18'sd1;
        array_end_y = origin_y_extended +
            $signed({1'b0, height}) - 18'sd1;
        clipped_start_x =
            (origin_x_extended > window_start_x_extended) ?
            origin_x_extended : window_start_x_extended;
        clipped_start_y =
            (origin_y_extended > window_start_y_extended) ?
            origin_y_extended : window_start_y_extended;
        clipped_end_x =
            (array_end_x < window_end_x_extended) ?
            array_end_x : window_end_x_extended;
        clipped_end_y =
            (array_end_y < window_end_y_extended) ?
            array_end_y : window_end_y_extended;
        no_intersection =
            (clipped_start_x > clipped_end_x) ||
            (clipped_start_y > clipped_end_y);
        any_outside =
            (origin_x < window_start_x) ||
            (origin_y < window_start_y) ||
            (array_end_x > window_end_x_extended) ||
            (array_end_y > window_end_y_extended);
        clipped_width =
            $unsigned(clipped_end_x - clipped_start_x) + 18'd1;
        clipped_height =
            $unsigned(clipped_end_y - clipped_start_y) + 18'd1;

        intersection_o =
            geometry_valid_o &&
            !no_intersection &&
            (clipped_width[17:16] == 2'd0) &&
            (clipped_height[17:16] == 2'd0);
        adjusted_origin_o = origin_i;
        adjusted_dimensions_o = dimensions_i;
        status_z_o = 1'b0;
        status_v_o = 1'b0;
        if (geometry_valid_o) begin
            status_z_o = no_intersection;
            status_v_o = any_outside;
            if (!no_intersection) begin
                adjusted_origin_o = {
                    clipped_start_y[15:0], clipped_start_x[15:0]
                };
                adjusted_dimensions_o = {
                    clipped_height[15:0], clipped_width[15:0]
                };
            end
        end
    end

endmodule

`default_nettype wire
