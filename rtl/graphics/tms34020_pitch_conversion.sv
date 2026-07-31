`timescale 1ns/1ps
`default_nettype none

module tms34020_pitch_conversion (
    input  logic [31:0] pitch_i,
    output logic [15:0] conversion_o,
    output logic [2:0]  visible_states_o
);

    integer bit_index;
    logic [5:0] set_bit_count;
    logic [4:0] lesser_power;
    logic [4:0] greater_power;
    logic [4:0] conversion_value_1;
    logic [4:0] conversion_value_2;

    always_comb begin
        set_bit_count = 6'd0;
        lesser_power = 5'd0;
        greater_power = 5'd0;

        for (bit_index = 32'd0;
             bit_index < 32'd32;
             bit_index = bit_index + 32'd1) begin
            if (pitch_i[bit_index]) begin
                if (set_bit_count == 6'd0) begin
                    lesser_power = bit_index[4:0];
                end else if (set_bit_count == 6'd1) begin
                    greater_power = bit_index[4:0];
                end
                set_bit_count = set_bit_count + 6'd1;
            end
        end

        conversion_value_1 = (~greater_power) & 5'h1F;
        conversion_value_2 = (~lesser_power) & 5'h1F;
        conversion_o = 16'd0;
        visible_states_o = 3'd3;

        if (set_bit_count == 6'd1) begin
            conversion_value_1 = (~lesser_power) & 5'h1F;
            if (conversion_value_1 != 5'd0) begin
                conversion_o = {11'd0, conversion_value_1};
                visible_states_o = 3'd4;
            end
        end else if (set_bit_count == 6'd2 &&
                     conversion_value_1 != 5'd0 &&
                     conversion_value_2 != 5'd0) begin
            conversion_o = {
                3'd0,
                conversion_value_2,
                3'd0,
                conversion_value_1
            };
            visible_states_o = 3'd6;
        end
    end

endmodule

`default_nettype wire
