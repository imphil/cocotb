-- Matrix Multiplier DUT
library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mean_pkg.clog2;

entity matrix_multiplier is
generic(
    DATA_WIDTH : positive := 8;
    A_ROWS : positive := 8;
    B_COLUMNS : positive := 5;
    A_COLUMNS_B_ROWS : positive := 4
    );
end matrix_multiplier;

architecture RTL of matrix_multiplier is

    type a_b_col_type is array (integer range <>) of unsigned(DATA_WIDTH-1 downto 0);
    type c_col_type   is array (integer range <>) of unsigned((2*DATA_WIDTH)+clog2(A_COLUMNS_B_ROWS)-1 downto 0);

    type a_type is array (0 to A_ROWS-1)            of a_b_col_type(0 to A_COLUMNS_B_ROWS-1);
    type b_type is array (0 to A_COLUMNS_B_ROWS-1)  of a_b_col_type(0 to B_COLUMNS-1);
    type c_type is array (0 to A_ROWS-1)            of c_col_type(0 to B_COLUMNS-1);

    signal clk      : std_logic;
    signal reset    : std_logic;

    signal i_valid  : std_logic;
    signal o_valid  : std_logic;

    signal i_A      : a_type;
    signal i_B      : b_type;
    signal o_C      : c_type;

begin
    process(clk)
        variable C_RESULT : c_type := (others => (others => (others => '0')));
    begin
        if rising_edge(clk) then
            if reset = '1' then
                o_C <= (others => (others => (others => '0')));
                o_valid <= '0';
            elsif i_valid = '1' then
                C_RESULT := (others => (others => (others => '0')));

                C_ROWS: for i in 0 to A_ROWS-1 loop
                    C_COLUMNS: for j in 0 to B_COLUMNS-1 loop
                        DOT_PRODUCT: for k in 0 to A_COLUMNS_B_ROWS-1 loop
                            C_RESULT(i)(j) := C_RESULT(i)(j) + (i_A(i)(k) * i_B(k)(j));
                        end loop;
                    end loop;
                end loop;

                o_C <= C_RESULT;
                o_valid <= '1';
            else
                o_valid <= '0';
            end if;
        end if;
    end process;

end RTL;
