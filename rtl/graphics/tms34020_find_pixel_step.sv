`default_nettype none

module tms34020_find_pixel_step (
    input  logic        equal_mode_i,
    input  logic [31:0] maddr_i,
    input  logic [31:0] mptch_i,
    input  logic [15:0] psize_i,
    input  logic [31:0] color0_i,
    input  logic [31:0] pmask_i,
    input  logic [31:0] raw_pixel_i,
    output logic        inputs_valid_o,
    output logic        active_o,
    output logic        predecrement_o,
    output logic [31:0] access_address_o,
    output logic [31:0] masked_pixel_o,
    output logic [31:0] comparison_pixel_o,
    output logic        found_o,
    output logic [31:0] next_maddr_o,
    output logic [31:0] next_mptch_o,
    output logic        done_o,
    output logic        status_z_o
);

    logic legal_psize;
    logic [31:0] psize_extended;
    logic [31:0] pixel_width_mask;
    logic [31:0] lane_plane_mask;
    logic [5:0] lane_end;
    logic address_aligned;
    logic lane_fits;
    logic pixels_equal;

    always_comb begin
        legal_psize =
            (psize_i == 16'd1) ||
            (psize_i == 16'd2) ||
            (psize_i == 16'd4) ||
            (psize_i == 16'd8) ||
            (psize_i == 16'd16) ||
            (psize_i == 16'd32);
        psize_extended = {16'd0, psize_i};
        predecrement_o = mptch_i[31] && (mptch_i != 32'd0);
        access_address_o = predecrement_o ?
            (maddr_i - psize_extended) : maddr_i;

        case (psize_i)
            16'd1: pixel_width_mask = 32'h0000_0001;
            16'd2: pixel_width_mask = 32'h0000_0003;
            16'd4: pixel_width_mask = 32'h0000_000F;
            16'd8: pixel_width_mask = 32'h0000_00FF;
            16'd16: pixel_width_mask = 32'h0000_FFFF;
            16'd32: pixel_width_mask = 32'hFFFF_FFFF;
            default: pixel_width_mask = 32'd0;
        endcase
        lane_end = {1'b0, access_address_o[4:0]} + psize_i[5:0];
        address_aligned =
            (access_address_o & (psize_extended - 32'd1)) == 32'd0;
        lane_fits = lane_end <= 6'd32;
        inputs_valid_o = legal_psize && address_aligned && lane_fits;
        active_o = inputs_valid_o && (mptch_i != 32'd0);

        lane_plane_mask =
            (pmask_i >> access_address_o[4:0]) & pixel_width_mask;
        masked_pixel_o =
            (raw_pixel_i & pixel_width_mask) & ~lane_plane_mask;
        comparison_pixel_o =
            (color0_i >> access_address_o[4:0]) & pixel_width_mask;
        pixels_equal = masked_pixel_o == comparison_pixel_o;
        found_o = active_o &&
            (equal_mode_i ? pixels_equal : !pixels_equal);

        next_maddr_o = maddr_i;
        next_mptch_o = mptch_i;
        if (active_o) begin
            if (predecrement_o) begin
                next_maddr_o = access_address_o;
                next_mptch_o = mptch_i + 32'd1;
            end else begin
                next_maddr_o = maddr_i + psize_extended;
                next_mptch_o = mptch_i - 32'd1;
            end
        end
        done_o = inputs_valid_o &&
            (!active_o || found_o || (next_mptch_o == 32'd0));
        status_z_o = found_o;
    end

endmodule

`default_nettype wire
