----------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Gianluca Palermo - Anno 2019/2020
--
-- Davide Raffaelli (Codice Persona 10561417 Matricola 887753)
-- Daniele Raimondi (Codice Persona 10611801 Matricola 891030)
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;


architecture Behavioral of project_reti_logiche is

    --Descrizione stati automa
    type state_type is (WAIT_START, FETCH_ADDRESS, REQUEST_ADDRESS, CHECK, WRITE_OUT,DONE);
    signal current_state, next_state : state_type;
    
    --Segnali di aggiornamento uscite componente
    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
	signal o_data_next : std_logic_vector(7 downto 0) := "00000000";
	signal o_address_next : std_logic_vector(3 downto 0) := "0000";
	
	--Segnali per l' indirizzo da tradurre (indirizzo memoria 8)
	signal addr_transl, addr_transl_next : std_logic_vector(6 downto 0) := "0000000";
	
	--Segnali per l' indirizzo che voglio leggere
	signal addr_read, addr_read_next : std_logic_vector(3 downto 0) := "0000";
    
    --Segnali per tenere la differenza fra l' indirizzo della wz e il segnale da tradurre
    signal diff_next: std_logic_vector(6 downto 0) := "0000000";
    signal diff: std_logic_vector(1 downto 0) := "00";
    
    --Segnali per capire se l'indirizzo è stato tradotto o meno
    signal translate, translate_next : boolean := false;
   

begin
    
    --Processo per aggiornare stato automa
    state_reg: process (i_clk, i_rst)
    begin
    
        --Se il segnale di rst si alza, resetto tutto e torno nello stato iniziale
        if(i_rst = '1') then
            addr_transl <= "0000000";
            o_done <= '0';
            o_en <= '0';
            o_we <= '0';
            o_data <= "00000000";
            o_address <= "0000000000000000";
            addr_read <= "1000";
            diff<="00";
            translate <= false;
            current_state <= WAIT_START;
            
        --Se ricevo un colpo di clock (fronte di salita), aggiorno segnali e output
        elsif (rising_edge(i_clk)) then
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            o_address <= "000000000000" & o_address_next;
            addr_transl <= addr_transl_next;
            addr_read <= addr_read_next;
            diff<=diff_next(1 downto 0);
            translate <= translate_next;
            current_state <= next_state;
        end if;
        
    end process;
    
    --Processo funzione lambda e delta
    next_state_process: process (current_state, i_start, i_data, addr_transl, addr_read,diff, translate)
    begin
    
        --Valori di default ad ogni ciclo di clock
        o_done_next <= '0';
        o_en_next <= '0';
        o_we_next <= '0';
        o_data_next <= "00000000";
        o_address_next <= "0000";
        addr_transl_next <= addr_transl;
        addr_read_next <= addr_read;
        diff_next<="00000" & diff;       
        translate_next <= translate;
        next_state <= current_state;
    
        --Aggiornamento stato
        case current_state is
        
            when WAIT_START =>
                if(i_start = '1') then
                    next_state <= FETCH_ADDRESS;
                end if;
               
            --Stato in cui chiedo l'indirizzo alla memoria
            when FETCH_ADDRESS =>
                o_en_next <= '1';
                o_address_next <= addr_read;
                next_state <= REQUEST_ADDRESS;
                      
            --Stato im cui chiedo alla memoria il prossimo indirizzo di working zone      
            when REQUEST_ADDRESS =>
                o_en_next <= '1';
                addr_read_next <= addr_read - "0001";
                o_address_next <= addr_read - "0001";
                next_state <= CHECK;             

            --Stato in cui controllo se devo tradurre l'indirizzo o andare avanti a chiedere gli indirizzi di working zone
            when CHECK =>
            if(addr_read = "0111") then
                addr_transl_next <= i_data(6 downto 0);
                next_state <= REQUEST_ADDRESS;
            else
                if(i_data <= ("0" & addr_transl) AND i_data + "00000011" >= ("0" & addr_transl)) then
                    diff_next <=addr_transl - i_data(6 downto 0); 
                    translate_next <= true;
                    next_state<=WRITE_OUT;
                else
                    if(addr_read="1111") then
                        next_state<=WRITE_OUT;
                    else
                        next_state <= REQUEST_ADDRESS;
                    end if;
                end if;
            end if;
                
            --Stato in cui scrivo sulla memoria l'indirizzo tradotto o non tradotto a seconda del caso
            when WRITE_OUT=>
                o_en_next<='1';
                o_we_next<='1';
                o_done_next<='1';
                o_address_next <= "1001";
                if(translate = false) then
                    o_data_next<="0" & addr_transl;
                else
                    o_data_next(7) <= '1';
                    o_data_next(6 downto 4) <= addr_read(2 downto 0) + "001";
                    case diff is
                    when "00" => o_data_next(3 downto 0) <= "0001";
                    when "01" => o_data_next(3 downto 0) <= "0010";
                    when "10" => o_data_next(3 downto 0) <= "0100";
                    when others => o_data_next(3 downto 0) <= "1000";
                end case;
                 end if;            
                next_state<=DONE;                          
                
            --Stato in cui aspetto che la memoria abbassi il segnale di start
            when DONE=> 
              if (i_start = '0') then
                     addr_transl_next <= "0000000";
                     addr_read_next <= "1000";
                     diff_next<="0000000";
                     translate_next <= false;
                     next_state<=WAIT_START;
               end if;    
            
        end case;
    end process;

end Behavioral;


