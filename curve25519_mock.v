module curve25519_mock
                 (input wire clock, start,
                  input wire [254:0] n, // scalar
                  input wire [254:0] q, // point
                  output wire done,
                  output wire [254:0] out);
    reg [15:0] count = 0;
    assign done = count == 0;
    always @(posedge clock) begin
        if (start) count <= {16{1'b1}};
        else if (count != 0) count <= count -1;
    end
    assign out = 
        (n==255'h4000000000000000000000000000000000000000000000000000000000000000
      && q==9)
          ? 255'h743bcb585f9990edc2cfc4af84f6ff300729bb5facda28154362cd47a37de52f :

        (n==255'h4002030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20
      && q==9)
          ? 255'h71850c3f2cd59eac742ceea75fc37c5de912aded47b366629169d381bb9dfba6 :

        (n==255'h4002030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20
      && q==255'h71850c3f2cd59eac742ceea75fc37c5de912aded47b366629169d381bb9dfba6)
          ? 255'h45dbaa45916a837457fdbda08bea49dbaabc29c65668ef235c7ae49a90375b54 :

      q;
endmodule
