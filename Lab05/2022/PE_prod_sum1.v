// synopsys translate_off
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_prod_sum1.v"
// synopsys translate_on

module PE(
	// Input signals
  clk,
  A,
  B,
  W,
	// Output signals
	C,
	D
);

input clk;
input signed [15:0] A;
input signed [35:0] B;
input signed [15:0] W;
output reg signed [35:0] C;
output reg signed [15:0] D;

wire signed [35:0] sum;
DW02_prod_sum1 #(.A_width(16), .B_width(16), .SUM_width(36))
    DW02_prod_sum1_u1 ( .A(A), .B(W), .C(B), .TC(1'b1), .SUM(sum) );

always@(posedge clk) begin
  C <= sum;
  D <= A;
end
endmodule

module PE_s(
	// Input signals
  clk,
  A,
  B,
  W,
	// Output signals
	C,
);

input clk;
input signed [15:0] A;
input signed [35:0] B;
input signed [15:0] W;
output reg signed [35:0] C;

wire signed [35:0] sum;
DW02_prod_sum1 #(.A_width(16), .B_width(16), .SUM_width(36))
    DW02_prod_sum1_u1 ( .A(A), .B(W), .C(B), .TC(1'b1), .SUM(sum) );

always@(posedge clk) begin
  C <= sum;
end
endmodule


