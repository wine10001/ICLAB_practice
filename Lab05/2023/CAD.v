`include "image_SRAM.v"
`include "kernel_SRAM.v"
// synopsys translate_off
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_mult.v"
`include "/usr/cadtool/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_sum.v"
// synopsys translate_on
module CAD(
	// Input signals
  clk,
  rst_n,
  in_valid,
  in_valid2,
  matrix,
  matrix_size,
  matrix_idx,
  mode,
	// Output signals
	out_valid,
  out_value
);

input clk;
input rst_n;
input in_valid, in_valid2;
input signed [7:0] matrix;
input [1:0] matrix_size;
input [3:0] matrix_idx;
input mode;
output reg out_valid;
output reg out_value;

genvar gv_i, gv_j;
integer i, j;

reg signed [7:0] line_buffer [0:4][0:31];
reg signed [7:0] kernel_map [0:4][0:4];
reg signed [19:0] feature_map [0:35][0:35];
reg signed [19:0] feature_map_next [0:35][0:35];

//////////////////  i_SRAM Instantiation
wire [63:0] i_Q;
reg i_WEN;
reg [10:0] i_A;
reg [63:0] i_D;
sram_2048x64 i_sram_2048x64(.Q(i_Q), .CLK(clk), .CEN(1'b0), .WEN(i_WEN), .A(i_A), .D(i_D));
//////////////////

//////////////////  k_SRAM Instantiation
wire [39:0] k_Q;
reg k_WEN;
reg [6:0] k_A;
reg [39:0] k_D;
sram_80x40 k_sram_80x40(.Q(k_Q), .CLK(clk), .CEN(1'b0), .WEN(k_WEN), .A(k_A), .D(k_D));
//////////////////

//////////////////  window1 Instantiation
wire signed [15:0] mult1_z [0:4][0:4];
reg signed [7:0] mult1_a [0:4][0:4];
generate
  for (gv_i = 0; gv_i <= 4; gv_i = gv_i + 1) begin : w1_mult_i
    for (gv_j = 0; gv_j <= 4; gv_j = gv_j + 1) begin : w1_mult_j
      DW02_mult #(.A_width(8), .B_width(8))
          DW02_mult_w1 ( .A(mult1_a[gv_i][gv_j]), .B(kernel_map[gv_i][gv_j]), .TC(1'b1), .PRODUCT(mult1_z[gv_i][gv_j]) );
    end
  end
endgenerate

reg signed [19:0] mult1_z_se [0:4][0:4];
wire signed [19:0] mult1_z_se_next [0:4][0:4];
wire signed [19:0] output_w1;
generate
  for (gv_i = 0; gv_i <= 4; gv_i = gv_i + 1) begin : w1_se_i
    for (gv_j = 0; gv_j <= 4; gv_j = gv_j + 1) begin : w1_se_j
      assign mult1_z_se_next[gv_i][gv_j] = (mult1_z[gv_i][gv_j][15]) ? {4'b1111, mult1_z[gv_i][gv_j]} : {4'b0000, mult1_z[gv_i][gv_j]};
    end
  end
endgenerate
wire [499:0] inst_INPUT1 = {mult1_z_se[0][0], mult1_z_se[0][1], mult1_z_se[0][2], mult1_z_se[0][3], mult1_z_se[0][4],
                            mult1_z_se[1][0], mult1_z_se[1][1], mult1_z_se[1][2], mult1_z_se[1][3], mult1_z_se[1][4],
                            mult1_z_se[2][0], mult1_z_se[2][1], mult1_z_se[2][2], mult1_z_se[2][3], mult1_z_se[2][4],
                            mult1_z_se[3][0], mult1_z_se[3][1], mult1_z_se[3][2], mult1_z_se[3][3], mult1_z_se[3][4],
                            mult1_z_se[4][0], mult1_z_se[4][1], mult1_z_se[4][2], mult1_z_se[4][3], mult1_z_se[4][4]};
DW02_sum #(25, 20)
    DW02_sum_w1 ( .INPUT(inst_INPUT1),  .SUM(output_w1));
//////////////////

reg [3:0] state, nxt_state;
localparam Idle	= 4'd0;
localparam Read_img	= 4'd1;
localparam Read_ker	= 4'd2;
localparam Idle2	= 4'd3;
localparam Wait	= 4'd4;
localparam Conv_Fill	= 4'd5;
localparam Conv_Shift	= 4'd6;
localparam Conv_Sum	= 4'd7;
localparam Conv_Done = 4'd8;
localparam DeConv_Fill	= 4'd9;
localparam DeConv_Shift	= 4'd10;
localparam DeConv_Done	= 4'd11;

reg md;
reg [1:0] size;
reg [4:0] size_sub_1;
reg [3:0] ii, ki;
reg [63:0] matrix_data;
reg [63:0] matrix_data_next;
reg signed [19:0] ans;
reg signed [19:0] ans_next;

wire [5:0] d_size_sub_1 = size_sub_1 + 6'd4;
wire [4:0] c_size_sub_1 = size_sub_1 - 5'd4;
wire [3:0] p_size_sub_1 = c_size_sub_1 >> 1;

reg [6:0] ecnt;                                     // element counter
reg [6:0] stop_ecnt;
wire stop_e = (ecnt == stop_ecnt);
wire [6:0] ecnt_add_1 = ecnt + 7'b1;
wire [6:0] ecnt_next = stop_e ? 7'd0 : ecnt_add_1;
wire stop_e_next = (ecnt_next == stop_ecnt);
wire [2:0] ecnt_lsb = ecnt[2:0];
wire [2:0] ecnt_csb = ecnt[3:1];
wire [2:0] ecnt_msb = ecnt[4:2];

reg [2:0] bcnt;                                     // bandwidth counter
wire [2:0] stop_bcnt = (state == Read_ker) ? 3'd4 : 3'd7;
wire stop_b = (bcnt == stop_bcnt);
wire [2:0] bcnt_add_1 = bcnt + 3'b1;
wire [2:0] bcnt_next = stop_b ? 3'd0 : bcnt_add_1;

reg [2:0] kcnt;
wire [2:0] stop_kcnt = 3'd4;                                     // kernel counter
wire stop_k = (kcnt == stop_kcnt);
wire [2:0] kcnt_add_1 = kcnt + 3'b1;
wire [2:0] kcnt_next = stop_k ? 3'd0 : kcnt_add_1;

reg [3:0] ncnt;                                     // matrix counter (matrix0, matrix1, matrix2, matrix3, ...)
wire [3:0] stop_ncnt = 4'd15;                       // out_valid counter (out_valid0, out_valid1, out_valid2, out_valid3, ...)
wire stop_n = (ncnt == stop_ncnt);
wire [3:0] ncnt_add_1 = ncnt + 4'b1;

/////////// pseduo process calculation
reg [4:0] pcnt;                                     // process counter
reg [4:0] stop_pcnt;
wire stop_p = (pcnt == stop_pcnt);
wire [4:0] pcnt_add_1 = pcnt + 4'b1;
///////////

reg [2:0] shift_cnt;
wire shift_cnt_eq_7 = (shift_cnt == 3'd7);
wire [2:0] shift_cnt_add_1 = shift_cnt + 3'b1;
wire [2:0] shift_cnt_next = shift_cnt_eq_7 ? 3'd0 : shift_cnt_add_1;

reg [4:0] ccnt;                                     // column counter
wire [4:0] stop_ccnt = (md) ? size_sub_1 : c_size_sub_1;
wire stop_c = (ccnt == stop_ccnt);
wire [4:0] ccnt_add_1 = ccnt + 5'b1;
wire [4:0] ccnt_next = stop_c ? 5'd0 : ccnt_add_1;
reg [4:0] ccnt_d;

reg [4:0] rcnt;                                     // row counter
wire [4:0] stop_rcnt = (md) ? size_sub_1 : c_size_sub_1;
wire stop_r = (rcnt == stop_rcnt);
wire [4:0] rcnt_add_1 = rcnt + 5'b1;
wire [4:0] rcnt_next = stop_r ? 5'd0 : rcnt_add_1;
reg [4:0] rcnt_d;

reg [4:0] ocnt;                                     // output counter
wire [4:0] stop_ocnt = 5'd19;
wire stop_o = (ocnt == stop_ocnt);
wire [4:0] ocnt_add_1 = ocnt + 5'b1;
wire [4:0] ocnt_next = stop_o ? 5'd0 : ocnt_add_1;
wire ocnt_eq_0 = (ocnt == 5'd0);

reg [5:0] occnt;                                     // output column counter
wire [5:0] stop_occnt = (md) ? d_size_sub_1 : p_size_sub_1;
wire stop_oc = (occnt == stop_occnt);
wire [5:0] occnt_add_1 = occnt + 5'b1;
wire [5:0] occnt_next = stop_oc ? 5'd0 : occnt_add_1;

reg [5:0] orcnt;                                     // output row counter
wire [5:0] stop_orcnt = (md) ? d_size_sub_1 : p_size_sub_1;
wire stop_or = (orcnt == stop_orcnt);
wire [5:0] orcnt_add_1 = orcnt + 5'b1;
wire [5:0] orcnt_next = stop_or ? 5'd0 : orcnt_add_1;

wire d_start_output = (pcnt >= 7'd1);
wire c_start_output_pulse = (ccnt == 5'd1 && rcnt == 5'd1);
reg c_start_output;

// Max Pool
wire signed [19:0] result1, result2, max_pool_result;
assign result1 = (feature_map_next[orcnt << 1][occnt << 1] > feature_map_next[orcnt << 1][(occnt << 1) + 1]) ? feature_map_next[orcnt << 1][occnt << 1] : feature_map_next[orcnt << 1][(occnt << 1) + 1];
assign result2 = (feature_map_next[(orcnt << 1) + 1][occnt << 1] > feature_map_next[(orcnt << 1) + 1][(occnt << 1) + 1]) ? feature_map_next[(orcnt << 1) + 1][occnt << 1] : feature_map_next[(orcnt << 1) + 1][(occnt << 1) + 1];
assign max_pool_result = (result1 > result2) ? result1 : result2;

always@(posedge clk or negedge rst_n) begin
  if (!rst_n) state <= Idle;
	else state <= nxt_state;
end

// Next state logic
always@(*) begin
  nxt_state <= state;
  case (state)
    Idle : begin
      if (in_valid) nxt_state <= Read_img;
    end
    Read_img : begin
      if (stop_b && stop_e && stop_n) nxt_state <= Read_ker;
    end
    Read_ker : begin
      if (stop_b && stop_k && stop_n) nxt_state <= Idle2;
    end
    Idle2 : begin
      if (in_valid2) nxt_state <= Wait;
    end
    Wait : begin
      if (!md) nxt_state <= Conv_Fill;
      else nxt_state <= DeConv_Fill;
    end
    Conv_Fill : begin
      if (stop_p) nxt_state <= Conv_Shift;
    end
    Conv_Shift : begin
      if (stop_c && stop_r) nxt_state <= Conv_Sum;
    end
    Conv_Sum : begin
      nxt_state <= Conv_Done;
    end
    DeConv_Fill : begin
      if (stop_p) nxt_state <= DeConv_Shift;
    end
    DeConv_Shift : begin
      if (stop_c && stop_r) nxt_state <= DeConv_Done;
    end
    Conv_Done, DeConv_Done : begin
      if (stop_o && stop_oc && stop_or) begin
        if (stop_n) nxt_state <= Idle;
        else nxt_state <= Idle2;
      end
    end
  endcase
end

// ccnt_d and rcnt_d 
always@(posedge clk) begin
  ccnt_d <= ccnt;
  rcnt_d <= rcnt;
end

always@(posedge clk) begin
  c_start_output <= 1'b0;
  case(state)
    Conv_Shift: begin
      if (c_start_output_pulse) c_start_output <= 1'b1;
      else c_start_output <= c_start_output;
    end
  endcase
end

// matrix data(64-bit) iteration
always@(*) begin
  matrix_data_next <= 64'bx;
  case(state)
    Idle: matrix_data_next <= {matrix, 56'b0};
    Read_img, Read_ker : matrix_data_next <= {matrix, matrix_data[63:8]};
  endcase
end

//==============================================//
//          SRAM read and write control         //
//==============================================//
always@(*) begin
    i_WEN <= 1'b1;
		i_A <= 11'bx;
		i_D <= 64'bx;
		k_WEN <= 1'b1;
		k_A <= 7'bx;
		k_D <= 40'bx;
  case (state)
    Read_img : begin
      if (stop_b) begin
        i_WEN <= 1'b0;
        i_A <= {ncnt, ecnt};
        i_D <= matrix_data_next;
      end
    end
    Read_ker : begin
      if (stop_b) begin
        k_WEN <= 1'b0;
        k_A <= (ncnt << 2) + ncnt + kcnt;
        k_D <= matrix_data_next[63:24];
      end
    end
    Wait : begin
      i_A <= {ii, 7'd0};
      if (in_valid2) k_A <= (matrix_idx << 2) + matrix_idx;
    end
    Conv_Fill, DeConv_Fill, Conv_Shift, DeConv_Shift : begin
      i_A <= {ii, ecnt_next};
      k_A <= (ki << 2) + ki + kcnt_next;
    end
  endcase
end

//==============================================//
//                 Line Buffer                  //
//==============================================//
always@(posedge clk) begin
  case(state)
    Idle2: for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 31; j = j + 1) line_buffer[i][j] <= 8'sbx;
    Conv_Fill, DeConv_Fill: begin
      case(size)
        2'd0 : begin        // Insert pixels for the first 5 cycles
          {line_buffer[ecnt_lsb][7], line_buffer[ecnt_lsb][6], line_buffer[ecnt_lsb][5], line_buffer[ecnt_lsb][4], 
          line_buffer[ecnt_lsb][3], line_buffer[ecnt_lsb][2], line_buffer[ecnt_lsb][1], line_buffer[ecnt_lsb][0]} <= i_Q;
        end

        2'd1 : begin        // Insert pixels for the first 10 cycles
          case(ecnt[0])
            1'b0 :  begin
              {line_buffer[ecnt_csb][7], line_buffer[ecnt_csb][6], line_buffer[ecnt_csb][5], line_buffer[ecnt_csb][4], 
              line_buffer[ecnt_csb][3], line_buffer[ecnt_csb][2], line_buffer[ecnt_csb][1], line_buffer[ecnt_csb][0]} <= i_Q;
            end
            1'b1 :  begin
              {line_buffer[ecnt_csb][15], line_buffer[ecnt_csb][14], line_buffer[ecnt_csb][13], line_buffer[ecnt_csb][12], 
              line_buffer[ecnt_csb][11], line_buffer[ecnt_csb][10], line_buffer[ecnt_csb][9], line_buffer[ecnt_csb][8]} <= i_Q;
            end
          endcase
        end

        2'd2 : begin        // Insert pixels for the first 20 cycles
          case(ecnt[1:0])
            2'b00 :  begin
              {line_buffer[ecnt_msb][7], line_buffer[ecnt_msb][6], line_buffer[ecnt_msb][5], line_buffer[ecnt_msb][4], 
              line_buffer[ecnt_msb][3], line_buffer[ecnt_msb][2], line_buffer[ecnt_msb][1], line_buffer[ecnt_msb][0]} <= i_Q;
            end
            2'b01 :  begin
              {line_buffer[ecnt_msb][15], line_buffer[ecnt_msb][14], line_buffer[ecnt_msb][13], line_buffer[ecnt_msb][12], 
              line_buffer[ecnt_msb][11], line_buffer[ecnt_msb][10], line_buffer[ecnt_msb][9], line_buffer[ecnt_msb][8]} <= i_Q;
            end
            2'b10 :  begin
              {line_buffer[ecnt_msb][23], line_buffer[ecnt_msb][22], line_buffer[ecnt_msb][21], line_buffer[ecnt_msb][20], 
              line_buffer[ecnt_msb][19], line_buffer[ecnt_msb][18], line_buffer[ecnt_msb][17], line_buffer[ecnt_msb][16]} <= i_Q;
            end
            2'b11 :  begin
              {line_buffer[ecnt_msb][31], line_buffer[ecnt_msb][30], line_buffer[ecnt_msb][29], line_buffer[ecnt_msb][28], 
              line_buffer[ecnt_msb][27], line_buffer[ecnt_msb][26], line_buffer[ecnt_msb][25], line_buffer[ecnt_msb][24]} <= i_Q;
            end
          endcase
        end
      endcase
    end

    Conv_Shift: begin
      case(size)
        2'd0 : begin 
          if (stop_c) begin 
            for (i = 0; i <= 3; i = i + 1) begin
              for (j = 0; j <= 7; j = j + 1) begin
                if (j>=3) line_buffer[i][j] <= line_buffer[i+1][j-3];  
                else line_buffer[i][j] <= line_buffer[i][j+5];        ///// shift 5
              end
            end

            {line_buffer[4][7], line_buffer[4][6], line_buffer[4][5], line_buffer[4][4], 
            line_buffer[4][3], line_buffer[4][2], line_buffer[4][1], line_buffer[4][0]} <= i_Q;
          end

          else begin                        
            for (i = 0; i <= 3; i = i + 1) begin
              for (j = 0; j <= 7; j = j + 1) begin
                if (j==7) line_buffer[i][j] <= line_buffer[i+1][0];  
                else line_buffer[i][j] <= line_buffer[i][j+1];        ///// shift 1 
              end
            end
            for (j = 0; j <= 6; j = j + 1) begin
              line_buffer[4][j] <= line_buffer[4][j+1];
            end
          end
        end
        2'd1 : begin 
          // No. 0~3 line buffer
          if (stop_c) begin 
            for (i = 0; i <= 3; i = i + 1) begin
              for (j = 0; j <= 15; j = j + 1) begin
                if (j>=11) line_buffer[i][j] <= line_buffer[i+1][j-11];  
                else line_buffer[i][j] <= line_buffer[i][j+5];        ///// shift 5
              end
            end
          end
          else begin
            for (i = 0; i <= 3; i = i + 1) begin
              for (j = 0; j <= 15; j = j + 1) begin
                if (j==15) line_buffer[i][j] <= line_buffer[i+1][0];  
                else line_buffer[i][j] <= line_buffer[i][j+1];        ///// shift 1 
              end
            end
          end

          // No. 4 line buffer
          if (stop_c) begin
            {line_buffer[4][15], line_buffer[4][14], line_buffer[4][13], line_buffer[4][12], 
            line_buffer[4][11], line_buffer[4][10], line_buffer[4][9], line_buffer[4][8]} <= i_Q;
            for (j = 0; j <= 7; j = j + 1) line_buffer[4][j] <= line_buffer[4][j+5];   ///// shift 5
          end

          else if (shift_cnt_eq_7) begin
            {line_buffer[4][15], line_buffer[4][14], line_buffer[4][13], line_buffer[4][12], 
            line_buffer[4][11], line_buffer[4][10], line_buffer[4][9], line_buffer[4][8]} <= i_Q;
            for (j = 0; j <= 7; j = j + 1) line_buffer[4][j] <= line_buffer[4][j+1];   ///// shift 1
          end

          else begin
            for (j = 0; j <= 14; j = j + 1) begin
              line_buffer[4][j] <= line_buffer[4][j+1];
            end
          end
        end

        2'd2 : begin 
          // No. 0~3 line buffer
          if (stop_c) begin 
            for (i = 0; i <= 3; i = i + 1) begin
              for (j = 0; j <= 31; j = j + 1) begin
                if (j>=27) line_buffer[i][j] <= line_buffer[i+1][j-27];  
                else line_buffer[i][j] <= line_buffer[i][j+5];        ///// shift 5
              end
            end
          end
          else begin
            for (i = 0; i <= 3; i = i + 1) begin
              for (j = 0; j <= 31; j = j + 1) begin
                if (j==31) line_buffer[i][j] <= line_buffer[i+1][0];  
                else line_buffer[i][j] <= line_buffer[i][j+1];        ///// shift 1 
              end
            end
          end

          // No. 4 line buffer
          if (stop_c) begin
            {line_buffer[4][31], line_buffer[4][30], line_buffer[4][29], line_buffer[4][28], 
            line_buffer[4][27], line_buffer[4][26], line_buffer[4][25], line_buffer[4][24]} <= i_Q;
            for (j = 0; j <= 23; j = j + 1) line_buffer[4][j] <= line_buffer[4][j+5];   ///// shift 5
          end

          else if (shift_cnt_eq_7) begin
            {line_buffer[4][31], line_buffer[4][30], line_buffer[4][29], line_buffer[4][28], 
            line_buffer[4][27], line_buffer[4][26], line_buffer[4][25], line_buffer[4][24]} <= i_Q;
            for (j = 0; j <= 23; j = j + 1) line_buffer[4][j] <= line_buffer[4][j+1];   ///// shift 1
          end

          else begin
            for (j = 0; j <= 30; j = j + 1) begin
              line_buffer[4][j] <= line_buffer[4][j+1];
            end
          end
        end
      endcase
    end

    DeConv_Shift: begin 
      case(size)
        2'd0 : begin 
          for (i = 0; i <= 3; i = i + 1) begin
            for (j = 0; j <= 7; j = j + 1) begin
              if (j==7) line_buffer[i][j] <= line_buffer[i+1][0];  
              else line_buffer[i][j] <= line_buffer[i][j+1];       ///// shift 1
            end
          end

          if (shift_cnt_eq_7) begin
            {line_buffer[4][7], line_buffer[4][6], line_buffer[4][5], line_buffer[4][4], 
            line_buffer[4][3], line_buffer[4][2], line_buffer[4][1], line_buffer[4][0]} <= i_Q;
          end
          else begin
            for (j = 0; j <= 6; j = j + 1) begin
              line_buffer[4][j] <= line_buffer[4][j+1];
            end
          end
        end

        2'd1 : begin 
          for (i = 0; i <= 3; i = i + 1) begin
            for (j = 0; j <= 15; j = j + 1) begin
              if (j==15) line_buffer[i][j] <= line_buffer[i+1][0];  
              else line_buffer[i][j] <= line_buffer[i][j+1];       ///// shift 1
            end
          end

          if (shift_cnt_eq_7) begin
            {line_buffer[4][15], line_buffer[4][14], line_buffer[4][13], line_buffer[4][12], 
            line_buffer[4][11], line_buffer[4][10], line_buffer[4][9], line_buffer[4][8]} <= i_Q;
            for (j = 0; j <= 7; j = j + 1) line_buffer[4][j] <= line_buffer[4][j+1];
          end
          else begin
            for (j = 0; j <= 14; j = j + 1) begin
              line_buffer[4][j] <= line_buffer[4][j+1];
            end
          end
        end

        2'd2 : begin 
          for (i = 0; i <= 3; i = i + 1) begin
            for (j = 0; j <= 31; j = j + 1) begin
              if (j==31) line_buffer[i][j] <= line_buffer[i+1][0];  
              else line_buffer[i][j] <= line_buffer[i][j+1];       ///// shift 1
            end
          end

          if (shift_cnt_eq_7) begin
            {line_buffer[4][31], line_buffer[4][30], line_buffer[4][29], line_buffer[4][28], 
            line_buffer[4][27], line_buffer[4][26], line_buffer[4][25], line_buffer[4][24]} <= i_Q;
            for (j = 0; j <= 23; j = j + 1) line_buffer[4][j] <= line_buffer[4][j+1];
          end
          else begin
            for (j = 0; j <= 30; j = j + 1) begin
              line_buffer[4][j] <= line_buffer[4][j+1];
            end
          end
        end
      endcase
    end
  endcase
end

//==============================================//
//                 Feature Map                  //
//==============================================// 
always@(*) begin
  for (i = 0; i <= 35; i = i + 1) for (j = 0; j <= 35; j = j + 1) feature_map_next[i][j] <= feature_map[i][j];
  case(state)
    DeConv_Shift: for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 4; j = j + 1) feature_map_next[rcnt+i][ccnt+j] <= feature_map[rcnt+i][ccnt+j] + mult1_z_se_next[i][j];
    Conv_Shift, Conv_Sum: feature_map_next[rcnt_d][ccnt_d] <= output_w1;
  endcase
end
always@(posedge clk) begin
  case(state)
    Idle2: for (i = 0; i <= 35; i = i + 1) for (j = 0; j <= 35; j = j + 1) feature_map[i][j] <= 20'b0;
    Conv_Shift, Conv_Sum, DeConv_Shift: for (i = 0; i <= 35; i = i + 1) for (j = 0; j <= 35; j = j + 1) feature_map[i][j] <= feature_map_next[i][j];
  endcase
end

//==============================================//
//                 Kernel Map                   //
//==============================================// 
always@(posedge clk) begin
  case(state)
    Conv_Fill, DeConv_Fill: begin
      {kernel_map[kcnt][4], kernel_map[kcnt][3], kernel_map[kcnt][2], kernel_map[kcnt][1], kernel_map[kcnt][0]} <= k_Q;
    end
    Conv_Shift, DeConv_Shift: for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 4; j = j + 1) kernel_map[i][j] <= kernel_map[i][j];
    default: for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 4; j = j + 1) kernel_map[i][j] <= 8'sbx;
  endcase
end

//==============================================//
//         mult1_a and mult2_a blocks           //
//==============================================//
always@(*) begin
    if (!md) begin
      for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 4; j = j + 1) mult1_a[i][j] <= line_buffer[i][j];
    end
    else begin
      for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 4; j = j + 1) mult1_a[i][j] <= line_buffer[0][0];
    end
end

//==============================================//
//         mult1_z signed extenstion            //
//==============================================//
always@(posedge clk) begin
  case(state)
    Conv_Fill, DeConv_Fill, Conv_Shift, DeConv_Shift: begin
      for (i = 0; i <= 4; i = i + 1) for (j = 0; j <= 4; j = j + 1) mult1_z_se[i][j] <= mult1_z_se_next[i][j];
    end
  endcase
end

//==============================================//
//                   Main FSM                   //
//==============================================//
always@(posedge clk) begin
  case (state)
    Idle :
      begin
        ecnt <= 7'b0;
        kcnt <= 3'b0;
        ncnt <= 4'b0;
        bcnt <= 3'b1;
        if (in_valid) begin
          size <= matrix_size;
          matrix_data <= matrix_data_next;
          case(matrix_size) 
            2'd0 : begin 
              stop_ecnt <= 7'd7;
              size_sub_1 <= 5'd7;
            end
            2'd1 : begin 
              stop_ecnt <= 7'd31;
              size_sub_1 <= 5'd15;
            end
            2'd2 : begin
              stop_ecnt <= 7'd127;
              size_sub_1 <= 5'd31;
            end
          endcase
        end
      end
    Read_img :
      begin
        matrix_data <= matrix_data_next;
        bcnt <= bcnt_next;
        if (stop_b) ecnt <= ecnt_next;
        if (stop_b && stop_e) ncnt <= ncnt_add_1;
      end
    Read_ker :
      begin
        matrix_data <= matrix_data_next;
        bcnt <= bcnt_next;
        if (stop_b) kcnt <= kcnt_next;
        if (stop_b && stop_k) ncnt <= ncnt_add_1;
      end
    Idle2 :
      begin
        ecnt <= 7'b0;
        kcnt <= 3'b0;
        pcnt <= 5'b0;
        ocnt <= 5'b0;
        occnt <= 6'b0;
        orcnt <= 6'b0;
        shift_cnt <= 3'd0;
        ccnt <= 5'd0;
        rcnt <= 5'd0;
        if(in_valid2) begin
          md <= mode;
          ii <= matrix_idx;
          case(size)
            2'd0 : stop_pcnt <= 5'd4;
            2'd1 : stop_pcnt <= 5'd9;
            2'd2 : stop_pcnt <= 5'd19;
          endcase
        end
      end
    Wait :
      begin
        if(in_valid2) begin
          ki <= matrix_idx;
        end
      end
    Conv_Fill :
      begin
        if (!stop_p) ecnt <= ecnt_next;
        kcnt <= kcnt_next;
        pcnt <= pcnt_add_1;
      end
    Conv_Shift :
      begin
        if (stop_e_next) ecnt <= ecnt;
        else if (shift_cnt_eq_7 || stop_c) ecnt <= ecnt_next;

        ccnt <= ccnt_next;
        if (stop_c) begin
          rcnt <= rcnt_next;
          shift_cnt <= 3'd0;
        end
        else shift_cnt <= shift_cnt_next;

        if (c_start_output) begin
          ocnt <= ocnt_next;
          if (stop_o) occnt <= occnt_next;
          if (stop_o && stop_oc) orcnt <= orcnt_next;
          if (stop_o && stop_oc && stop_or) ncnt <= ncnt_add_1;
        end
      end
    Conv_Sum, Conv_Done : 
      begin 
        ocnt <= ocnt_next;
        if (stop_o) occnt <= occnt_next;
        if (stop_o && stop_oc) orcnt <= orcnt_next;
        if (stop_o && stop_oc && stop_or) ncnt <= ncnt_add_1;
      end
      
    DeConv_Fill :
      begin
        if (!stop_p) ecnt <= ecnt_next;

        kcnt <= kcnt_next;
        pcnt <= pcnt_add_1;

        if (d_start_output) begin
          ocnt <= ocnt_next;
          if (stop_o) occnt <= occnt_next;
          if (stop_o && stop_oc) orcnt <= orcnt_next;
          if (stop_o && stop_oc && stop_or) ncnt <= ncnt_add_1;
        end
      end
    
    DeConv_Shift :
      begin
        if (stop_e_next) ecnt <= ecnt;
        else if (shift_cnt_eq_7) ecnt <= ecnt_next;

        shift_cnt <= shift_cnt_next;
        ccnt <= ccnt_next;
        if (stop_c) rcnt <= rcnt_next;

        ocnt <= ocnt_next;
        if (stop_o) occnt <= occnt_next;
        if (stop_o && stop_oc) orcnt <= orcnt_next;
        if (stop_o && stop_oc && stop_or) ncnt <= ncnt_add_1;
      end
    DeConv_Done :
      begin
        ocnt <= ocnt_next;
        if (stop_o) occnt <= occnt_next;
        if (stop_o && stop_oc) orcnt <= orcnt_next;
        if (stop_o && stop_oc && stop_or) ncnt <= ncnt_add_1;
      end
  endcase
end

//==============================================//
//                   Ans                        //
//==============================================//
always@(*) begin
  ans_next <= ans >> 1;
  case(state)
    Conv_Shift, Conv_Sum, Conv_Done: if (ocnt_eq_0) ans_next <= max_pool_result;
    DeConv_Fill: if (ocnt_eq_0) ans_next <= mult1_z_se_next[0][0];  
    DeConv_Shift, DeConv_Done: if (ocnt_eq_0) ans_next <= feature_map_next[orcnt][occnt];
  endcase
end
always@(posedge clk) begin
  ans <= ans_next;
end

//==============================================//
//                Output                        //
//==============================================//
always@(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_valid <= 1'b0;
    out_value <= 1'b0;
  end 
  else begin
    case(state)
      Conv_Shift: begin
        if (c_start_output) begin
          out_valid <= 1'b1;
          out_value <= ans_next[0];
        end
      end
      Conv_Sum, Conv_Done: begin 
        out_valid <= 1'b1;
        out_value <= ans_next[0];
      end
      DeConv_Fill: begin
        if (d_start_output) begin
          out_valid <= 1'b1;
          out_value <= ans_next[0];
        end
      end
      DeConv_Shift, DeConv_Done: begin
        out_valid <= 1'b1;
        out_value <= ans_next[0];
      end
      default: begin
        out_valid <= 1'b0;
        out_value <= 1'b0;
      end
    endcase
  end
end

endmodule


