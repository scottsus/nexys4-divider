module divider_8_top		(   
		MemOE, MemWR, RamCS, QuadSpiFlashCS,

        ClkPort,
		
		BtnL, BtnU, BtnD, BtnR, BtnC,
		Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8,
		Sw7,  Sw6,  Sw5,  Sw4,  Sw3,  Sw2,  Sw1, Sw0,
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0,
		An7, An6, An5, An4, An3, An2, An1, An0,
		Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp
	  );
	
	input		ClkPort;	
	input		BtnL, BtnU, BtnD, BtnR, BtnC;	
	input		Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8;
	input		Sw7,  Sw6,  Sw5,  Sw4,  Sw3,  Sw2,  Sw1, Sw0;

	output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An7, An6, An5, An4, An3, An2, An1, An0; 
	
	wire		Reset, ClkPort;
	wire		board_clk; 
	wire [2:0] 	ssdscan_clk;

	wire [7:0] 	Xin, Yin;
	reg  [7:0] 	Quotient, Remainder;
	wire 		Start, Ack;
	reg 		Done, Qi, Qc, Qd;

	reg [26:0]	DIV_CLK;
	reg [3:0]	SSD;
	wire [7:0]	SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;

	wire [11:0] address;
	wire [17:0]	instruction;
	wire        bram_enable;
	reg  [7:0]  in_port;
	wire [7:0]  out_port;
	wire [7:0]  port_id;
	wire        write_strobe;
	wire        k_write_strobe;
	wire        read_strobe;
	reg         interrupt;   
	wire        interrupt_ack;
	wire        kcpsm6_sleep;  
	wire        kcpsm6_reset;
	wire        rdl;	
	
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	kcpsm6 #(
		.interrupt_vector	(12'h3FF),
		.scratch_pad_memory_size(64),
		.hwbuild		(8'h41))
	processor (
		.address 		(address),
		.instruction 	(instruction),
		.bram_enable 	(bram_enable),
		.port_id 		(port_id),
		.write_strobe 	(write_strobe),
		.k_write_strobe (k_write_strobe),
		.out_port 		(out_port),
		.read_strobe 	(read_strobe),
		.in_port 		(in_port),
		.interrupt 		(interrupt),
		.interrupt_ack 	(interrupt_ack),
		.reset 			(kcpsm6_reset),
		.sleep			(kcpsm6_sleep),
		.clk 			(board_clk)); 

	assign kcpsm6_reset = rdl | (BtnC);
	assign kcpsm6_sleep = 0;
  
	prom_divider_8 #(
		.C_FAMILY		   ("7S"),  
		.C_RAM_SIZE_KWORDS	(1),  
		.C_JTAG_LOADER_ENABLE	(1))
	program_rom (
		.rdl 			(rdl),
		.enable 		(bram_enable),
		.address 		(address),
		.instruction 	(instruction),
		.clk 			(board_clk));  

	assign board_clk = ClkPort;	
	assign Reset = BtnC;
	
	always @(posedge board_clk, posedge Reset) begin							
		if (Reset)
		DIV_CLK <= 0;
		else
		DIV_CLK <= DIV_CLK + 1'b1;
	end
	
	assign Xin = {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8};
	assign Yin = {Sw7,  Sw6,  Sw5,  Sw4,  Sw3,  Sw2,  Sw1, Sw0};
	assign Start = BtnL; assign Ack = BtnR;

	always @ (*) begin
		case (port_id[1:0])
			2'b01 : in_port <= Xin;
			2'b10 : in_port <= Yin;
			2'b11 : in_port <= {6'b000000,Start,Ack}; 	
			default : in_port <= 8'bXXXXXXXX ;  
		endcase
	end	

	always @(posedge board_clk) begin	
		if (write_strobe == 1'b1) begin
			case (port_id[1:0])
				2'b01 : Quotient <= out_port;
				2'b10 : Remainder <= out_port;
			endcase
		end
		
		if (k_write_strobe == 1'b1) begin
			if (port_id[0]  == 1'b1) begin
				Done <= out_port[0];
				Qi <= out_port[1];
				Qc <= out_port[2];
				Qd <= out_port[3];
			end	
		end		
	end

	assign {Ld7, Ld6, Ld5, Ld4} = {Qi, Qc, Qd, Done};
	assign {Ld3, Ld2, Ld1, Ld0} = {Start, BtnU, Ack, BtnD}; 
	
	assign SSD7 = Xin[7:4];
	assign SSD6 = Xin[3:0];
	assign SSD5 = Yin[7:4];
	assign SSD4 = Yin[3:0];
	assign SSD3 = Quotient[7:4];
	assign SSD2 = Quotient[3:0];
	assign SSD1 = Remainder[7:4];
	assign SSD0 = Remainder[3:0];

	assign ssdscan_clk = DIV_CLK[19:17];
	assign An0 = !(ssdscan_clk[2:0] == 3'b000);
	assign An1 = !(ssdscan_clk[2:0] == 3'b001);
	assign An2 = !(ssdscan_clk[2:0] == 3'b010);
	assign An3 = !(ssdscan_clk[2:0] == 3'b011);
	assign An4 = !(ssdscan_clk[2:0] == 3'b100);
	assign An5 = !(ssdscan_clk[2:0] == 3'b101);
	assign An6 = !(ssdscan_clk[2:0] == 3'b110);
	assign An7 = !(ssdscan_clk[2:0] == 3'b111);
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3) begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  3'b000: SSD = SSD0;
				  3'b001: SSD = SSD1;
				  3'b010: SSD = SSD2;
				  3'b011: SSD = SSD3;
				  3'b100: SSD = SSD4;
				  3'b101: SSD = SSD5;
				  3'b110: SSD = SSD6;
				  3'b111: SSD = SSD7;
				  
		endcase 
	end

	always @ (SSD) begin : HEX_TO_SSD
		case (SSD)
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX;
		endcase
	end	
	
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};	

endmodule
