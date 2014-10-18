`default_nettype none

module femul(input wire clock, start,
             input wire [254:0] a_in, b_in,
             output reg done = 0,
             output wire [254:0] out);
    parameter W = 17; // hardware multiplier input word size
    parameter N = 15; // number of words used to represent one field element
    parameter C = 19; // pseudo-Mersenne coefficient
    parameter P = (255'b1<<(N*W)) - C; // 2^255 - 19
    parameter LOGC = 4;
    parameter LOGN = 4;

    reg [254:0] a = 0;
    reg [254:0] b = 0;
    reg [2*W + LOGN + LOGC - 1:0] mid [N-1:0];
    reg [LOGN-1:0] multiply_step = N;

    always @ (posedge clock) begin
        if (start) begin
            multiply_step <= 0;
            a <= a_in;
            b <= b_in;
        end else if (multiply_step < N) begin
            multiply_step <= multiply_step + 1;
            a <= {a[0 +: N*W-W], a[254 -: W]}; // XXX: rotation operators <<< and >>> DO NOT WORK?
            b <= {b[0 +: W], b[W +: 255-W]};
            if (multiply_step == N-1) reduce_step <= 0;
        end
    end

    genvar j; generate for (j = 0; j < N; j = j + 1) begin: mul_mid
        always @(posedge clock) begin
            `define partial (b[0 +: W] * a[j*W +: W])
            mid[j] <=                multiply_step == 0?          `partial     :
                j < multiply_step && multiply_step < N ? mid[j] + `partial * C : 
                                     multiply_step < N ? mid[j] + `partial     :
                                      /* otherwise */    mid[j]                ;
            `undef partial
        end
    end endgenerate

    parameter R = 2; // number of high-order words where carry needs full reduction mod P
    parameter LOGR = 2;
    reg [LOGR+LOGN-1:0] reduce_step = N+R;
    reg [2*W + LOGN + LOGC - 1:0] carry = 0, carryP = 0;
    reg [254:0] out_, outP; // two options for the output: r, and r-P
    reg wrapP = 0;

    wire [2*W + LOGN + LOGC - 1:0] partial, partialP, carry_next, carryP_next;
    wire [LOGN-1:0] i = reduce_step == 0 ? N-2: 
                        reduce_step == 1 ? N-1:
                                           reduce_step-R;
    assign partial  = carry  + mid[i];
    assign partialP = carryP + mid[i] - P[i*W +: W];
    assign carry_next  = reduce_step == 0 ?  mid[i]   >> W:
                         reduce_step == 1 ? (partial  >> W) * C:
                          /*otherwise*/      partial  >> W;
    assign carryP_next = reduce_step == 0 ?  mid[i]   >> W:
                         reduce_step == 1 ? (partial  >> W) * C:
                          /*otherwise*/      partialP >> W;
    always @ (posedge clock) begin
        if (reduce_step < N+R) begin
            reduce_step <= reduce_step + 1;
            if (reduce_step >= R) out_ <= {partial [W-1:0],  out[254:W]};
            if (reduce_step >= R) outP <= {partialP[W-1:0], outP[254:W]};
            carry <= carry_next;
            carryP <= carryP_next;
        end
        if (reduce_step == N+R-1) begin
            done <= 1;
            wrapP <= ~|carryP_next;
        end else done <= 0;
    end
    assign out = wrapP ? outP : out_;
endmodule
