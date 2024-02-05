/******************************************************************/
// MODULE    :  LCD_CTRL
// VERSION   :  1.0
// TEAMS     :  Hung, Song
// DATE      :  Feb, 2024
// CODE TYPE :  RTL
/******************************************************************/

`timescale 1 ns/10 ps

module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
// ============     I/O ports     ============= //
// input
input            clk       ;
input            reset     ;
input      [7:0] IROM_Q    ;
input      [2:0] cmd       ;
input            cmd_valid ;
// output
output reg       IROM_EN   ;
output     [5:0] IROM_A    ;
output reg       IRB_RW    ;
output     [7:0] IRB_D     ;
output     [5:0] IRB_A     ;
output reg       busy      ;
output reg       done      ;


// ============     integer        ============= //
integer          index     ;


// ============      regester      ============= //
reg        [2:0] current_state  ;
reg        [2:0] next_state     ;
reg        [6:0] cnt            ; // count
reg              cnt_re         ; // count_reset
reg              cnt_en         ; // count_enable
reg              ctrl           ;
reg        [7:0] data [0:63]    ;
reg        [5:0] position_0     ;


// ==============      wire      =============== //
wire       [5:0] position_1 ; //  |  0  |  1  |
wire       [5:0] position_2 ; //  |-----|-----|
wire       [5:0] position_3 ; //  |  2  |  3  |
wire       [9:0] sum        ; //  -------------


// ============      parameter      ============= //
// pamameter of cmd
parameter  [2:0] Write      = 3'd0 ;
parameter  [2:0] ShiftUp    = 3'd1 ;
parameter  [2:0] ShiftDown  = 3'd2 ;
parameter  [2:0] ShiftLeft  = 3'd3 ;
parameter  [2:0] ShiftRight = 3'd4 ;
parameter  [2:0] Average    = 3'd5 ;
parameter  [2:0] MirrorX    = 3'd6 ;
parameter  [2:0] MirrorY    = 3'd7 ;
// parameter of state
parameter  [2:0] INITIAL    = 3'd0 ;
parameter  [2:0] READ       = 3'd1 ;
parameter  [2:0] OPERATE    = 3'd2 ;
parameter  [2:0] WRITE      = 3'd3 ;
parameter  [2:0] FINISH     = 3'd4 ;
// parameter of behavior
parameter        PosiProcess = 1'b0;
parameter        DataProcess = 1'b1;


// ==============      assign     =============== //
assign           IROM_A     = cnt[5:0];
assign           IRB_A      = cnt[5:0];
assign           IRB_D      = (current_state == WRITE) ? data[cnt[5:0]] : 8'd0;
assign           position_1 = position_0 + 6'd1;
assign           position_2 = position_0 + 6'd8;
assign           position_3 = position_0 + 6'd9;
assign           sum        = data[position_0] + data[position_1] + data[position_2] + data[position_3];


// =============== FSM state register =========== //
always @(posedge clk or posedge reset) begin
	if (reset)
        current_state <= INITIAL;
	else
        current_state <= next_state;
end

//============== FSM next state logic ============ //
always @(*) begin
	next_state  = current_state;
	case(current_state)
        INITIAL  : next_state = READ;
        READ     : next_state = cnt[6]              ? OPERATE : READ;
        OPERATE  : next_state = (cmd_valid & ~|cmd) ? WRITE   : OPERATE;
        WRITE    : next_state = cnt[6]              ? FINISH  : WRITE;
        FINISH   : next_state =                       FINISH  ;
	endcase
end


// ==============   control signal  ============== //
always @(*) begin
	busy      = 1'b1;
	done      = 1'b0;
	IROM_EN   = 1'b1;
	IRB_RW    = 1'b1;
	cnt_re    = 1'b0;
	cnt_en    = 1'b0;
	case(current_state)
		INITIAL : begin
			busy      = 1'b1;
			done      = 1'b0;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b1;
			cnt_re    = 1'b0;
			cnt_en    = 1'b0;
		end
		READ : begin
			busy      = 1'b1;
			done      = 1'b0;
			IROM_EN   = 1'b0;
			IRB_RW    = 1'b1;
			cnt_re    = cnt[6];
			cnt_en    = 1'b1;
		end
		OPERATE : begin
			busy      = 1'b0;
			done      = 1'b0;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b1;
			cnt_re    = 1'b0;
			cnt_en    = 1'b0;
		end
		WRITE : begin
			busy      = 1'b1;
			done      = 1'b0;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b0;
			cnt_re    = cnt[6];
			cnt_en    = 1'b1;
		end
		FINISH : begin
			busy      = 1'b0;
			done      = 1'b1;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b1;
			cnt_re    = 1'b0;
			cnt_en    = 1'b0;
		end
	endcase
end


// ==============      counter     =============== //
always @(posedge clk or posedge reset) begin
	if (reset)
        cnt <= 7'd0;
	else begin
        if (cnt_re)
            cnt <= 7'd0;
        else if (cnt_en) 
            cnt <= cnt + 7'd1;
	end
end


// ==============     identifier    =============== //
always @(*) begin
	ctrl = 1'b0;
	if (current_state == OPERATE) begin
		case (cmd) 
		ShiftUp    : ctrl = PosiProcess;
		ShiftDown  : ctrl = PosiProcess;
		ShiftLeft  : ctrl = PosiProcess;
		ShiftRight : ctrl = PosiProcess;
		Average    : ctrl = DataProcess;
		MirrorX    : ctrl = DataProcess;
		MirrorY    : ctrl = DataProcess;
		endcase
	end
end


// ============  position controller  ============ //
always @(posedge clk) begin
    if (reset) begin
        position_0 <= 6'h1b; // initial operation point
    end
    else if (ctrl == PosiProcess) begin
        case (cmd)
            ShiftUp   :  position_0 <= (position_0      >= 6'h8 ) ? position_0 - 6'h8 : position_0;
            ShiftDown :  position_0 <= (position_0      <= 6'h2e) ? position_0 + 6'h8 : position_0;
            ShiftLeft :  position_0 <= (position_0[2:0] != 3'd0 ) ? position_0 - 6'h1 : position_0; // 0, 8, 10, 18, 20, 28, 30, 38
            ShiftRight:  position_0 <= (position_1[2:0] != 3'd7 ) ? position_0 + 6'h1 : position_0; // 7, f, 17, 1f, 27, 2f, 37, 3f
		endcase
    end
end


// ============    data processor    ============ //
always @(posedge clk) begin
    if (reset) begin
        for (index = 0; index < 64; index = index + 1)
            data[index] <= 8'd0;
    end
    else begin
        if (current_state == READ) begin
            data[cnt - 1] <= IROM_Q;
        end
        else if (current_state == OPERATE && ctrl == DataProcess) begin
            case (cmd)
                MirrorX : begin
                    data[position_0] <= data[position_2]; // down to up
                    data[position_1] <= data[position_3]; // down to up
                    data[position_2] <= data[position_0]; // up to down
                    data[position_3] <= data[position_1]; // up to down
                end
                MirrorY: begin
                    data[position_0] <= data[position_1]; // right to left
                    data[position_1] <= data[position_0]; // left to right
                    data[position_2] <= data[position_3]; // right to left
                    data[position_3] <= data[position_2]; // left to right
                end
                Average : begin
                    data[position_0] <= sum[9:2];
                    data[position_1] <= sum[9:2];
                    data[position_2] <= sum[9:2];
                    data[position_3] <= sum[9:2];
                end
            endcase
        end
    end
end


endmodule
