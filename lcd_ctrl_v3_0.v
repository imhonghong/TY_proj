/******************************************************************/
// MODULE    :  LCD_CTRL
// VERSION   :  3.1
// TEAMS     :  Hung, Song
// DATE      :  Feb, 2024
// CODE TYPE :  RTL
/******************************************************************/
module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output IROM_EN;
output [5:0] IROM_A;
output IRB_RW;
output [7:0] IRB_D;
output [5:0] IRB_A;
output busy;
output done;

parameter ST_WRIT = 4'd0;
parameter ST_SHUP = 4'd1;
parameter ST_SHDN = 4'd2;
parameter ST_SHLT = 4'd3;
parameter ST_SHRT = 4'd4;
parameter ST_AVEG = 4'd5;
parameter ST_MIRX = 4'd6;
parameter ST_MIRY = 4'd7;
parameter ST_REST = 4'd8;
parameter ST_READ = 4'd9;
//parameter ST_DONE = 4'd10;

reg [3:0] cs,ns;
reg [7:0] img [0:63];
reg [5:0] cnt;
reg IROM_EN;
//reg [7:0] IRB_D;
reg busy;
reg done;
reg IRB_RW;
reg [5:0] pos1;
wire [5:0] pos2;
wire [5:0] pos3;
wire [5:0] pos4;
wire [9:0] sum;
wire cntzero;
//wire IROM_EN;

assign pos2 = pos1 + 6'd1;
assign pos3 = pos1 + 6'd8;
assign pos4 = pos1 + 6'd9;
assign sum = (img[pos1] + img[pos2]) + (img[pos3] + img[pos4]);
assign cntzero = reset | (~busy);

always @(negedge clk or posedge reset) begin
    if(reset)
        cs <= ST_REST;
    else
        cs <= ns;
end

always @(*) begin
    case (cs)
        //ST_WRIT: ns = (IRB_A == 6'h3f)? ST_DONE : ST_WRIT;
        ST_WRIT: ns = ST_WRIT;
		ST_SHUP: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_SHDN: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_SHLT: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_SHRT: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_AVEG: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_MIRX: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_MIRY: ns = (cmd_valid)? cmd : ST_WRIT;
        ST_REST: ns = (IROM_EN)? ST_REST : ST_READ;
        ST_READ: ns = (cmd_valid)? cmd : ST_READ;
        //ST_DONE: ns = ST_DONE;
        default: ns = ST_REST;
    endcase
end

always @(negedge clk or posedge cntzero) begin
    if (cntzero)
        cnt <= 6'd0;
    else if(busy == 1'd1)
        cnt <= cnt + 6'd1;
    else
        cnt <= cnt;
end

assign IROM_A = (ns == ST_READ)? cnt : IROM_A;
assign IRB_A = (ns == ST_WRIT)? cnt : IRB_A;

always @(posedge clk) begin
    case (cs)
    ST_READ: begin
        img[IROM_A-6'd1] <= IROM_Q;
    end
    ST_AVEG: begin
        img[pos1] <= sum[9:2];
        img[pos2] <= sum[9:2];
        img[pos3] <= sum[9:2];
        img[pos4] <= sum[9:2];
    end
    ST_MIRX: begin
        img[pos1] <= img[pos3];
        img[pos2] <= img[pos4];
        img[pos3] <= img[pos1];
        img[pos4] <= img[pos2];
    end
    ST_MIRY: begin
        img[pos1] <= img[pos2];
        img[pos2] <= img[pos1];
        img[pos3] <= img[pos4];
        img[pos4] <= img[pos3];
    end
    default: begin
        img[pos1] <= img[pos1];
        img[pos2] <= img[pos2];
        img[pos3] <= img[pos3];
        img[pos4] <= img[pos4];
    end
    endcase
end

always @(negedge clk) begin
    if (IROM_A == 6'h3f)
        pos1 <= 6'h1b;
    else begin
        case (cs)
            ST_SHUP: pos1 <= (pos1 >= 6'd8)? pos1-6'd8 : pos1;
            ST_SHDN: pos1 <= (pos1 <= 6'd46)? pos1+6'd8 : pos1;
            ST_SHLT: pos1 <= (pos1[2:0] == 3'd0)? pos1 : pos1-6'd1;
            ST_SHRT: pos1 <= (pos2[2:0] == 3'd7)? pos1 : pos1+6'd1;
            default: pos1 <= pos1;
        endcase
    end
end

assign IRB_D = img[IRB_A];

/*
always @(negedge clk or reset) begin
    if (reset)
        IRB_D <= 8'h0;
    else if (cs == ST_WRIT)
        IRB_D <= img[IRB_A];
    else
        IRB_D <= IRB_D;
end
*/

always @(negedge clk or posedge reset) begin
    if(reset)
        busy <= 1'd1;
    else if(IROM_A == 6'h3f)
        busy <= 1'd0;
	else if(cmd == 1'd0)
        busy <= 1'd1;
    else
        busy <= busy;
end

// assign IROM_EN = 1'd0;

always @(negedge clk or posedge reset) begin
    if(reset)
        IROM_EN <= 1'd0;
    else if(IROM_A == 6'h3f)
        IROM_EN <= 1'b1;
    else
        IROM_EN <= IROM_EN;
end

// assign done = (IRB_A == 6'h3f)? 1'd1:1'd0;
// assign done = (cs == ST_DONE)? 1'd1 : 1'd0;

always @(negedge clk or posedge reset) begin
    if(reset)
		done <= 1'd0;
	else if(IRB_A == 6'h3f)
        done <= 1'd1;
    else
        done <= 1'd0;
end

// assign IRB_RW = (cs == ST_WRIT)? 1'd0 : 1'd1;

always @(negedge clk or posedge reset) begin
    if(reset)
        IRB_RW <= 1'd1;
    else if(cmd == 1'd0)
        IRB_RW <= 1'd0;
    else
        IRB_RW <= IRB_RW;
end

endmodule