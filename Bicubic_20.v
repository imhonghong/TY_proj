module Bicubic (
input CLK,
input RST,
input [6:0] V0,
input [6:0] H0,
input [4:0] SW,
input [4:0] SH,
input [5:0] TW,
input [5:0] TH,
output reg DONE);


wire 		cen_inn,	cen_out,	wen_out;
reg			cen_inn$,	cen_out$,	wen_out$;
reg 		RD_FIN,		WK_FIN,		WT_FIN;
wire [7:0]	data_rd,	data_wrt;
wire [13:0]	addr_rd,	addr_wrt;


ImgROM u_ImgROM (.Q(data_rd), .CLK(CLK), .CEN(cen_inn), .A(addr_rd));
ResultSRAM u_ResultSRAM (.Q(), .CLK(CLK), .CEN(cen_out), .WEN(wen_out), .A(addr_wrt), .D(data_wrt));

parameter	[1:0]	READ=2'b00;
parameter	[1:0]	WORK=2'b01;
parameter	[1:0]	WRIT=2'b10;
parameter	[1:0]	DOON=2'b11;



//state part
reg [1:0]	cs,ns;
//state DFF
always@(posedge CLK or posedge RST)begin
	if(RST)	cs<=DOON;
	else	cs<=ns;
end
//control sig by state
always@(*)begin
	case(cs)
	DOON:	begin
			ns<=(RST)?		DOON:	READ;
			cen_inn$<=1;	cen_out$<=1;	wen_out$<=1;	DONE<=1;
			end
	READ:	begin
			ns<=(RD_FIN)?	WORK:	READ;
			cen_inn$<=0;	cen_out$<=1;	wen_out$<=1;	DONE<=0;
			end
	WORK:	begin
			ns<=(WK_FIN)?	WRIT:	WORK;
			cen_inn$<=1;	cen_out$<=1;	wen_out$<=1;	DONE<=0;
			end
	WRIT:	begin
			ns<=(WT_FIN)?	DOON:	WRIT;
			cen_inn$<=1;	cen_out$<=0;	wen_out$<=0;	DONE<=0;
			end
	endcase
end

assign 	cen_inn=cen_inn$;
assign 	cen_out=cen_out$;
assign	wen_out=wen_out$;

//read part
//addr_rd:read from data
//cnt_rd:store in our reg
reg 	[6:0]	H,	V;
reg		[7:0]	img[0:1023];
reg		[13:0]	addr_rd$,cnt_rd,cnt_H;
wire	[13:0]	SCALE_RD;

assign	addr_rd=addr_rd$;
assign SCALE_RD=(SW+2)*(SH+2);
always@(posedge CLK or posedge RST)	begin
	if(RST)	
		begin
		H = H0-1;	V = V0-1;
		addr_rd$ = 100*V+H;
		cnt_rd = 0;	
		cnt_H = 0;
		RD_FIN = 0;
		end
	else if(cs==READ)
		begin
		if(cnt_rd < SCALE_RD)
			begin
			RD_FIN = 0;
			img[cnt_rd] = data_rd;
			cnt_rd = cnt_rd+1;
			if(cnt_H<=SW+1)
				begin
				H = H+1;
				cnt_H = cnt_H+1;
				addr_rd$ = 100*V+H;
				end
			else
				begin
				H = H0-1;
				cnt_H = 0;
				V = V+1;
				addr_rd$ = addr_rd$+99-SW;
				end
			end
		else
			begin
			RD_FIN = 1;
			end
		end
	else ;
end
//work part
reg [7:0] 	cnt_iH;
reg [15:0]	cnt_workall;
wire [7:0]	fenmu_H,	fenzi_H,	Q_H,	R_H;
wire fenzi_H = SW-1;
wire fenmu_H = TW-1;
wire Q_H = (cnt_iH-1)*fenzi_H / fenmu_H +1;
wire R_H = cnt_iH*fenzi_H % fenmu_H ;

always@(posedge CLK or posedge RST)begin
	if(RST)
		begin
		cnt_workall = 0;
		cnt_iH = 0;
		WK_FIN = 0;
		end
	else if (cs==WORK)
		begin
		if (cnt_workall<SCALE_WRT)
			begin
			cnt_workall = cnt_workall+1;
			cnt_iH = cnt_iH+1;
			addr_1 = Q_H;

			end
		end
		else
			begin
			WK_FIN = 1;
			end
	else ;

end

//write part
reg		[13:0]	addr_wrt$;
reg		[7:0]	data_wrt$;
wire 	[13:0]	SCALE_WRT;
assign 	SCALE_WRT = TW*TH;
assign	addr_wrt = addr_wrt$;
assign	data_wrt = data_wrt$;
always@(posedge CLK or posedge RST)	begin
	if(RST)
		begin
		addr_wrt$ = 0;
		WT_FIN = 0;
		end
	else if (cs==WRIT)
		begin
		if(addr_wrt$ < SCALE_WRT)
			begin
			data_wrt$ = img[addr_wrt$];	//modify here
			addr_wrt$ = addr_wrt$+1;
			WT_FIN = 0;
			end
		else
			begin
			WT_FIN = 1;
			end
		end

	else ;
end


endmodule


