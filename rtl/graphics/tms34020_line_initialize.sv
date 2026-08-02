`default_nettype none

module tms34020_line_initialize (
    input  logic [31:0] start_point_i,
    input  logic [31:0] end_point_i,
    input  logic [31:0] window_start_i,
    input  logic [31:0] window_end_i,
    output logic [31:0] decision_variable_o,
    output logic [31:0] dimensions_o,
    output logic [31:0] count_o,
    output logic [31:0] diagonal_increment_o,
    output logic [31:0] dominant_increment_o,
    output logic [3:0]  status_nczv_o,
    output logic [3:0]  visible_states_o
);

    logic signed [15:0] start_x;
    logic signed [15:0] start_y;
    logic signed [15:0] end_x;
    logic signed [15:0] end_y;
    logic signed [15:0] window_start_x;
    logic signed [15:0] window_start_y;
    logic signed [15:0] window_end_x;
    logic signed [15:0] window_end_y;
    logic signed [16:0] delta_x;
    logic signed [16:0] delta_y;
    logic [16:0] extent_x;
    logic [16:0] extent_y;
    logic [16:0] major_axis;
    logic [16:0] minor_axis;
    logic signed [15:0] step_x;
    logic signed [15:0] step_y;
    logic signed [17:0] decision;
    logic [3:0] start_outcode;
    logic [3:0] end_outcode;

    always_comb begin
        start_x = $signed(start_point_i[15:0]);
        start_y = $signed(start_point_i[31:16]);
        end_x = $signed(end_point_i[15:0]);
        end_y = $signed(end_point_i[31:16]);
        window_start_x = $signed(window_start_i[15:0]);
        window_start_y = $signed(window_start_i[31:16]);
        window_end_x = $signed(window_end_i[15:0]);
        window_end_y = $signed(window_end_i[31:16]);

        delta_x = {end_x[15], end_x} - {start_x[15], start_x};
        delta_y = {end_y[15], end_y} - {start_y[15], start_y};
        extent_x = delta_x[16] ? (~delta_x) + 17'd1 : delta_x;
        extent_y = delta_y[16] ? (~delta_y) + 17'd1 : delta_y;
        if (extent_x >= extent_y) begin
            major_axis = extent_x;
            minor_axis = extent_y;
        end else begin
            major_axis = extent_y;
            minor_axis = extent_x;
        end

        step_x = 16'sd0;
        if (delta_x < 0) begin
            step_x = -16'sd1;
        end else if (delta_x > 0) begin
            step_x = 16'sd1;
        end
        step_y = 16'sd0;
        if (delta_y < 0) begin
            step_y = -16'sd1;
        end else if (delta_y > 0) begin
            step_y = 16'sd1;
        end

        decision = ($signed({1'b0, minor_axis}) <<< 1) -
            $signed({1'b0, major_axis});
        decision_variable_o = {{14{decision[17]}}, decision};
        dimensions_o = {minor_axis[15:0], major_axis[15:0]};
        count_o = {15'd0, major_axis} + 32'd1;
        diagonal_increment_o = {step_y, step_x};
        if (extent_x >= extent_y) begin
            dominant_increment_o = {16'd0, step_x};
        end else begin
            dominant_increment_o = {step_y, 16'd0};
        end

        start_outcode = 4'd0;
        start_outcode[0] = start_x < window_start_x;
        start_outcode[1] = start_x > window_end_x;
        start_outcode[2] = start_y < window_start_y;
        start_outcode[3] = start_y > window_end_y;
        end_outcode = 4'd0;
        end_outcode[0] = end_x < window_start_x;
        end_outcode[1] = end_x > window_end_x;
        end_outcode[2] = end_y < window_start_y;
        end_outcode[3] = end_y > window_end_y;
        status_nczv_o = {
            start_x == end_x,
            |(start_outcode & end_outcode),
            start_y == end_y,
            |(start_outcode | end_outcode)
        };
        visible_states_o = 4'd9;
    end

endmodule

`default_nettype wire
