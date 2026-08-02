`default_nettype none

module tms34020_fill_step (
    input  logic [31:0] current_address_i,
    input  logic [31:0] row_start_i,
    input  logic [31:0] dptch_i,
    input  logic [15:0] columns_remaining_i,
    input  logic [15:0] rows_remaining_i,
    input  logic [15:0] row_width_i,
    input  logic [31:0] color1_i,
    input  logic [31:0] pmask_i,
    input  logic [31:0] raw_destination_i,
    input  logic [15:0] psize_i,
    output logic        inputs_valid_o,
    output logic        active_o,
    output logic [31:0] access_address_o,
    output logic [31:0] source_pixel_o,
    output logic [31:0] plane_mask_o,
    output logic [31:0] result_pixel_o,
    output logic [31:0] next_address_o,
    output logic [31:0] next_row_start_o,
    output logic [15:0] next_columns_remaining_o,
    output logic [15:0] next_rows_remaining_o,
    output logic        done_o
);

    logic legal_psize;
    logic [31:0] psize_extended;
    logic [31:0] pixel_width_mask;
    logic [5:0] lane_end;
    logic address_aligned;
    logic lane_fits;
    logic counters_valid;

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

        active_o =
            (columns_remaining_i != 16'd0) &&
            (rows_remaining_i != 16'd0);
        counters_valid = !active_o ||
            ((row_width_i != 16'd0) &&
             (columns_remaining_i <= row_width_i));
        lane_end = {1'b0, current_address_i[4:0]} + psize_i[5:0];
        address_aligned =
            (current_address_i & (psize_extended - 32'd1)) == 32'd0;
        lane_fits = lane_end <= 6'd32;
        inputs_valid_o = legal_psize && counters_valid &&
            (!active_o || (address_aligned && lane_fits));

        access_address_o = current_address_i;
        source_pixel_o =
            (color1_i >> current_address_i[4:0]) & pixel_width_mask;
        plane_mask_o =
            (pmask_i >> current_address_i[4:0]) & pixel_width_mask;
        result_pixel_o =
            (raw_destination_i & plane_mask_o) |
            (source_pixel_o & (~plane_mask_o & pixel_width_mask));

        next_address_o = current_address_i;
        next_row_start_o = row_start_i;
        next_columns_remaining_o = columns_remaining_i;
        next_rows_remaining_o = rows_remaining_i;
        done_o = !active_o;
        if (active_o && inputs_valid_o) begin
            if (columns_remaining_i == 16'd1) begin
                next_row_start_o = row_start_i + dptch_i;
                next_address_o = row_start_i + dptch_i;
                next_rows_remaining_o = rows_remaining_i - 16'd1;
                if (rows_remaining_i == 16'd1) begin
                    next_columns_remaining_o = 16'd0;
                    done_o = 1'b1;
                end else begin
                    next_columns_remaining_o = row_width_i;
                    done_o = 1'b0;
                end
            end else begin
                next_address_o = current_address_i + psize_extended;
                next_columns_remaining_o = columns_remaining_i - 16'd1;
                done_o = 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
