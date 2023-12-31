LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY generic_complex_mult_block IS
	GENERIC (
				C_PLUS_S:	STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000";
				C_ONLY  :   STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000";
				C_MIN_S :	STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000"
				
			);
	PORT	(
				A32		:	IN	STD_LOGIC_VECTOR (31 DOWNTO 0);
				TYPESEL :	IN	STD_LOGIC_VECTOR (2 DOWNTO 0);
				R32		:	OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
END generic_complex_mult_block;

ARCHITECTURE structural OF generic_complex_mult_block IS
COMPONENT generic_complex_mult_16b IS
	GENERIC (
				C_PLUS_S:	STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000";
				C_ONLY  :   STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000";
				C_MIN_S :	STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000"
				
			);
	PORT	(
				REAL_A32:	IN	STD_LOGIC_VECTOR (15 DOWNTO 0);
				IMAG_A32:	IN	STD_LOGIC_VECTOR (15 DOWNTO 0);
				REAL_R32:	OUT	STD_LOGIC_VECTOR (15 DOWNTO 0);
				IMAG_R32:	OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
			);
END COMPONENT;
COMPONENT mux_2to1_16b IS
	PORT 	(
				D1	:	IN	std_logic_vector (15 DOWNTO 0);
				D2	:	IN	std_logic_vector (15 DOWNTO 0);
				Y	:	OUT	std_logic_vector (15 DOWNTO 0);
				S	:	IN	std_logic
			);
END COMPONENT;
COMPONENT sgninv_16b IS
	PORT	(
				A16		:	IN	STD_LOGIC_VECTOR (15 DOWNTO 0);
				R16		:	OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
				C_OUT16 :	OUT STD_LOGIC
			);
END COMPONENT;


SIGNAL REAL_A32 		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL IMAG_A32 		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL REAL_R32 		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL IMAG_R32 		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL REAL_MULT_OUT	: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL IMAG_MULT_OUT	: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_0_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_1_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_2_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_3_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_4_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_5_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL SGNINV_0_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL SGNINV_1_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL SGNINV_2_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL SGNINV_3_OUT		: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL MUX_4_SELECTOR : STD_LOGIC;
SIGNAL MUX_5_SELECTOR : STD_LOGIC;

BEGIN
	REAL_A32			<= A32(31 DOWNTO 16);
	IMAG_A32			<= A32(15 DOWNTO 0);
	REAL_R32			<= MUX_4_OUT;
	IMAG_R32			<= MUX_5_OUT;
	R32(31 DOWNTO 16) 	<= REAL_R32;
	R32(15 DOWNTO 0)	<= IMAG_R32;
	MUX_4_SELECTOR <=TYPESEL(2) AND NOT((TYPESEL(1) XOR TYPESEL(0)));
	MUX_5_SELECTOR <=(NOT TYPESEL(2)) AND (TYPESEL(1) XOR TYPESEL(0));
	
	
	-- Port Mapping
	-- PRE PROCESSING
	-- Swapping Mux
	MUX_0	:
		mux_2to1_16b
			PORT MAP
				(
					D1	=>REAL_A32,
					D2	=>IMAG_A32,
					Y	=>MUX_0_OUT,
					S	=>TYPESEL(2)
				);
	MUX_1	:
		mux_2to1_16b
			PORT MAP
				(
					D1	=>IMAG_A32,
					D2	=>REAL_A32,
					Y	=>MUX_1_OUT,
					S	=>TYPESEL(2)
				);	
	-- Sign Inversion Circuit
	SGNINV_0 :
		sgninv_16b
			PORT MAP
				(
					A16	=>MUX_0_OUT,
					R16 =>SGNINV_0_OUT
				);
	SGNINV_1 :
		sgninv_16b
			PORT MAP
				(
					A16	=>MUX_1_OUT,
					R16 =>SGNINV_1_OUT
				);		
	MUX_2	:
		mux_2to1_16b
			PORT MAP
				(
					D1	=>MUX_0_OUT,
					D2	=>SGNINV_0_OUT,
					Y	=>MUX_2_OUT,
					S	=>TYPESEL(1)
				);
	MUX_3	:
		mux_2to1_16b
			PORT MAP
				(
					D1	=>MUX_1_OUT,
					D2	=>SGNINV_1_OUT,
					Y	=>MUX_3_OUT,
					S	=>TYPESEL(0)
				);	
	-- MULTIPLICATION
	COMPLEX_MULTIPLIER :
		generic_complex_mult_16b
			GENERIC MAP
				(
					C_PLUS_S	=>C_PLUS_S,
					C_ONLY		=>C_ONLY,
					C_MIN_S		=>C_MIN_S
				)
			PORT MAP
				(
					REAL_A32	=>MUX_2_OUT,
					IMAG_A32	=>MUX_3_OUT,
					REAL_R32	=>REAL_MULT_OUT,
					IMAG_R32	=>IMAG_MULT_OUT
				);
	-- POST PROCESSING
	-- Sign Inversion Circuit
	SGNINV_2 :
		sgninv_16b
			PORT MAP
				(
					A16	=>REAL_MULT_OUT,
					R16 =>SGNINV_2_OUT
				);
	SGNINV_3 :
		sgninv_16b
			PORT MAP
				(
					A16	=>IMAG_MULT_OUT,
					R16 =>SGNINV_3_OUT
				);			
	MUX_4	:
		mux_2to1_16b
			PORT MAP
				(
					D1	=>REAL_MULT_OUT,
					D2	=>SGNINV_2_OUT,
					Y	=>MUX_4_OUT,
					S	=>MUX_4_SELECTOR
				);
	MUX_5	:
		mux_2to1_16b
			PORT MAP
				(
					D1	=>IMAG_MULT_OUT,
					D2	=>SGNINV_3_OUT,
					Y	=>MUX_5_OUT,
					S	=>MUX_5_SELECTOR
				);			
END structural;

