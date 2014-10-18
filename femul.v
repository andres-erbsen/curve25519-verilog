`default_nettype none

module femul(input wire clock, start,
             input wire [254:0] a_in, b_in,
             output reg done = 0,
             output reg [254:0] out = 0);
    parameter W = 17; // hardware multiplier input word size
    parameter N = 15; // number of words used to represent one field element
    parameter C = 19; // pseudo-Mersenne coefficient; P = (1<<W*N) - C = 2^255 - 19
    parameter LOGC = 4;
    parameter LOGN = 4;

    reg [254:0] a = 0;
    reg [254:0] b = 0;
    reg [2*W + LOGN + LOGC - 1:0] mid [N-1:0];
    reg [LOGN-1:0] multiply_step = N;
    wire multiply_running = multiply_step < N;

    always @ (posedge clock) begin
        if (start) begin
            multiply_step <= 0;
            a <= a_in;
            b <= b_in;
        end else if (multiply_running) begin
            multiply_step <= multiply_step + 1;
            a <= {a, a[254 -: W]}; // XXX: rotation operators <<< and >>> DO NOT WORK?
            b <= {b[0 +: W], b[W +: 255-W]};
            if (multiply_step == N-1) reduce_step <= 0;
        end
    end

    genvar i; generate for (i = 0; i < N; i = i + 1) begin: mul_mid
        always @(posedge clock) begin
            if (start) mid[i] <= 0;
            else if (multiply_running) begin
                mid[i] <= /* if */ (i < multiply_step)
                    ? mid[i] + (b[0 +: W] * a[i*W +: W]) * C
                    : mid[i] + b[0 +: W] * a[i*W +: W];
            end
        end
    end endgenerate

    parameter R = 2; // number of high-order words where carry needs full reduction mod P
    parameter LOGR = 2;
    reg [LOGR+LOGN-1:0] reduce_step = N+R;
    reg [2*W + LOGN + LOGC - 1:0] carry = 0;
    wire reduce_running = reduce_step < R;
    wire [W-1:0] carry_out = carry + mid[reduce_step - R];
    always @ (posedge clock) begin
        if (reduce_step < N+R) begin
            reduce_step <= reduce_step + 1;
            if (reduce_step >= R) out <= {carry_out, out[254:W]};
            carry <= reduce_step == 0 ? carry <= mid[N-2] >> W:
                     reduce_step == 1 ? carry <= ((mid[N-1] + carry) >> W) * C:
                      /*otherwise*/    (carry + mid[reduce_step-R]) >> W;
        end
        if (reduce_step == N+R-1) done <= 1;
        else done <= 0;
    end
endmodule
