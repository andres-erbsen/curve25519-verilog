`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module curve25519_mock_test;
    parameter N = 4;
    reg [$bits(N):0] i = 0;
    reg [254:0] ns [N:0];
    reg [254:0] qs [N:0];
    reg [254:0] outs [N:0];

    initial begin
        ns[0]   = 255'h4000000000000000000000000000000000000000000000000000000000000000;
        qs[0]   = 9; // the basepoint
        outs[0] = 255'h743bcb585f9990edc2cfc4af84f6ff300729bb5facda28154362cd47a37de52f;

        ns[1]   = 255'h4002030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20;
        qs[1]   = 9; // the basepoint
        outs[1] = 255'h71850c3f2cd59eac742ceea75fc37c5de912aded47b366629169d381bb9dfba6;

        ns[2]   = 255'h4002030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20;
        qs[2]   = 255'h71850c3f2cd59eac742ceea75fc37c5de912aded47b366629169d381bb9dfba6;
        outs[2] = 255'h45dbaa45916a837457fdbda08bea49dbaabc29c65668ef235c7ae49a90375b54;

        ns[3]   = 255'h1234;
        qs[3]   = 255'h5678;
        outs[3] = 255'h5678;
    end

    wire [254:0] out;
    wire done;
    reg clock = 0, start = 1;
    curve25519_mock c(clock, start, ns[i], qs[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        // $display("%3d %x-%0d-%x: %d %d", $time/2, c.state, c.i, c.stage, c.sub_done, c.mul_ready);
        if (done) begin
            $display("0x%x == 0x%x", out, outs[i]);
            `assert(out === outs[i])
            if (i==0) $display("%d cycles / curve25519", $time/2);
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
