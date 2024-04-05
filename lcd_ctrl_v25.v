/******************************************************************/
// MODULE    :  LCD_CTRL
// VERSION   :  2.5
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

reg IROM_EN;
reg [5:0] IROM_A;
reg IRB_RW;
reg [7:0] IRB_D;
reg [5:0] IRB_A;
reg busy;
reg done;

parameter INIT=2'b00;
parameter WORK=2'b01;
parameter WRIT=2'b10;
parameter DONE=2'b11;

parameter write=3'd0;
parameter sftUP=3'd1;
parameter sftDN=3'd2;
parameter sftLF=3'd3;
parameter sftRT=3'd4;
parameter avrge=3'd5;
parameter mirrX=3'd6;
parameter mirrY=3'd7;

//state ctrl
reg	[1:0]cs,ns;

always@(posedge clk or posedge reset)begin
	if (reset)	cs<=DONE;
	else		cs<=ns;
end

//state machine
wire INIT_done;
wire write_val=cmd_valid&(~|cmd);
wire WRIT_done;
always@(*)begin
	case(cs)
	DONE:
		begin
		ns<=(reset)?INIT:DONE;
		IROM_EN<=1;	IRB_RW<=1;
		busy<=0;	done<=1;
		end
	INIT:
		begin
		ns<=(INIT_done)?WORK:INIT;
		IROM_EN<=0;	IRB_RW<=1;
		busy<=1;	done<=0;
		end
	WORK:
		begin
		ns<=(write_val)?WORK:INIT;
		IROM_EN<=1;	IRB_RW<=1;
		busy<=0;	done<=0;
		end
	WRIT:
		begin
		ns<=(WRIT_done)?done:WRIT;
		IROM_EN<=1;	IRB_RW<=0;
		busy<=1;	done<=0;
		end	
	endcase
end

//counter
wire [5:0]	cnt,cnt1;
reg  [5:0]	cnt$;
assign cnt=cnt$;
//module add1_6(A,S);
add1_6 a1(cnt,cnt1);

always@(posedge clk)begin
	if (cs[0])	cnt$ <= 0;
	else 		cnt$ <= cnt1;
end

assign INIT_done=&cnt;
assign WRIT_done=&cnt;

reg [7:0]img[0:63];

wire work_valid=cmd_valid&(~cs[1])&cs[0];

//operation point
//WORK: operating
reg [2:0]opX,opY;
wire [2:0]opX_a1,opX_s1,opY_a1,opY_s1;
//module add1_3(A,S);
add1_3 a2(opX,opX_a1);
add1_3 a3(opY,opY_a1);
//module sub1_3(A,S);
sub1_3 a4(opX,opX_s1);
sub1_3 a5(opY,opY_s1);

always@(posedge clk)begin
	if(work_valid)
		begin
		case(cmd)
		sftUP:	begin	opY <= (opY==1)?opY:opY_s1;	end
		sftDN:	begin	opY <= (&opY)?	opY:opY_a1;	end
		sftLF:	begin	opX <= (opX==1)?opX:opX_s1;	end
		sftRT:	begin	opX <= (&opX)?	opX:opX_a1;	end
		default:	begin	opX <= opX;	opY <= opY;	end
		endcase
		end
	else
		begin
		opX <= 3'd4;
		opY <= 3'd4;
		end
end

//position
wire [5:0]pos1,pos2,pos3,pos4;
assign pos4={opY,opX};
assign pos1={opY,opX}-6'd9;		//  1    2
assign pos2={opY,opX}-6'd8;		//    op
assign pos3={opY,opX}-6'd1;		//  3    4
wire [9:0]sum;
assign sum=img[pos1]+img[pos2]+img[pos3]+img[pos4];

reg [7:0]ndpos1,ndpos2,ndpos3,ndpos4;
always@(*)begin
	case(cmd)
	mirrX:
		begin
		ndpos1 <= img[pos3];	ndpos2 <= img[pos4];
		ndpos3 <= img[pos1];	ndpos4 <= img[pos2];
		end
	mirrY:
		begin
		ndpos1 <= img[pos2];	ndpos2 <= img[pos1];
		ndpos3 <= img[pos4];	ndpos4 <= img[pos3];
		end
	avrge:
		begin
		ndpos1 <= sum[9:2];		ndpos2 <= sum[9:2];
		ndpos3 <= sum[9:2];		ndpos4 <= sum[9:2];		
		end
	default:
		begin
		ndpos1 <= img[pos1];	ndpos2 <= img[pos2];
		ndpos3 <= img[pos3];	ndpos4 <= img[pos4];
		end
	endcase
end

//img processing
always@(negedge clk)begin
	case(cs)
	INIT:
		begin
		IROM_A	 <= cnt;
		img[cnt] <= IROM_Q;
		end
	WORK:
		if(cmd_valid)
			begin
			img[pos1] <= ndpos1;
			img[pos2] <= ndpos2;
			img[pos3] <= ndpos3;
			img[pos4] <= ndpos4;
			end
		else ;
	WRIT:
		begin
		IRB_A <= cnt;
		IRB_D <= img[cnt];
		end
	DONE: ;
	endcase
end

endmodule

/*#########################*/
/*--------submodule--------*/
/*#########################*/
module add1_6(A,S);
input [5:0]A;
output [5:0]S;
wire [5:0]C;
assign C[0]=1'b1;
assign C[1]=A[0];
assign C[2]=C[1]&A[1];
assign C[3]=C[2]&A[2];
assign C[4]=C[3]&A[3];
assign C[5]=C[4]&A[4];
assign S=A^C;
endmodule

module add1_3(A,S);
input [2:0]A;
output [2:0]S;
wire [2:0]C;
assign C[0]=1'b1;
assign C[1]=A[0];
assign C[2]=C[1]&A[1];
assign S=A^C;
endmodule

module sub1_3(A,S);
input [2:0]A;
output [2:0]S;
wire [2:0]C;
assign C[0]=0;
assign C[1]=A[0];
assign C[2]=C[1]|A[1];
assign S=~(A^C);
endmodule

