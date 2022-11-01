//////////////////////////////////////////////////////////////////////////////////
// Picoblaze 8 bit divider testbench for the divider_4_top_simulation design    //
//     File: divider_8_top_simulation_tb.v   Gandhi Puvvada  3/13/2021          //                                                        //
// Here, we want to simulate the top design which is generally uncommon.        //
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module divider_8_top_simulation_tb;
	reg ClkPort;
	reg Reset;
	reg Start;
	reg Ack;
		
	reg [7:0] Xin;
	reg [7:0] Yin;

	wire [7:0] Quotient;
	wire [7:0] Remainder;
	wire Qi;
	wire Qc;
	wire Qd;
	wire Done;
	
	wire [17:0] instruction;
	wire [7:0] port_id;
	wire [7:0] out_port;
	wire [7:0] in_port;
	wire [11:0] address;
	
	wire write_strobe, k_write_strobe, read_strobe;
	
	reg [2*8:0] state_string;
	
	integer clk_cnt, start_clock_cnt,clocks_taken;
	integer results_file, instruction_trace_file;
	
	divider_8_top_simulation uut (
		.ClkPort(ClkPort),
		.Xin(Xin), 
		.Yin(Yin),
		.Start(Start), 
		.Ack(Ack),
		.Reset(Reset),
		.Quotient(Quotient), 
		.Remainder(Remainder),
		.Done(Done), 
		.Qi(Qi), 
		.Qc(Qc), 
		.Qd(Qd),
		.instruction(instruction),
		.port_id(port_id),
		.in_port(in_port),
		.out_port(out_port),
		.address(address),
		.write_strobe(write_strobe), 
		.k_write_strobe(k_write_strobe), 
		.read_strobe(read_strobe)
	);

	always begin
		#5;
		ClkPort = ~ ClkPort;
	end

	always@(posedge ClkPort) begin
		clk_cnt=clk_cnt+1;
	end

	initial begin
		results_file = $fopen("results_divider_8.txt", "w");
		clk_cnt = 0;
		ClkPort = 0;
		Reset = 1;
		Start = 0;
		Ack = 0;
		Xin = 0;
		Yin = 0;

		#200;
		@(posedge ClkPort);
		#1;
		Reset = 0;
		
		Xin = 70;
		Yin = 20;
		APPLY_STIMULUS(Xin, Yin);
		
		Xin = 150;
		Yin = 30;
		APPLY_STIMULUS(Xin, Yin);

		
		Xin = 140;
		Yin = 40;
		APPLY_STIMULUS(Xin, Yin);

	end
	
	task APPLY_STIMULUS;	
		input [7:0] Xin_val;
		input [7:0] Yin_val;
		begin
			wait (read_strobe);
			@(posedge ClkPort);
			@(posedge ClkPort);

			wait (read_strobe);
			@(posedge ClkPort);
			@(posedge ClkPort);
			
			wait (read_strobe);
			@(posedge ClkPort);
			@(posedge ClkPort);
			
			#1;
			Start=1;

			wait(Qc);
			@(posedge ClkPort);
			
			#1;
			Start=0;
			
			start_clock_cnt=clk_cnt;
			
			wait(Qd);
			wait (read_strobe);
			@(posedge ClkPort);
			@(posedge ClkPort);
			#1;
			clocks_taken = clk_cnt - start_clock_cnt;
			$display("Reporting from the Qd Done state");
			$fdisplay(results_file,"Reporting from the Qd Done state");			
			$display("Xin:%d Yin:%d Quotient:%d Remainder:%d", Xin_val, Yin_val, Quotient, Remainder);
			$display("It took %d clocks to compute the quotient", clocks_taken);
			$fdisplay(results_file,"Xin:%d Yin:%d Quotient:%d Remainder:%d", Xin_val, Yin_val, Quotient, Remainder);
			$fdisplay(results_file,"It took %d clocks to compute the quotient", clocks_taken);

			Ack=1;
			wait(Qi);
			@(posedge ClkPort);
			#1;
			Ack=0;
			@(posedge ClkPort);
			#1;			
		end
	endtask
			

	always @(*) begin
		case ({Qi, Qc, Qd})  
			3'b100: state_string = "Qi";  
			3'b010: state_string = "Qc";  
			3'b001: state_string = "Qd";
		endcase
	end

    initial begin : Trace
		reg [11:0] ADDR;
		reg [17:0] INSTR;
		reg	[1:152]	INSTR_ASCII; 
		instruction_trace_file = $fopen("instruction_trace_divider_8.txt", "w");
		ADDR = 12'h000;
		wait (address == 12'h001); 
		forever	begin
			@ (negedge ClkPort) 
			INSTR = instruction;
			INSTR_ASCII  = uut.processor.kcpsm6_opcode ;
			$fdisplay(instruction_trace_file, "Addr: %h  Instr: %h %s Dividend_s0: %h Divider_s1: %h Quotient_s3: %h Remainder_s4: %h Control_s2: %h  cc: %0d ", ADDR, INSTR, INSTR_ASCII, uut.processor.bank_a_s0, uut.processor.bank_a_s1, uut.processor.bank_a_s3, uut.processor.bank_a_s4, uut.processor.bank_a_s2,  clk_cnt);
			ADDR = address;
			@(negedge ClkPort);
		end
	end

endmodule
