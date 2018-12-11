#include "cocotb_top.h"
#include "verilated.h"
#include "verilated_vpi.h"  // Required to get definitions

vluint64_t main_time = 0;   // See comments in first example
double sc_time_stamp () { return main_time; }

void read_and_check() {
    vpiHandle vh1 = vpi_handle_by_name((PLI_BYTE8*)"TOP.our.readme", NULL);
    if (!vh1) { vl_fatal(__FILE__, __LINE__, "sim_main", "No handle found"); }
    const char* name = vpi_get_str(vpiName, vh1);
    printf("Module name: %s\n", name);  // Prints "readme"

    s_vpi_value v;
    v.format = vpiIntVal;
    vpi_get_value(vh1, &v);
    printf("Value of v: %d\n", v.value.integer);  // Prints "readme"
}

int32_t handle_vpi_callback(p_cb_data cb_data_p )
{
  printf("reached the callback handler\n");
}

void test_register_cb()
{
    s_vpi_time vpi_time;
    vpi_time.high = 0;
    vpi_time.low = 0;
    vpi_time.type = vpiSimTime;

    s_cb_data cb_data;
    cb_data.reason    = cbStartOfSimulation;
    cb_data.cb_rtn    = handle_vpi_callback;
    cb_data.obj       = NULL;
    cb_data.time      = &vpi_time;
    cb_data.value     = NULL;
    cb_data.index     = 0;
    cb_data.user_data = 0;

    vpiHandle cb = vpi_register_cb(&cb_data);

    printf("registered callback at sim start time");
}

void vlog_startup_routines_bootstrap(void) {
    void (*routine)(void);
    int i;
    routine = vlog_startup_routines[0];
    for (i = 0, routine = vlog_startup_routines[i];
         routine;
         routine = vlog_startup_routines[++i]) {
        if (i == 1) continue; // skip registration of system tasks, which is unsupported in Verilator
        routine();
    }
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::debug(0);

    cocotb_top* top = new cocotb_top;
    Verilated::internalsDump();  // See scopes to help debug

    vlog_startup_routines_bootstrap();

    //test_register_cb();
    VerilatedVpi::callCbs(cbStartOfSimulation);
    while (!Verilated::gotFinish()) {
        VerilatedVpi::callValueCbs();  // For signal callbacks
        VerilatedVpi::callTimedCbs();  // For signal callbacks
        VerilatedVpi::callCbs(cbReadWriteSynch);  // For signal callbacks
        top->eval();
        //top->clk = 0;
        //read_and_check();
        main_time++;
    }
    VerilatedVpi::callCbs(cbEndOfSimulation);

    delete top;
    exit(0);
}
