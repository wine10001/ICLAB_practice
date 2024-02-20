// synopsys translate_off
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_add.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_mult.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_exp.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_recip.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_addsub.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_div.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/vcs/DW_exp2.v"
// synopsys translate_on

module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

localparam fp_width = inst_sig_width + inst_exp_width + 1;
localparam fp_one = {1'b0, {1'b0, {inst_exp_width - 1{1'b1}}}, {inst_sig_width{1'b0}}};
localparam fp_zero = {fp_width{1'b0}};

reg [fp_width - 1:0] u [0:2][0:2];
reg [fp_width - 1:0] w [0:2][0:2];
reg [fp_width - 1:0] v [0:2][0:2];
reg [fp_width - 1:0] x [1:3][0:2];
reg [fp_width - 1:0] h [1:3][0:2];

reg [4:0] state, next_state;
wire [4:0] state_add_1 = state + 5'd1;
localparam S1	= 5'd1;
localparam S2	= 5'd2;
localparam S3	= 5'd3;
localparam S4	= 5'd4;
localparam S5	= 5'd5;
localparam S6	= 5'd6;
localparam S7	= 5'd7;
localparam S8	= 5'd8;
localparam S9	= 5'd9;
localparam S10	= 5'd10;
localparam S11	= 5'd11;
localparam S12	= 5'd12;
localparam S13	= 5'd13;
localparam S14	= 5'd14;
localparam S15	= 5'd15;
localparam S16	= 5'd16;
localparam S17	= 5'd17;
localparam S18	= 5'd18;
localparam S19	= 5'd19;
localparam S20	= 5'd20;
localparam S21	= 5'd21;  // ouput state 1
localparam S22	= 5'd22;  // ouput state 2
localparam S23	= 5'd23;  // ouput state 3
localparam S24	= 5'd24;  // ouput state 4
localparam S25	= 5'd25;  // ouput state 5
localparam S26	= 5'd26;  // ouput state 6
localparam S27	= 5'd27;  // ouput state 7
localparam S28	= 5'd28;  // ouput state 8
localparam S29	= 5'd29;  // ouput state 9

// Instantiate of DW IP for mult, add, sigmoid
// mult
reg [fp_width - 1:0] mult1_a, mult1_b;
wire [fp_width - 1:0]mult1_z;
DW_fp_mult #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_mult1(.a(mult1_a), .b(mult1_b), .rnd(3'b000), .z(mult1_z), .status());
reg [fp_width - 1:0] mult2_a, mult2_b;
wire [fp_width - 1:0]mult2_z;
DW_fp_mult #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_mult2(.a(mult2_a), .b(mult2_b), .rnd(3'b000), .z(mult2_z), .status());
reg [fp_width - 1:0] mult3_a, mult3_b;
wire [fp_width - 1:0]mult3_z;
DW_fp_mult #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_mult3(.a(mult3_a), .b(mult3_b), .rnd(3'b000), .z(mult3_z), .status());

// add
reg [fp_width - 1:0] add1_a;
wire [fp_width - 1:0] add1_z;
DW_fp_add #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_add_1(.a(add1_a), .b(mult1_z), .z(add1_z), .status(), .rnd(3'b000));

reg [fp_width - 1:0] add2_a;
wire [fp_width - 1:0] add2_z;
DW_fp_add #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_add_2(.a(add2_a), .b(mult2_z), .z(add2_z), .status(), .rnd(3'b000));

reg [fp_width - 1:0] add3_a;
wire [fp_width - 1:0] add3_z;
DW_fp_add #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_add_3(.a(add3_a), .b(mult3_z), .z(add3_z), .status(), .rnd(3'b000));

// sigmoid
reg [fp_width - 1:0] sigmoid1_a;
wire [fp_width - 1:0] sigmoid1_z;
DW_fp_exp #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance), .arch(1))
	u_DW_fp_exp_sigmoid(.a({~sigmoid1_a[fp_width - 1], sigmoid1_a[fp_width - 2:0]}), .z(sigmoid1_z), .status());
reg [fp_width - 1:0] sigmoid2_a;
wire [fp_width - 1:0] sigmoid2_z;
DW_fp_add #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
	u_DW_fp_add_sigmoid(.a(fp_one), .b(sigmoid2_a), .z(sigmoid2_z), .status(), .rnd(3'b000));
reg [fp_width - 1:0] sigmoid3_a;
wire [fp_width - 1:0] sigmoid3_z;
DW_fp_recip #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance), .faithful_round(1))
	u_DW_fp_recip_sigmoid(.a(sigmoid3_a), .rnd(3'b000), .z(sigmoid3_z), .status());

// FSM next state logic
always @(*) begin
	next_state <= state_add_1;
	case (state)
		S1 :
			if (in_valid_u) next_state <= S2;
			else next_state <= S1;
    S29 : next_state <= S1;
	endcase
end

// FSM  current state logic
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state <= S1;
	else state <= next_state;
end

// FSM logic for mult, add
always @(posedge clk) begin
  mult1_a <= {fp_width{1'bx}};
  mult1_b <= {fp_width{1'bx}};
  mult2_a <= {fp_width{1'bx}};
  mult2_b <= {fp_width{1'bx}};
  mult3_a <= {fp_width{1'bx}};
  mult3_b <= {fp_width{1'bx}};
  add1_a <= {fp_width{1'bx}};
  add2_a <= {fp_width{1'bx}};
  add3_a <= {fp_width{1'bx}};
  sigmoid1_a <= {fp_width{1'bx}};
  sigmoid2_a <= {fp_width{1'bx}};
  sigmoid3_a <= {fp_width{1'bx}};
  case(state)
    S1: begin
      mult1_a <= weight_u;  // u[0][0]
      mult1_b <= data_x;    // x[1][0]
    end

    S2: begin
      mult1_a <= weight_u;  // u[0][1]
      mult1_b <= data_x;    // x[1][1]
      add1_a <= mult1_z;
    end

    S3: begin
      mult1_a <= weight_u;  // u[0][2]
      mult1_b <= data_x;    // x[1][2]
      add1_a <= add1_z;

    end

    S4: begin
      mult1_a <= weight_u;  // u[1][0]
      mult1_b <= data_x;    // x[2][0]

      mult2_a <= weight_u;  // u[1][0]
      mult2_b <= x[1][0];    // x[1][0]

      mult3_a <= u[0][0];   // u[0][0]
      mult3_b <= data_x;    // x[2][0]

      sigmoid1_a <= add1_z; 
    end

    S5: begin
      mult1_a <= weight_u;  // u[1][1]
      mult1_b <= data_x;    // x[2][1]
      add1_a <= mult1_z;

      mult2_a <= weight_u;  // u[1][1]
      mult2_b <= x[1][1];    // x[1][1]
      add2_a <= mult2_z;

      mult3_a <= u[0][1];   // u[0][1]
      mult3_b <= data_x;    // x[2][1]
      add3_a <= mult3_z;

      sigmoid2_a <= sigmoid1_z;
    end

    S6: begin
      mult1_a <= weight_u;  // u[1][2]
      mult1_b <= data_x;    // x[2][2]
      add1_a <= add1_z;

      mult2_a <= weight_u;  // u[1][2]
      mult2_b <= x[1][2];    // x[1][2]
      add2_a <= add2_z;

      mult3_a <= u[0][2];   // u[0][2]
      mult3_b <= data_x;    // x[2][2]
      add3_a <= add3_z;

      sigmoid3_a <= sigmoid2_z;
    end

    S7: begin
      mult1_a <= weight_u;  // u[2][0]
      mult1_b <= data_x;    // x[3][0]

      mult2_a <= weight_u;  // u[2][0]
      mult2_b <= x[2][0];    // x[2][0]

      mult3_a <= weight_u;   // u[2][0]
      mult3_b <= x[1][0];    // x[1][0]

      sigmoid1_a <= add2_z;
    end

    S8: begin
      mult1_a <= weight_u;  // u[2][1]
      mult1_b <= data_x;    // x[3][1]
      add1_a <= mult1_z;

      mult2_a <= weight_u;  // u[2][1]
      mult2_b <= x[2][1];   // x[2][1]
      add2_a <= mult2_z;

      mult3_a <= weight_u;  // u[2][1]
      mult3_b <= x[1][1];   // x[1][1]
      add3_a <= mult3_z;

      sigmoid2_a <= sigmoid1_z;
    end

    S9: begin
      mult1_a <= weight_u;  // u[2][2]
      mult1_b <= data_x;    // x[3][2]
      add1_a <= add1_z;

      mult2_a <= weight_u;  // u[2][2]
      mult2_b <= x[2][2];   // x[2][2]
      add2_a <= add2_z;

      mult3_a <= weight_u;  // u[2][2]
      mult3_b <= x[1][2];   // x[1][2]
      add3_a <= add3_z;

      sigmoid3_a <= sigmoid2_z;
    end

    S10: begin
      mult1_a <= u[0][0];  // u[0][0]
      mult1_b <= x[3][0];    // x[3][0]

      mult2_a <= u[1][0];  // u[1][0]
      mult2_b <= x[3][0];    // x[3][0]

      mult3_a <= w[1][0];  // w[1][0]
      mult3_b <= h[1][0];  // h[1][0]
      add3_a <= h[2][1];   // h[2][1]

      sigmoid1_a <= add3_z;
    end

    S11: begin
      mult1_a <= u[0][1];  // u[0][1]
      mult1_b <= x[3][1];    // x[3][1]
      add1_a <= mult1_z;

      mult2_a <= u[1][1];  // u[1][1]
      mult2_b <= x[3][1];    // x[3][1]
      add2_a <= mult2_z;

      mult3_a <= w[0][0];  // w[0][0]
      mult3_b <= h[1][0];    // h[1][0]
      add3_a <= h[2][0];   // h[2][0]

      sigmoid2_a <= sigmoid1_z;
    end

    S12: begin
      mult1_a <= u[0][2];  // u[0][2]
      mult1_b <= x[3][2];    // x[3][2]
      add1_a <= add1_z;

      mult2_a <= u[1][2];  // u[1][2]
      mult2_b <= x[3][2];    // x[3][2]
      add2_a <= add2_z;

      mult3_a <= w[0][1];  // w[0][1]
      mult3_b <= h[1][1];    // h[1][1]
      add3_a <= add3_z;   // h[2][0]

      sigmoid3_a <= sigmoid2_z;
    end

    S13: begin
      mult1_a <= w[1][1];  // w[1][1]
      mult1_b <= h[1][1];    // h[1][1]
      add1_a <= h[2][1];

      mult2_a <= w[2][0];  // w[2][0]
      mult2_b <= h[1][0];    // h[1][0]
      add2_a <= h[2][2];

      mult3_a <= w[0][2];  // w[0][2]
      mult3_b <= sigmoid3_z;    // h[1][2]
      add3_a <= add3_z;   // h[2][0]
    end

    S14: begin
      mult1_a <= w[1][2];  // w[1][2]
      mult1_b <= h[1][2];    // h[1][2]
      add1_a <= add1_z;
      
      mult2_a <= w[2][1];  // w[2][1]
      mult2_b <= h[1][1];    // h[1][1]
      add2_a <= add2_z;

      mult3_a <= v[0][2];  // v[0][2]
      mult3_b <= h[1][2];    // h[1][2]

      sigmoid1_a <= add3_z;
    end

    S15: begin
      mult1_a <= v[0][0];  // v[0][0]
      mult1_b <= h[1][0];    // h[1][0]
      add1_a <= mult3_z;
      
      mult2_a <= w[2][2];  // w[2][2]
      mult2_b <= h[1][2];    // h[1][2]
      add2_a <= add2_z;

      mult3_a <= v[2][0];  // v[2][0]
      mult3_b <= h[1][0];    // h[1][0]

      sigmoid1_a <= add1_z;
      sigmoid2_a <= sigmoid1_z;
    end

    S16: begin
      mult1_a <= v[0][1];  // v[0][1]
      mult1_b <= h[1][1];    // h[1][1]
      add1_a <= add1_z;
      
      mult2_a <= v[1][0];  // v[1][0]
      mult2_b <= h[1][0];    // h[1][0]


      mult3_a <= v[2][1];  // v[2][1]
      mult3_b <= h[1][1];    // h[1][1]
      add3_a <= mult3_z;

      sigmoid1_a <= add2_z;
      sigmoid2_a <= sigmoid1_z;
      sigmoid3_a <= sigmoid2_z;
    end

    S17: begin
      mult1_a <= w[0][0];  // w[0][0]
      mult1_b <= sigmoid3_z;    // h[2][0]
      add1_a <= h[3][0];
      
      mult2_a <= v[1][1];  // v[1][1]
      mult2_b <= h[1][1];    // h[1][1]
      add2_a <= mult2_z;

      mult3_a <= v[2][2];  // v[2][2]
      mult3_b <= h[1][2];    // x[1][2]
      add3_a <= add3_z;

      sigmoid2_a <= sigmoid1_z;
      sigmoid3_a <= sigmoid2_z;
    end

    S18: begin
      mult1_a <= w[0][1];  // w[0][1]
      mult1_b <= sigmoid3_z;    // h[2][1]
      add1_a <= add1_z;
      
      mult2_a <= v[1][2];  // w[1][2]
      mult2_b <= h[1][2];    // h[1][2]
      add2_a <= add2_z;

      mult3_a <= w[1][0];  // w[1][0]
      mult3_b <= h[2][0];    // h[2][0]
      add3_a <= h[3][1];

      sigmoid3_a <= sigmoid2_z;
    end

    S19: begin
      mult1_a <= w[0][2];  // w[0][2]
      mult1_b <= sigmoid3_z;    // h[2][2]
      add1_a <= add1_z;

      mult2_a <= w[2][0];  // w[2][0]
      mult2_b <= h[2][0];    // h[2][0]
      add2_a <= h[3][2];

      mult3_a <= w[1][1];  // w[1][1]
      mult3_b <= h[2][1];    // h[2][1]
      add3_a <= add3_z;
    end

    S20: begin
      mult1_a <= v[0][0];  // v[0][0]
      mult1_b <= h[2][0];    // h[2][0]

      mult2_a <= w[2][1];  // w[2][1]
      mult2_b <= h[2][1];    // h[2][1]
      add2_a <= add2_z;

      mult3_a <= w[1][2];  // w[1][2]
      mult3_b <= h[2][2];    // h[2][2]
      add3_a <= add3_z;

      sigmoid1_a <= add1_z;
    end

    S21: begin
      mult1_a <= v[0][1];  // v[0][1]
      mult1_b <= h[2][1];    // h[2][1]
      add1_a <= mult1_z;

      mult2_a <= w[2][2];  // w[2][2]
      mult2_b <= h[2][2];    // h[2][2]
      add2_a <= add2_z;

      mult3_a <= v[1][0];  // v[1][0]
      mult3_b <= h[2][0];    // h[2][0]

      sigmoid1_a <= add3_z;
      sigmoid2_a <= sigmoid1_z;

    end

    S22: begin
      mult1_a <= v[0][2];  // v[0][2]
      mult1_b <= h[2][2];    // h[2][2]
      add1_a <= add1_z;

      mult2_a <= v[2][0];  // v[2][0]
      mult2_b <= h[2][0];    // h[2][0]

      mult3_a <= v[1][1];  // v[1][1]
      mult3_b <= h[2][1];    // h[2][1]
      add3_a <= mult3_z;

      sigmoid1_a <= add2_z;
      sigmoid2_a <= sigmoid1_z;
      sigmoid3_a <= sigmoid2_z;
    end

    S23: begin
      mult1_a <= v[0][0];  // v[0][0]
      mult1_b <= sigmoid3_z;    // h[3][0] 

      mult2_a <= v[2][1];  // v[2][1]
      mult2_b <= h[2][1];    // h[2][1]
      add2_a <= mult2_z; 

      mult3_a <= v[1][2];  // v[1][2]
      mult3_b <= h[2][2];    // h[2][2] 
      add3_a <= add3_z;

      sigmoid2_a <= sigmoid1_z;
      sigmoid3_a <= sigmoid2_z;
    end

    S24: begin
      mult1_a <= v[0][1];  // v[0][1]
      mult1_b <= sigmoid3_z;    // h[3][1] 
      add1_a <= mult1_z;

      mult2_a <= v[2][2];  // v[2][2]
      mult2_b <= h[2][2];    // h[2][2]
      add2_a <= add2_z; 

      mult3_a <= v[1][0];  // v[1][0]
      mult3_b <= h[3][0];    // h[3][0]

      sigmoid3_a <= sigmoid2_z;
    end

    S25: begin
      mult1_a <= v[0][2];  // v[0][2]
      mult1_b <= sigmoid3_z;    // h[3][2] 
      add1_a <= add1_z;

      mult2_a <= v[2][0];  // v[2][0]
      mult2_b <= h[3][0];    // h[3][0]

      mult3_a <= v[1][1];  // v[1][1]
      mult3_b <= h[3][1];    // h[3][1]
      add3_a <= mult3_z;
    end

    S26: begin
      mult2_a <= v[2][1];  // v[2][1]
      mult2_b <= h[3][1];    // h[3][1]
      add2_a <= mult2_z;

      mult3_a <= v[1][2];  // v[1][2]
      mult3_b <= h[3][2];    // h[3][2]
      add3_a <= add3_z;
    end

    S27: begin
      mult2_a <= v[2][2];  // v[2][2]
      mult2_b <= h[3][2];    // h[3][2]
      add2_a <= add2_z;
    end


  endcase
end

// FSM logic for u, v, w, x, h
always @(posedge clk) begin
  case(state)
  // Read weight_u, weight_v, weight_w, data_x
    S1 : begin 
      u[0][0] <= weight_u;
      v[0][0] <= weight_v;
      w[0][0] <= weight_w;
      x[1][0] <= data_x;
    end

    S2 : begin 
      u[0][1] <= weight_u;
      v[0][1] <= weight_v;
      w[0][1] <= weight_w;
      x[1][1] <= data_x;
    end

    S3 : begin 
      u[0][2] <= weight_u;
      v[0][2] <= weight_v;
      w[0][2] <= weight_w;
      x[1][2] <= data_x;
    end

    S4 : begin 
      u[1][0] <= weight_u;
      v[1][0] <= weight_v;
      w[1][0] <= weight_w;
      x[2][0] <= data_x;

      //h[1][0] <= add1_z;  // h1[0] before sigmoid
    end

    S5 : begin 
      u[1][1] <= weight_u;
      v[1][1] <= weight_v;
      w[1][1] <= weight_w;
      x[2][1] <= data_x;
    end

    S6 : begin 
      u[1][2] <= weight_u;
      v[1][2] <= weight_v;
      w[1][2] <= weight_w;
      x[2][2] <= data_x;
    end

    S7 : begin 
      u[2][0] <= weight_u;
      v[2][0] <= weight_v;
      w[2][0] <= weight_w;
      x[3][0] <= data_x;

      h[1][0] <= sigmoid3_z;  // h1[0] after sigmoid
      h[2][1] <= add1_z;  
      h[2][0] <= add3_z;  
    end

    S8 : begin 
      u[2][1] <= weight_u;
      v[2][1] <= weight_v;
      w[2][1] <= weight_w;
      x[3][1] <= data_x;
    end

    S9 : begin 
      u[2][2] <= weight_u;
      v[2][2] <= weight_v;
      w[2][2] <= weight_w;
      x[3][2] <= data_x;
    end

    S10 : begin 
      h[1][1] <= sigmoid3_z;  // h1[1] after sigmoid
      h[3][2] <= add1_z;  
      h[2][2] <= add2_z;  
    end

    S11 : begin 
      h[2][1] <= add3_z;
    end

    S12 : begin 
    end

    S13 : begin 
      h[1][2] <= sigmoid3_z;  // h1[2] after sigmoid
      h[3][0] <= add1_z;
      h[3][1] <= add2_z;
    end

    S14 : begin 
    end

    S15 : begin 
    end

    S16 : begin 
    end

    S17 : begin 
      h[2][0] <= sigmoid3_z;
      x[1][0] <= add1_z;
    end

    S18 : begin 
      h[2][1] <= sigmoid3_z;
      x[1][2] <= add3_z;
    end

    S19 : begin 
      h[2][2] <= sigmoid3_z;
      x[1][1] <= add2_z;
    end

    S23: begin
      h[3][0] <= sigmoid3_z;
      //x[2][0] <= add1_z;
    end

    S24: begin
      h[3][1] <= sigmoid3_z;
      //x[2][1] <= add3_z;
    end

    S25: begin
      h[3][2] <= sigmoid3_z;
      //x[2][2] <= add2_z;
    end

    S26: begin
      //x[3][0] <= add1_z;
    end

    S27: begin
      //x[3][1] <= add3_z;
    end

    S28: begin
      //x[3][2] <= add2_z;
    end
  endcase
end

always@(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    out_valid <= 1'b0;
    out <= fp_zero;
  end
  else begin
    case(state)
      S20: begin
        out_valid <= 1'b1;
        out <= (x[1][0][fp_width - 1])? fp_zero : x[1][0];
      end

      S21: begin
        out_valid <= 1'b1;
        out <= (x[1][1][fp_width - 1])? fp_zero : x[1][1];
      end

      S22: begin
        out_valid <= 1'b1;
        out <= (x[1][2][fp_width - 1])? fp_zero : x[1][2];
      end

      S23, S26: begin
        out_valid <= 1'b1;
        out <= (add1_z[fp_width - 1])? fp_zero : add1_z;
      end

      S24, S27: begin
        out_valid <= 1'b1;
        out <= (add3_z[fp_width - 1])? fp_zero : add3_z;
      end

      S25, S28: begin
        out_valid <= 1'b1;
        out <= (add2_z[fp_width - 1])? fp_zero : add2_z;
      end
      default: begin
        out_valid <= 1'b0;
        out <= fp_zero;
      end
    endcase
  end
end
endmodule


