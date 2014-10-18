`default_nettype none

module femul_test;
    reg clock = 0, start = 0;
    reg [254:0] a = 25728561913544074806655338655832537372072648408242416352266576543536686506277;
    reg [254:0] b = 17566812258234732776846655780981983198843065998106887116944655754324067075440;
    wire [254:0] out;
    wire done;
    femul femul(clock, start, a, b, done, out);

    always #1 clock <= !clock;
    initial begin
        $monitor("done=%b mul_step=%x reduce_step=%d carry=%x mid[14]=%x out=%0x", done, femul.multiply_step, femul.reduce_step, femul.carry, femul.mid[14], out);
        #1 start <= 1;
        #1 start <= 0;
    end
    always @(posedge done) $finish;
endmodule
