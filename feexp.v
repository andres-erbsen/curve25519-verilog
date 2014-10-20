`default_nettype none

module feexp(input wire clock, start,
             input wire [254:0] x, e,
             output reg done = 0,
             output reg [254:0] out);
    reg [7:0] i = 0;
    reg square = 0, mult_start = 0;
    wire mult_done;
    wire [254:0] mult_out;
    femul femul(.clock(clock), .start(mult_start),
        .a_in(out), .b_in(square ? out : x), .done(mult_done), .out(mult_out));
    always @(posedge clock) begin
        if (start) begin
            i <= 255;
            out <= 1;
            square <= 0;
            mult_start <= 1;
        end else if (mult_done) begin
            if (square || e[i]) out <= mult_out;
            if (i == 0 && !square) done <= 1;
            else if (!square) i <= i-1;
            square <= !square;
            if (i != 0 || square) mult_start <= 1;
        end
        if (done) done <= 0;
        if (mult_start) mult_start <= 0;
    end
endmodule

