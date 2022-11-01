module divider_8_top_simulation		(   
        ClkPort,
		Xin, Yin,
		Start, Ack,
		Reset,
		
		Quotient, Remainder,
		Done, Qi, Qc, Qd,
		instruction, port_id, in_port, out_port, address,
		write_strobe, k_write_strobe, read_strobe
);

	input ClkPort;
	input[7:0] Xin, Yin;
	input Start, Ack, Reset;

	output Done, Qi, Qc, Qd, Quotient, Remainder;
	output [17:0] instruction;
	output [7:0] in_port;
	output [7:0] port_id;
	output [7:0] out_port;
	output [11:0] address;
	output write_strobe, k_write_strobe, read_strobe;

	wire		Reset, ClkPort;
	wire		board_clk;

	wire [7:0] 	Xin, Yin;
	reg  [7:0] 	Quotient, Remainder;
	wire 		Start, Ack;
	reg 		Done, Qi, Qc, Qd;

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

	assign kcpsm6_reset = rdl | (Reset);	
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

	assign ssdscan_clk = DIV_CLK[19:18];
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	// Turn off another 4 anodes
	assign {An7, An6, An5, An4} = 4'b1111;


	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3) begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00: SSD = SSD0;
			2'b01: SSD = SSD1;
			2'b10: SSD = SSD2;
			2'b11: SSD = SSD3;
		endcase 
	end

	always @ (SSD) begin : HEX_TO_SSD
		case (SSD)
			4'b0000: SSD_CATHODES = 8'b00000010; // 0
			4'b0001: SSD_CATHODES = 8'b10011110; // 1
			4'b0010: SSD_CATHODES = 8'b00100100; // 2
			4'b0011: SSD_CATHODES = 8'b00001100; // 3
			4'b0100: SSD_CATHODES = 8'b10011000; // 4
			4'b0101: SSD_CATHODES = 8'b01001000; // 5
			4'b0110: SSD_CATHODES = 8'b01000000; // 6
			4'b0111: SSD_CATHODES = 8'b00011110; // 7
			4'b1000: SSD_CATHODES = 8'b00000000; // 8
			4'b1001: SSD_CATHODES = 8'b00001000; // 9
			4'b1010: SSD_CATHODES = 8'b00010000; // A
			4'b1011: SSD_CATHODES = 8'b11000000; // B
			4'b1100: SSD_CATHODES = 8'b01100010; // C
			4'b1101: SSD_CATHODES = 8'b10000100; // D
			4'b1110: SSD_CATHODES = 8'b01100000; // E
			4'b1111: SSD_CATHODES = 8'b01110000; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX;
		endcase
	end	

	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule
