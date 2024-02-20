`include "PE_prod_sum1.v"
`include "SRAM.v"
// synopsys translate_off
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_sum.v"
// synopsys translate_on
module MMSA(
	// Input signals
  clk,
  rst_n,
  in_valid,
  in_valid2,
  matrix,
  matrix_size,
  i_mat_idx,
  w_mat_idx,
	// Output signals
	out_valid,
  out_value
);

input clk;
input rst_n;
input in_valid, in_valid2;
input signed [15:0] matrix;
input [1:0] matrix_size;
input [3:0] i_mat_idx, w_mat_idx;
output reg out_valid;
output reg signed [39:0] out_value;

genvar gv_i, gv_j;
integer i, j;

//////////////////  m_SRAM Instantiation
wire signed [15:0] m_Q [0:15];
reg m_WEN [0:15];
reg [7:0] m_A [0:15];
reg signed [15:0] m_D [0:15];
generate
  for (gv_i = 0; gv_i <= 15; gv_i = gv_i + 1) begin : m_SRAM_block
    sram_256x16 m_sram_256x16(.Q(m_Q[gv_i]), .CLK(clk), .CEN(1'b0), .WEN(m_WEN[gv_i]), .A(m_A[gv_i]), .D(m_D[gv_i]));
  end
endgenerate
//////////////////

//////////////////  w_SRAM Instantiation
wire signed [15:0] w_Q [0:15];
reg w_WEN [0:15];
reg [7:0] w_A [0:15];
reg signed [15:0] w_D [0:15];
generate
  for (gv_i = 0; gv_i <= 15; gv_i = gv_i + 1) begin : w_SRAM_block
    sram_256x16 w_sram_16x16(.Q(w_Q[gv_i]), .CLK(clk), .CEN(1'b0), .WEN(w_WEN[gv_i]), .A(w_A[gv_i]), .D(w_D[gv_i]));
  end
endgenerate
//////////////////

//////////////////  PROD_SUM PE Instantiation
reg m_valid [0:15];
reg signed [15:0] w_mem [0:15][0:15];
wire signed [15:0] h [1:16][0:16];
wire signed [35:0] v [1:16][0:16];
generate
  for (gv_i = 1; gv_i <= 16; gv_i = gv_i + 1) begin : inst_i
    for (gv_j = 1; gv_j <= 16; gv_j = gv_j + 1) begin : inst_j
      PE pe_u1(.clk(clk), .A(h[gv_i][gv_j-1]), .B(v[gv_j][gv_i-1]), .W(w_mem[gv_i-1][gv_j-1]), .C(v[gv_j][gv_i]), .D(h[gv_i][gv_j]));
    end
  end
endgenerate
generate
  for (gv_i = 1; gv_i <= 16; gv_i = gv_i + 1) begin : connect_and_intialize
    assign h[gv_i][0] = (m_valid[gv_i-1]) ? m_Q[gv_i-1] : 16'b0;
    assign v[gv_i][0] = 36'b0;
  end
endgenerate
//////////////////


reg [2:0] state, nxt_state;
localparam Idle	= 3'd0;
localparam Readm	= 3'd1;
localparam Readw	= 3'd2;
localparam Idle2	= 3'd3;
localparam Wait	= 3'd4;
localparam Process	= 3'd5;
localparam Sum	= 3'd6;
localparam Output	= 3'd7;

reg [1:0] size;
reg [3:0] size_sub_1;
reg [3:0] mi, wi;

reg [3:0] ccnt;                                     // column counter
wire [3:0] stop_ccnt = size_sub_1;
wire stop_c = (ccnt == stop_ccnt);
wire [3:0] ccnt_add_1 = ccnt + 4'b1;
wire [3:0] ccnt_next = stop_c ? 4'd0 : ccnt_add_1;
reg [3:0] ccnt_d[0:16];

reg [3:0] rcnt;                                     // row counter
wire [3:0] stop_rcnt = size_sub_1;
wire stop_r = (rcnt == stop_rcnt);
wire [3:0] rcnt_add_1 = rcnt + 4'b1;
wire [3:0] rcnt_next = stop_r ? 4'd0 : rcnt_add_1;

reg [3:0] ncnt;                                     // matrix counter (matrix0, matrix1, matrix2, matrix3, ...)
wire [3:0] stop_ncnt = 4'd15;                       // out_valid counter (out_valid0, out_valid1, out_valid2, out_valid3, ...)
wire stop_n = (ncnt == stop_ncnt);
wire [3:0] ncnt_add_1 = ncnt + 4'b1;

reg [3:0] pcnt;                                     // process counter
wire [3:0] stop_pcnt = size_sub_1;
wire stop_p = (pcnt == stop_pcnt);
wire [3:0] pcnt_add_1 = pcnt + 4'b1;

reg [4:0] ocnt;                                     // output counter
wire [4:0] stop_ocnt = {size_sub_1, 1'b0};
wire stop_o = (ocnt == stop_ocnt);
wire [4:0] ocnt_add_1 = ocnt + 5'b1;

//////////////////  FINAL ADDER Instantiation
wire signed [39:0] out_value_next;
reg signed [39:0] se_input [1:16];
always@(*) begin
  for (i = 1; i <= 16; i = i + 1) se_input[i] = 40'b0;
  case(size)
    2'd0: for (i = 1; i <= 2; i = i + 1) if (i <= ocnt_add_1) se_input[i] = (v[i][2][35])  ? {4'b1111, v[i][2]}  : {4'b0000, v[i][2]};
    2'd1: for (i = 1; i <= 4; i = i + 1) if (i <= ocnt_add_1) se_input[i] = (v[i][4][35])  ? {4'b1111, v[i][4]}  : {4'b0000, v[i][4]};
    2'd2: for (i = 1; i <= 8; i = i + 1) if (i <= ocnt_add_1) se_input[i] = (v[i][8][35])  ? {4'b1111, v[i][8]}  : {4'b0000, v[i][8]};
    2'd3: for (i = 1; i <= 16; i = i + 1) if (i <= ocnt_add_1) se_input[i] = (v[i][16][35]) ? {4'b1111, v[i][16]} : {4'b0000, v[i][16]};
  endcase 
end
wire [639:0] inst_INPUT = {se_input[1], se_input[2], se_input[3], se_input[4], 
                           se_input[5], se_input[6], se_input[7], se_input[8], 
                           se_input[9], se_input[10], se_input[11], se_input[12], 
                           se_input[13], se_input[14], se_input[15], se_input[16]};
DW02_sum #(16, 40)
    DW02_sum_u1 ( .INPUT(inst_INPUT),  .SUM(out_value_next));
//////////////////

always@(posedge clk or negedge rst_n) begin
  if (!rst_n) state <= Idle;
	else state <= nxt_state;
end

// Next state logic
always@(*) begin
  nxt_state <= state;
  case (state)
    Idle : begin
      if (in_valid) nxt_state <= Readm;
    end
    Readm : begin
      if (stop_r && stop_c && stop_n) nxt_state <= Readw;
    end
    Readw : begin
      if (stop_r && stop_c && stop_n) nxt_state <= Idle2;
    end
    Idle2 : begin
      if (in_valid2) nxt_state <= Wait;
    end
    Wait : nxt_state <= Process;
    Process : begin
      if (stop_p) nxt_state <= Sum;
    end
    Sum : nxt_state <= Output;
    Output : begin
      if (stop_o) begin
        if (stop_n) nxt_state <= Idle;
        else nxt_state <= Idle2;
      end
    end
  endcase
end

// ccnt delay (generate the delayed ccnt)
always@(posedge clk) begin
  ccnt_d[0] <= ccnt;
  for (i = 0; i <= 15; i = i + 1) ccnt_d[i+1] <= ccnt_d[i];
end

// m_valid control (generate the control signal decide whether the inputs are from m_Q or 0)
always@(posedge clk) begin
  m_valid[0] <= 1'b0;
  for (i = 0; i <= 14; i = i + 1)  m_valid[i+1] <= m_valid[i];
  case(state)
    Process: m_valid[0] <= 1'b1;
  endcase
end

// SRAM read and write control
always@(*) begin
  for (i = 0; i <= 15; i = i + 1) begin
    m_WEN[i] <= 1'b1;
		m_A[i] <= 8'bx;
		m_D[i] <= 16'sbx;
		w_WEN[i] <= 1'b1;
		w_A[i] <= 8'bx;
		w_D[i] <= 16'sbx;
	end
  case (state)
    Idle : begin
      if (in_valid) begin
        m_WEN[0] <= 1'b0;
        m_A[0] <= 8'b0;
        m_D[0] <= matrix;
      end
    end
    Readm : begin
        m_WEN[ccnt] <= 1'b0;
        m_A[ccnt] <= {ncnt, rcnt};
        m_D[ccnt] <= matrix;
    end
    Readw : begin
        w_WEN[rcnt] <= 1'b0;
        w_A[rcnt] <= {ncnt, ccnt};
        w_D[rcnt] <= matrix;
    end
    Idle2 : begin
      //if (in_valid2) for (i = 0; i <= 15; i = i + 1) w_A[i] <= {w_mat_idx, ccnt};
    end
    Wait : begin
        for (i = 0; i <= 15; i = i + 1) begin
          w_A[i] <= {wi, ccnt_d[0]};
        end
    end
    Process : begin
        for (i = 0; i <= 15; i = i + 1) begin
          m_A[i] <= {mi, ccnt_d[i+1]};
          w_A[i] <= {wi, ccnt_d[0]};
        end
    end
    Sum : begin
        for (i = 0; i <= 15; i = i + 1) begin
          m_A[i] <= {mi, ccnt_d[i+1]};
        end
    end
    Output : begin
      for (i = 1; i <= 15; i = i + 1)  m_A[i] <= {mi, ccnt_d[i+1]};
    end
  endcase
end

// Main FSM
always@(posedge clk) begin
  case (state)
    Idle :
      begin
        rcnt <= 4'b0;
        ccnt <= 4'b1;
        ncnt <= 4'b0;
        if (in_valid) begin
          size <= matrix_size;
          case(matrix_size) 
            2'd0 : size_sub_1 <= 4'd1;
            2'd1 : size_sub_1 <= 4'd3;
            2'd2 : size_sub_1 <= 4'd7;
            2'd3 : size_sub_1 <= 4'd15;
          endcase
        end
      end
    Readm :
      begin
        ccnt <= ccnt_next;
        if (stop_c) rcnt <= rcnt_next;
        if (stop_c && stop_r) ncnt <= ncnt_add_1;
      end
    Readw :
      begin
        ccnt <= ccnt_next;
        if (stop_c) rcnt <= rcnt_next;
        if (stop_c && stop_r) ncnt <= ncnt_add_1;
      end
    Idle2 :
      begin
        pcnt <= 5'b0;
        ocnt <= 5'b0;
        if(in_valid2) begin
          ccnt <= ccnt_next;
          mi <= i_mat_idx;
          wi <= w_mat_idx;
        end
      end
    Wait :
      begin
        ccnt <= ccnt_next;
      end
    Process :
      begin
        ccnt <= ccnt_next;
        pcnt <= pcnt_add_1;
        for (i = 0; i <= 15; i = i + 1) w_mem[i][pcnt] <= w_Q[i];
      end
    Output :
      begin
        ccnt <= 4'b0;
        ocnt <= ocnt_add_1;
        if (stop_o) ncnt <= ncnt_add_1;
      end
  endcase
end

// Output control
always@(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_valid <= 1'b0;
    out_value <= 40'b0;
  end 
  else begin
    case(state)
      Output: begin
        out_valid <= 1'b1;
        out_value <= out_value_next;
      end
      default: begin
        out_valid <= 1'b0;
        out_value <= 40'b0;
      end
    endcase
  end
end

endmodule


