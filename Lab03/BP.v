module BP (
  // Input port
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  // Output port
  out_valid,
  out
);

input clk, rst_n, in_valid;
input [2:0] guy;
input [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg out_valid;
output reg [1:0] out;

parameter [1:0] Idle = 0; 
parameter [1:0] Scan = 1;
parameter [1:0] Update = 2;
parameter [1:0] Done = 3;

integer i;
//genvar i;

reg [1:0] state, next_state;
reg [5:0] cnt;
wire [5:0] cnt_add_1 = cnt + 6'd1;

reg [5:0] pivot1_x, pivot2_x;
reg [2:0] pivot1_y, pivot2_y, pivot2_y_next;
reg pivot2_h, pivot2_h_next;

reg [1:0] out_move [0:62];
reg [1:0] out_move_next [0:62];
wire [1:0] out_next;
assign out_next = out_move[cnt_add_1];

assign ob_flag = |(in0 & in1 & in2 & in3 & in4 & in5 & in6 & in7);

wire [7:0] ob_index;
assign ob_index = {(^in7), (^in6), (^in5), (^in4), (^in3), (^in2), (^in1), (^in0)};

wire [2:0] offset1, offset2;
assign offset1 = pivot2_y - pivot1_y;
assign offset2 = pivot1_y - pivot2_y;

// next pivot2 logic
always@(*) begin
  case(ob_index)
    8'b00000001: 
      begin
        pivot2_y_next = 3'b000;
        pivot2_h_next = in0[0];
      end
    8'b00000010: 
      begin
        pivot2_y_next = 3'b001; 
        pivot2_h_next = in1[0];
      end
    8'b00000100:
      begin
        pivot2_y_next = 3'b010; 
        pivot2_h_next = in2[0];
      end
    8'b00001000:
      begin
        pivot2_y_next = 3'b011; 
        pivot2_h_next = in3[0];
      end
    8'b00010000:  
      begin
        pivot2_y_next = 3'b100; 
        pivot2_h_next = in4[0];
      end
    8'b00100000:
      begin
        pivot2_y_next = 3'b101; 
        pivot2_h_next = in5[0];
      end
    8'b01000000:
      begin
        pivot2_y_next = 3'b110; 
        pivot2_h_next = in6[0];
      end
    8'b10000000:
      begin
        pivot2_y_next = 3'b111; 
        pivot2_h_next = in7[0];
      end
    default: 
      begin
        pivot2_y_next = pivot2_y;
        pivot2_h_next = pivot2_h;
      end
  endcase
end

always@(*) begin
  for (i=0; i<=62; i=i+1) begin 
    // in the range 
    if ((i >= pivot1_x) && (i < pivot2_x)) begin
      // need to go right
      if (pivot2_y > pivot1_y) begin
        if ((i + 1 == pivot2_x) && (pivot2_h)) begin
          out_move_next[i] = 2'b11;
        end
        else if (i < pivot1_x + offset1) begin
          out_move_next[i] = 2'b01; // turn right
        end
        else begin
          out_move_next[i] = 2'b00; // go straight
        end
      end
      // need to go left
      else if (pivot2_y < pivot1_y) begin
        if ((i + 1 == pivot2_x) && (pivot2_h)) begin
          out_move_next[i] = 2'b11;
        end
        else if (i < pivot1_x + offset2) begin
          out_move_next[i] = 2'b10; // turn left
        end
        else begin
          out_move_next[i] = 2'b00; // go straight
        end
      end
      // need to go straight
      else begin
        if ((i + 1 == pivot2_x) && (pivot2_h)) begin
          out_move_next[i] = 2'b11;
        end
        else begin
          out_move_next[i] = 2'b00; // go straight
        end
      end
    end
    // out of range
    else begin
      out_move_next[i] = out_move[i];
    end
  end
end

// Current state logic (sequential)
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) state <= Idle;
  else state <= next_state;
end

// Next state logic (combinational)
always@(*) begin
  next_state = state;
  case(state)
    Idle: begin
      if (in_valid) next_state = Scan;
    end
    Scan: begin
      if (ob_flag) next_state = Update;
      else if (cnt == 6'd63) next_state = Done;
    end
    Update: begin
      if (cnt == 6'd63) next_state = Done;
      else next_state = Scan;
    end
    Done: begin
      if (cnt == 6'd62) next_state = Idle;
    end
  endcase
end

always@(posedge clk) begin
  case(state)
    Idle: begin
      // Initialize cnt
      cnt <= 6'd0;
      // Initialize pivot1, pivot2
      pivot1_x <= 6'd0;
      pivot1_y <= guy;
      pivot2_x <= 6'd0;
      pivot2_y <= guy;
      pivot2_h <= 1'b0;

      // Initialize out_move
      for (i = 0; i <= 62; i = i + 1) out_move[i] <= 2'b00;
    end
    Scan: begin
      cnt <= cnt_add_1;
      if (ob_flag) begin
        pivot1_x <= pivot2_x;
        pivot1_y <= pivot2_y;
        pivot2_x <= cnt_add_1;
        pivot2_y <= pivot2_y_next;
        pivot2_h <= pivot2_h_next;
      end
    end
    Update: begin
      cnt <= cnt_add_1;
      for (i = 0; i <= 62; i = i + 1) out_move[i] <= out_move_next[i];
    end
    Done: cnt <= cnt_add_1;
  endcase
end

// out & out_valid
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    out_valid <= 1'b0;
    out <= 2'b00;
  end
  else begin
    case(next_state)
      Done: begin
        out_valid <= 1'b1;
        out <= out_next;
      end
      default: begin
        out_valid <= 1'b0;
        out <= 2'b00;
      end
    endcase
  end
end

endmodule


