`default_nettype none

module tms34020_xy_to_linear (
    input  logic [31:0] xy_i,
    input  logic [31:0] pitch_i,
    input  logic [31:0] offset_i,
    input  logic [4:0]  conversion_value_1_i,
    input  logic [4:0]  conversion_value_2_i,
    input  logic [15:0] pixel_size_i,
    input  logic        scale_x_by_pixel_size_i,
    input  logic        cvxyl_extra_state_i,
    output logic [31:0] linear_o,
    output logic [1:0]  pitch_class_o,
    output logic [3:0]  visible_states_o
);

    localparam logic [1:0] PITCH_POWER_OF_TWO = 2'd0;
    localparam logic [1:0] PITCH_TWO_POWERS = 2'd1;
    localparam logic [1:0] PITCH_ARBITRARY = 2'd2;

    logic signed [15:0] x_coordinate;
    logic signed [15:0] y_coordinate;
    logic signed [31:0] x_extended;
    logic signed [31:0] y_extended;
    logic signed [31:0] pitch_signed;
    logic signed [31:0] pixel_size_extended;
    logic signed [31:0] arbitrary_y_product;
    logic signed [31:0] scaled_x_product;
    logic [31:0] y_product;
    logic [31:0] x_product;
    logic [4:0] conversion_value_1;
    logic [4:0] conversion_value_2;
    logic [4:0] shift_1;
    logic [4:0] shift_2;

    always_comb begin
        x_coordinate = $signed(xy_i[15:0]);
        y_coordinate = $signed(xy_i[31:16]);
        x_extended = {{16{x_coordinate[15]}}, x_coordinate};
        y_extended = {{16{y_coordinate[15]}}, y_coordinate};
        pitch_signed = $signed(pitch_i);
        pixel_size_extended = $signed({16'd0, pixel_size_i});
        arbitrary_y_product = y_extended * pitch_signed;
        scaled_x_product = x_extended * pixel_size_extended;
        conversion_value_1 = conversion_value_1_i;
        conversion_value_2 = conversion_value_2_i;
        shift_1 = (~conversion_value_1) & 5'h1F;
        shift_2 = (~conversion_value_2) & 5'h1F;

        y_product = 32'd0;
        pitch_class_o = PITCH_ARBITRARY;
        visible_states_o = 4'd14;
        if (conversion_value_1 != 5'd0) begin
            y_product = y_extended <<< shift_1;
            pitch_class_o = PITCH_POWER_OF_TWO;
            visible_states_o = cvxyl_extra_state_i ? 4'd3 : 4'd2;
            if (conversion_value_2 != 5'd0) begin
                y_product = y_product + (y_extended <<< shift_2);
                pitch_class_o = PITCH_TWO_POWERS;
                visible_states_o = cvxyl_extra_state_i ? 4'd4 : 4'd3;
            end
        end else begin
            y_product = arbitrary_y_product;
        end

        x_product = scale_x_by_pixel_size_i
            ? scaled_x_product
            : x_extended;
        linear_o = y_product + x_product + offset_i;
    end

endmodule

`default_nettype wire
