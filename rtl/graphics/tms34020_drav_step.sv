`default_nettype none

module tms34020_drav_step (
    input  logic [31:0] source_xy_i,
    input  logic [31:0] destination_xy_i,
    input  logic [31:0] linear_address_i,
    input  logic [31:0] color1_i,
    input  logic [31:0] pmask_i,
    input  logic [31:0] raw_destination_i,
    input  logic [15:0] psize_i,
    output logic        inputs_valid_o,
    output logic [31:0] access_address_o,
    output logic [31:0] source_pixel_o,
    output logic [31:0] plane_mask_o,
    output logic [31:0] result_pixel_o,
    output logic [31:0] next_destination_xy_o
);

    logic legal_psize;
    logic [31:0] psize_extended;
    logic [31:0] pixel_width_mask;
    logic [5:0] lane_end;
    logic address_aligned;
    logic lane_fits;

    always_comb begin
        legal_psize =
            (psize_i == 16'd1) ||
            (psize_i == 16'd2) ||
            (psize_i == 16'd4) ||
            (psize_i == 16'd8) ||
            (psize_i == 16'd16) ||
            (psize_i == 16'd32);
        psize_extended = {16'd0, psize_i};
        case (psize_i)
            16'd1: pixel_width_mask = 32'h0000_0001;
            16'd2: pixel_width_mask = 32'h0000_0003;
            16'd4: pixel_width_mask = 32'h0000_000F;
            16'd8: pixel_width_mask = 32'h0000_00FF;
            16'd16: pixel_width_mask = 32'h0000_FFFF;
            16'd32: pixel_width_mask = 32'hFFFF_FFFF;
            default: pixel_width_mask = 32'd0;
        endcase

        lane_end = {1'b0, linear_address_i[4:0]} + psize_i[5:0];
        address_aligned =
            (linear_address_i & (psize_extended - 32'd1)) == 32'd0;
        lane_fits = lane_end <= 6'd32;
        inputs_valid_o = legal_psize && address_aligned && lane_fits;
        access_address_o = linear_address_i;
        source_pixel_o =
            (color1_i >> linear_address_i[4:0]) & pixel_width_mask;
        plane_mask_o =
            (pmask_i >> linear_address_i[4:0]) & pixel_width_mask;
        result_pixel_o =
            (raw_destination_i & plane_mask_o) |
            (source_pixel_o & (~plane_mask_o & pixel_width_mask));
        next_destination_xy_o = {
            destination_xy_i[31:16] + source_xy_i[31:16],
            destination_xy_i[15:0] + source_xy_i[15:0]
        };
    end

endmodule

`default_nettype wire
