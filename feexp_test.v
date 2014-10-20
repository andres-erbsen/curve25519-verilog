`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module feexp_test;
    parameter N = 6;
    reg [$bits(N):0] i = 0;
    reg [254:0] as [N:0];
    reg [254:0] bs [N:0];
    reg [254:0] outs [N:0];

    initial begin
        as[0]   = 7;
        bs[0]   = 2;
        outs[0] = 49;

        as[1]   = (255'b1 << 128);
        bs[1]   = 2;
        outs[1] = 38;

        as[2]   = 2;
        bs[2]   = 254;
        outs[2] = (255'b1 << 254);

        as[3]   = 2;
        bs[3]   = 255;
        outs[3] = 19;

        as[4]   = 7;
        bs[4] = (255'b1 << 255) - 21;
        outs[4] = 255'h249249249249249249249249249249249249249249249249249249249249248d;

        as[5]   = 255'h1342d411f5508b2013297c21c1ec44e4c21cf6d8da8f3f0cf8e333d64614ad4d;
        bs[5]   = 255'h42ffa5e363133dab46c552c3ace4ffdd3c01ff6a72f09791922b63997b871740;
        outs[5] = 255'h21f3b3f38a7a8a6213ccf88adf7bf9c403185fe8624447d8c321512f10db69d7;
    end

    wire [254:0] out;
    wire done;
    reg clock = 0, start = 1;
    feexp feexp(clock, start, as[i], bs[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        if (done) begin
            $display("pow(0x%x, 0x%x, 2**255 - 19) == 0x%x", as[i], bs[i], out);
            `assert(out === outs[i])
            if (i < N-1) begin
                i <= i + 1;
                start <= 1;
            end else begin
                $finish;
            end
        end
        if (start) start <= 0;
    end

    // initial begin $monitor("0x%x", feexp.out); end
endmodule
