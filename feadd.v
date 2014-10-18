`default_nettype none

module feadd(input wire clock, start,
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
    reg [LOGN-1:0] i = N;
    reg [254:0] out_, outP;
    reg wrapP = 0;
    reg carry = 0, carryP = 0;

    wire [W:0] partial  = carry + a[i*W +: W] + b[i*W +: W];
    wire [W:0] partialP = partial[W-1:0] - carryP - P[i*W +: W];

    always @ (posedge clock) begin
        if (start) begin
            i <= 0;
            {carry, carryP} <= 0;
            a <= a_in;
            b <= b_in;
        end else if (i < N) begin
            i <= i + 1;
            carry <= partial[W];
            carryP <= partialP[W];
            out_ <= {partial [W-1:0], out_[254:W]};
            outP <= {partialP[W-1:0], outP[254:W]};
            if (i == N-1) done <= 1;
            // we only want to use the non-reduced result if the reduction
            // overflowed and the main operation did not.
            if (i == N-1) wrapP <= ~(partialP[W] && !partial[W]);
        end else if (done) done <= 0;
    end
    assign out = wrapP ? outP : out_;
endmodule
