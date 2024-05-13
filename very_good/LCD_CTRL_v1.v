/******************************************************************/
// MODULE    :  LCD_CTRL_v1
// VERSION   :  modified from v28, remove submodule and less pin
// TEAMS     :  Hung, Song
// DATE      :  Feb, 2024
// CODE TYPE :  RTL
/******************************************************************/
module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_EN, ADDR, IRB_RW, DATA, busy, done);
input clk;
input reset;
input [2:0] cmd;
input cmd_valid;
output IROM_EN;
output IRB_RW;
output busy;
output done;

//###################
/*DATA: input:IROM_Q, output:IRB_D*/
inout [7:0] DATA;
output [5:0] ADDR;
wire [7:0]DATA, IROM_Q;
reg [7:0] IRB_D;
//###################

//reg
reg busy;
reg IROM_EN;
reg IRB_RW;
reg done;
reg [5:0]IROM_A;
reg [5:0] IRB_A;

//define state parameter
parameter	[1:0]	INIT=2'b00;
parameter	[1:0]	WORK=2'b01;
parameter	[1:0]	WRIT=2'b11;
parameter	[1:0]	DONE=2'b10;
//define command parameter
parameter	[2:0]	WRTBK=3'd0;
parameter	[2:0]	OP_UP=3'd1;
parameter	[2:0]	OP_DN=3'd2;
parameter	[2:0]	OP_LF=3'd3;
parameter	[2:0]	OP_RT=3'd4;
parameter	[2:0]	AVRGE=3'd5;
parameter	[2:0]	MRR_X=3'd6;
parameter	[2:0]	MRR_Y=3'd7;

reg [6:0]pcnt,ncnt;
//state control
reg [1:0]cs;
reg [1:0]ns;
//state DFF
always@(posedge clk or posedge reset)begin
	if(reset)	cs<=INIT;
	else		cs<=ns;
end
//state FSM
wire ini_done;
wire wrt_done;
assign ini_done=ncnt[6]&ncnt[0];	//done when 65
assign wrt_done=(ncnt==7'd64)?1'b1:1'b0;		//done when 63

wire enterws;
assign enterws=(~|cmd)&cmd_valid;

always@(*)begin
	case(cs)
	INIT:	begin	ns<=(ini_done)?WORK:INIT;
					busy<=1'b1;
					IROM_EN<=1'b0;
					IRB_RW<=1'b1;
					done<=1'b0;
			end
	WORK:	begin	ns<=(enterws)?WRIT:WORK;
					busy<=1'b0;
					IROM_EN<=1'b1;
					IRB_RW<=1'b1;
					done<=1'b0;
			end
	WRIT:	begin	ns<=(wrt_done)?DONE:WRIT;
					busy<=1'b1;
					IROM_EN<=1'b1;
					IRB_RW<=1'b0;
					done<=1'b0;
			end
	DONE:	begin	ns<=DONE;
					busy<=1'b0;
					IROM_EN<=1'b1;
					IRB_RW<=1'b1;
					done<=1'b1;
			end
	endcase
end

/* ---------------------//
//	modify inout port	//
h ttps://blog.csdn.net/Times_poem/article/details/52037380
h ttps://blog.csdn.net/wordwarwordwar/article/details/78076120
------------------------*/
wire	sel_in;
assign sel_in = ~IROM_EN;		//sel_in=1 @ INIT state
assign ADDR =	(sel_in)? IROM_A : IRB_A;	//ADDR are always output
assign IROM_Q = (sel_in)? DATA : 8'hzz;	//DATA is inout, IROM_Q is the input
assign DATA =	(sel_in)? 8'hzz : IRB_D; //while IRB_D is the output of DATA

wire cntzero;
wire workstate;
assign workstate=(~cs[1])&cs[0];
assign cntzero=reset|workstate;

wire [6:0]pcnt1;
assign pcnt1= pcnt+7'd1;

//counter to generate addr
always@(posedge clk)begin
	if(cntzero)		begin pcnt<=0;			end
	else 			begin pcnt<=pcnt1;		end
end


always@(negedge clk)
	ncnt<=pcnt;


//operation point
reg [2:0] 	opX,opY;
wire [2:0]	opXa1,opXs1,opYa1,opYs1;

assign opXa1=opX+3'd1;
assign opYa1=opY+3'd1;
assign opXs1=opX-3'd1;
assign opYs1=opY-3'd1;

wire op_valid;
assign op_valid=(~cs[1])&cs[0]&cmd_valid;
always@(posedge clk)begin
	if(op_valid)begin
			case(cmd)
			OP_DN:	opY<=(&opY)?	opY:opYa1;
			OP_UP:	opY<=(opY==3'd1)?	opY:opYs1;
			OP_RT:	opX<=(&opX)?	opX:opXa1;
			OP_LF:	opX<=(opX==3'd1)?	opX:opXs1;
			default:	begin	opX<=opX;	opY<=opY;	end
			endcase
		end
	else begin
		opX<=3'd4;
		opY<=3'd4;
		end
end	


//img computation
reg  [7:0] img [0:63];
wire [5:0]pos1,pos2,pos3,pos4;
assign pos1={opY,opX}-6'd9;		//  1    2
assign pos2={opY,opX}-6'd8;		//    op
assign pos3={opY,opX}-6'd1;		//  3    4
assign pos4={opY,opX};
wire [9:0]sum;
assign sum=img[pos1]+img[pos2]+img[pos3]+img[pos4];

always@(negedge clk)begin
	case(cs)
	INIT:	begin
			if(ncnt>7'd0 && ncnt<7'd65) begin img[ncnt-1]<=IROM_Q; end
				else
					;
			IROM_A<=ncnt[5:0];
			end
	WORK:	if (cmd_valid)begin
				case(cmd)
				MRR_X:	begin
				img[pos1]<=img[pos3];	
				img[pos2]<=img[pos4];
				img[pos3]<=img[pos1];
				img[pos4]<=img[pos2];
				end
				MRR_Y:	begin
				img[pos1]<=img[pos2];	
				img[pos2]<=img[pos1];
				img[pos3]<=img[pos4];
				img[pos4]<=img[pos3];
				end
				AVRGE:	begin
				img[pos1]<=sum[9:2];	
				img[pos2]<=sum[9:2];
				img[pos3]<=sum[9:2];
				img[pos4]<=sum[9:2];
				end
				default:;
				endcase
			end
				else
					;
	WRIT:	begin
			IRB_A<=ncnt[5:0];
			IRB_D<=img[ncnt[5:0]];
			end
	DONE:	;
	endcase
end

endmodule