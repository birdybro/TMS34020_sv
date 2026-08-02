`default_nettype none

module tms34020_fline_step (
    input  logic        algorithm_one_i,
    input  logic [31:0] decision_i,
    input  logic [31:0] daddr_i,
    input  logic [31:0] count_i,
    input  logic [31:0] dimensions_i,
    input  logic [31:0] inc1_linear_i,
    input  logic [31:0] inc2_linear_i,
    input  logic [31:0] pattern_i,
    input  logic [31:0] color0_i,
    input  logic [31:0] color1_i,
    input  logic [31:0] pmask_i,
    input  logic [31:0] raw_destination_i,
    input  logic [15:0] psize_i,
    output logic        inputs_valid_o,
    output logic        active_o,
    output logic        diagonal_o,
    output logic [31:0] access_address_o,
    output logic [31:0] source_pixel_o,
    output logic [31:0] plane_mask_o,
    output logic [31:0] result_pixel_o,
    output logic [31:0] next_decision_o,
    output logic [31:0] next_daddr_o,
    output logic [31:0] next_count_o,
    output logic [31:0] next_pattern_o,
    output logic        done_o
);

    logic legal_psize;
    logic [31:0] psize_extended;
    logic [31:0] pixel_width_mask;
    logic [31:0] source_word;
    logic [31:0] minor_twice;
    logic [31:0] major_twice;
    logic [5:0] lane_end;
    logic address_aligned;
    logic lane_fits;
    logic count_positive;
    logic decision_nonnegative;
    logic decision_positive;

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

        lane_end = {1'b0, daddr_i[4:0]} + psize_i[5:0];
        address_aligned =
            (daddr_i & (psize_extended - 32'd1)) == 32'd0;
        lane_fits = lane_end <= 6'd32;
        inputs_valid_o = legal_psize && address_aligned && lane_fits;
        count_positive = $signed(count_i) > 0;
        active_o = inputs_valid_o && count_positive;
        decision_nonnegative = !decision_i[31];
        decision_positive = decision_nonnegative && (decision_i != 32'd0);
        diagonal_o = active_o &&
            (algorithm_one_i ? decision_positive : decision_nonnegative);

        access_address_o = daddr_i;
        source_word = pattern_i[0] ? color1_i : color0_i;
        source_pixel_o =
            (source_word >> daddr_i[4:0]) & pixel_width_mask;
        plane_mask_o =
            (pmask_i >> daddr_i[4:0]) & pixel_width_mask;
        result_pixel_o =
            (raw_destination_i & plane_mask_o) |
            (source_pixel_o & (~plane_mask_o & pixel_width_mask));

        minor_twice = {15'd0, dimensions_i[31:16], 1'b0};
        major_twice = {15'd0, dimensions_i[15:0], 1'b0};
        next_decision_o = decision_i;
        next_daddr_o = daddr_i;
        next_count_o = count_i;
        next_pattern_o = pattern_i;
        if (active_o) begin
            next_count_o = count_i - 32'd1;
            next_pattern_o = {pattern_i[0], pattern_i[31:1]};
            if (diagonal_o) begin
                next_decision_o =
                    decision_i + minor_twice - major_twice;
                next_daddr_o = daddr_i + inc1_linear_i;
            end else begin
                next_decision_o = decision_i + minor_twice;
                next_daddr_o = daddr_i + inc2_linear_i;
            end
        end
        done_o = inputs_valid_o &&
            (!active_o || (next_count_o == 32'd0));
    end

endmodule

`default_nettype wire
