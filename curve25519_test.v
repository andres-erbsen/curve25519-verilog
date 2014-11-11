`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module curve25519_test;
    parameter N = 1;
    reg [$bits(N):0] i = 0;
    reg [254:0] ns [N:0];
    reg [254:0] qs [N:0];
    reg [254:0] outs [N:0];

    initial begin
        ns[0]   = 255'h4000000000000000000000000000000000000000000000000000000000000000;
        qs[0]   = 9; // the basepoint
        outs[0] = 255'h743bcb585f9990edc2cfc4af84f6ff300729bb5facda28154362cd47a37de52f;
    end

    wire [254:0] out;
    wire done;
    reg clock = 0, start = 1;
    curve25519 c(clock, start, ns[i], qs[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        // $display("%3d %x-%0d-%x: %d %d", $time/2, c.state, c.i, c.stage, c.sub_done, c.mul_ready);
        if (done) begin
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
endmodule
