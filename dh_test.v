`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module curve25519_test;
    reg [254:0] a_seed, b_seed, a, b, A, B, shared_a, shared_b, base=9;

    initial begin
        a_seed={$random, $random, $random, $random, $random, $random, $random, $random};
        b_seed={$random, $random, $random, $random, $random, $random, $random, $random};
        a={1'b1, a_seed[3 +: 251], 3'b000};
        b={1'b1, b_seed[3 +: 251], 3'b000};
        $display("a = 0x%x", a);
        $display("b = 0x%x", b);
    end

    reg clock = 0, start = 0;
    reg [254:0] scalar, point;
    wire [254:0] out;
    wire done;
    curve25519 c(clock, start, scalar, point, done, out);
    always #1 clock <= !clock;

    reg [7:0] pc = 0;
    always @(posedge clock) begin
        if (start) start <= 0;
        if (pc == 0) begin
            start <= 1; scalar <= a; point <= base;
            pc <= pc+1;
        end
        if (pc == 1 && done) begin
            A <= out;
            $display("A = 0x%x", out);
            start <= 1; scalar <= b; point <= base;
            pc <= pc+1;
        end
        if (pc == 2 && done) begin
            B <= out;
            $display("B = 0x%x", out);
            start <= 1; scalar <= b; point <= A;
            pc <= pc+1;
        end
        if (pc == 3 && done) begin
            $display("shared_b = 0x%x", out);
            shared_b <= out;
            start <= 1; scalar <= a; point <= B;
            pc <= pc+1;
        end
        if (pc == 3 && done) begin
            $display("shared_a = 0x%x", out);
            shared_a <= out;
            pc <= pc+1;
        end
        if (pc == 4 && done) begin
            `assert(shared_a === shared_b)
            $finish;
        end
    end
endmodule
