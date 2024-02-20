module TT (
  // Input port
  clk,
  rst_n,
  in_valid,
  source,
  destination,
  // Output port
  out_valid,
  cost
);

input clk, rst_n, in_valid;
input [3:0] source, destination;
output reg out_valid;
output reg [3:0] cost;

parameter [1:0] Idle = 0; 
parameter [1:0] Read = 1;
parameter [1:0] Search = 2;
parameter [1:0] Done1 = 3;

integer i, j;
genvar g_i, g_j;

reg [1:0] state, next_state;

reg [3:0] d;
reg [3:0] dis;
reg e[0:15][0:15];
reg v[0:15];
wire v_next[0:15];

// Use BFS update v (heck whether each node can be accessed)
generate
  for (g_i=0; g_i<=15; g_i=g_i+1) begin : test2
    assign v_next[g_i] = ( (v[0]&&e[0][g_i])   || (v[1]&&e[1][g_i])   || (v[2]&&e[2][g_i])   || (v[3]&&e[3][g_i])   || 
                           (v[4]&&e[4][g_i])   || (v[5]&&e[5][g_i])   || (v[6]&&e[6][g_i])   || (v[7]&&e[7][g_i])   ||
                           (v[8]&&e[8][g_i])   || (v[9]&&e[9][g_i])   || (v[10]&&e[10][g_i]) || (v[11]&&e[11][g_i]) ||
                           (v[12]&&e[12][g_i]) || (v[13]&&e[13][g_i]) || (v[14]&&e[14][g_i]) || (v[15]&&e[15][g_i])  );
  end
endgenerate

// access destination
wire bfs_found;
assign bfs_found = v_next[d];

// bfs end criteria
wand bfs_end;
generate
	for (g_i = 0; g_i <= 15; g_i = g_i + 1) begin : test4
		assign bfs_end = (v[g_i] == v_next[g_i]);
	end
endgenerate

// Current state logic (sequential)
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) state <= Idle;
  else state <= next_state;
end

// Next state logic (combinational)
always@(*) begin
  if (!rst_n) next_state = Idle;
  else begin
    case(state)
      Idle: begin
        if (in_valid) next_state = Read;
        else next_state = Idle;
      end
      Read: begin
        if (in_valid) next_state = Read;
        else begin
          if (bfs_found) next_state = Done1;
          else next_state = Search;
        end
      end
      Search: begin
        if(bfs_found || bfs_end) next_state = Idle;
        else next_state = Search;
      end
      Done1: next_state = Idle;
      default:next_state = state;
    endcase
  end
end

always@(posedge clk) begin
  case(state)
    Idle: begin
      // Initialize e
      for (i = 0; i <= 15; i = i + 1) begin
				for (j = 0; j <= 15; j = j + 1) begin
          if (i==j) e[i][j] <= 1'b1;
          else e[i][j] <= 1'b0;
        end
      end

      // Initiaize v
      for (i=0; i<=15; i=i+1) v[i] <= 1'b0;
      // Source & Destination
      dis <= 4'd0;
      v[source] <= 1'b1;
      d <= destination;
    end
    Read: begin
      if (in_valid) begin
        e[source][destination] <= 1'b1;
        e[destination][source] <= 1'b1;
        dis <= 4'd0;
      end

      else begin
        for (i=0; i<=15; i=i+1) v[i] <= v_next[i];
        dis <= dis + 1'b1;
      end
    end
    
    Search: begin
      for (i=0; i<=15; i=i+1) v[i] <= v_next[i];
      dis <= dis + 1'b1;
    end
    Done1: dis <= dis;
  endcase
end

// out_valid
always@(*) begin
  out_valid = 0;
  case(state)
    Idle, Read: out_valid = 1'b0;
    Search: begin
      if (bfs_found || bfs_end) out_valid = 1'b1;
      else out_valid = 1'b0;
    end
    Done1: out_valid = 1'b1;
  endcase
end

// cost
always@(*) begin
  cost = 0;
  case(state)
    Idle, Read : cost = 1'b0;
    Search : begin 
      if (bfs_found) cost = dis + 1'b1;
      else cost = 1'b0;
    end
    Done1 : cost = dis;
    default:cost = cost;
  endcase
end








/*
// out_valid
always@(posedge clk or negedge rst_n) begin
  if (!rst_n) out_valid <= 0;
  else begin
    case(next_state)
      Idle, Read, Search: out_valid <= 1'b0;
      Done : out_valid <= 1'b1;
    endcase
  end
end

// cost
always@(posedge clk or negedge rst_n) begin
  if (!rst_n) cost <= 0;
  else begin
    case(next_state)
      Idle, Read, Search: cost <= 1'b0;
      Done : begin 
        if (bfs_found) cost <= dis + 1'b1;
        else cost <= 1'b0;
      end
      default:cost <= cost;
    endcase
  end
end
*/
endmodule


