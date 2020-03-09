library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
constant c_CLOCK_PERIOD		: time := 100 ns;
signal   tb_done		: std_logic;
signal   mem_address		: std_logic_vector (15 downto 0) := (others => '0');
signal   tb_rst	                : std_logic := '0';
signal   tb_start		: std_logic := '0';
signal   tb_clk		        : std_logic := '0';
signal   mem_o_data,mem_i_data	: std_logic_vector (7 downto 0);
signal   enable_wire  		: std_logic;
signal   mem_we		        : std_logic;

type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);

signal RAM1: ram_type := (0 => std_logic_vector(to_unsigned( 5 , 8)),
                         1 => std_logic_vector(to_unsigned( 21 , 8)),
                         2 => std_logic_vector(to_unsigned( 88 , 8)),
                         3 => std_logic_vector(to_unsigned( 31 , 8)),
                         4 => std_logic_vector(to_unsigned( 11 , 8)),
                         5 => std_logic_vector(to_unsigned( 51 , 8)),
                         6 => std_logic_vector(to_unsigned( 66 , 8)),
                         7 => std_logic_vector(to_unsigned( 44 , 8)),
                         8 => std_logic_vector(to_unsigned( 11 , 8)),
			 others => (others =>'0'));

signal SEC_IND8: ram_type := (8 => std_logic_vector(to_unsigned( 120 , 8)),
			 others => (others =>'0'));
shared variable sec_ind : boolean := false;

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;


begin
UUT: project_reti_logiche
port map (
          i_clk      	=> tb_clk,
          i_start       => tb_start,
          i_rst      	=> tb_rst,
          i_data    	=> mem_o_data,
          o_address  	=> mem_address,
          o_done      	=> tb_done,
          o_en   	=> enable_wire,
          o_we 		=> mem_we,
          o_data    	=> mem_i_data
          );

p_CLK_GEN : process is
begin
    wait for c_CLOCK_PERIOD/2;
    tb_clk <= not tb_clk;
end process p_CLK_GEN;


MEM : process(tb_clk)
begin
    if tb_clk'event and tb_clk = '1' then
        if enable_wire = '1' then
            if mem_we = '1' then
                if(NOT sec_ind) then
                    RAM1(conv_integer(mem_address))  <= mem_i_data;
                    mem_o_data                      <= mem_i_data after 1 ns;
                else
                    SEC_IND8(conv_integer(mem_address))  <= mem_i_data;
                    mem_o_data                      <= mem_i_data after 1 ns;
                end if;
            else
                if(NOT sec_ind) then
                    mem_o_data <= RAM1(conv_integer(mem_address)) after 1 ns;
                else
                    mem_o_data <= SEC_IND8(conv_integer(mem_address)) after 1 ns;
                end if;
            end if;
        end if;
    end if;
end process;

test : process is
begin

    -- RAM
    wait for 100 ns;
    wait for c_CLOCK_PERIOD;
    tb_rst <= '1';
    wait for c_CLOCK_PERIOD;
    tb_rst <= '0';
    wait for c_CLOCK_PERIOD;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 100 ns;

    -- Maschera di output = 1 - 100 - 0001
    assert RAM1(9) = std_logic_vector(to_unsigned( 193 , 8)) report "TEST 1 FALLITO. Expected  193  found " & integer'image(to_integer(unsigned(RAM1(9))))  severity failure;

    assert false report "Simulation Ended!, TEST 1 PASSATO" severity failure;

    -- RAM2
    sec_ind := true;
    wait for c_CLOCK_PERIOD;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 100 ns;

    assert SEC_IND8(9) = std_logic_vector(to_unsigned( 120 , 8)) report "TEST 2 FALLITO. Expected  120 found " & integer'image(to_integer(unsigned(SEC_IND8(9))))  severity failure;

    assert false report "Simulation Ended!, TEST 2 PASSATO" severity failure;

end process test;

end projecttb;