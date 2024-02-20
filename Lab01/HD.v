module HD (
  output signed[5:0] out_n,
	input [6:0] code_word1,
	input [6:0] code_word2
);

wire eb1, eb2;
wire signed [3:0] c1, c2;
wire signed [5:0] a, b;
wire add_sub;
ebc ebc1(eb1, c1, code_word1);
ebc ebc2(eb2, c2, code_word2);
assign a = eb1 ? c1 : (c1 << 1);
assign b = eb1 ? (c2 << 1) : c2;
assign out_n = (eb1 ^ eb2) ? (a-b) : (a+b);
endmodule

module ebc (
  output reg eb,
  output reg signed[3:0] c,
	input [6:0] code_word
);

assign p1 = code_word[6];
assign p2 = code_word[5];
assign p3 = code_word[4];
assign x1 = code_word[3];
assign x2 = code_word[2];
assign x3 = code_word[1];
assign x4 = code_word[0];
assign circle1 = p1 ^ x1 ^ x2 ^ x3;
assign circle2 = p2 ^ x1 ^ x2 ^ x4;
assign circle3 = p3 ^ x1 ^ x3 ^ x4;
always@(*) begin
  case({circle1, circle2, circle3})
    3'b011: eb = x4;
    3'b101: eb = x3;
    3'b110: eb = x2;
    3'b111: eb = x1;
    3'b001: eb = p3;
    3'b010: eb = p2;
    3'b100: eb = p1;
  default : eb = 1'bx;
  endcase
end
always@(*) begin
  case({circle1, circle2, circle3})
    3'b011: c = {x1, x2, x3, ~x4};
    3'b101: c = {x1, x2, ~x3, x4};
    3'b110: c = {x1, ~x2, x3, x4};
    3'b111: c = {~x1, x2, x3, x4};
    3'b001: c = code_word;
    3'b010: c = code_word;
    3'b100: c = code_word;
  default : c = 4'bx;
  endcase
end
//assign eb = circle1 ? (circle2 ? (circle3 ? x1 : x2) : (circle3 ? x3 : p1)) : (circle2 ? (circle3 ? x4 : p2) : (circle3 ? p3 : 1'bx));
//assign c = circle1 ? (circle2 ? (circle3 ? {~x1, x2, x3, x4} : {x1, ~x2, x3, x4}) : (circle3 ? {x1, x2, ~x3, x4} : code_word)) : (circle2 ? (circle3 ? {x1, x2, x3, ~x4} : code_word) : (circle3 ? code_word : 4'bx));
endmodule

