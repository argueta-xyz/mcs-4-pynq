#include "verilated_fst_c.h"
#include "testbench.h"
template<class MODULE> class AXI_TESTBENCH : public TESTBENCH<MODULE> {
public:
    AXI_TESTBENCH() : TESTBENCH<MODULE>() { }
    virtual ~AXI_TESTBENCH() { }

    virtual void axiWrite(int addr, int wdata, int wstrb=0xF) {
        int timeout = 100;
        this->m_core->s_axi_wdata = wdata;
        this->m_core->s_axi_awaddr = addr;
        this->m_core->s_axi_awvalid = 1;
        this->m_core->s_axi_wvalid = 0;
        this->m_core->s_axi_wlast = 0;
        this->tick();
        while (this->m_core->s_axi_awready == 0 && timeout > 0) {
            this->tick();
            timeout--;
        }
        this->m_core->s_axi_awvalid = 0;
        if (this->checkTimeout(timeout, "WRITE (Addr)", addr)){
            this->m_core->s_axi_wdata = 0;
            this->m_core->s_axi_awaddr = 0;
            this->m_core->s_axi_awvalid = 0;
            this->m_core->s_axi_wvalid = 0;
            this->m_core->s_axi_wlast = 0;
            return;
        }
        this->m_core->s_axi_wvalid = 1;
        this->m_core->s_axi_wlast = 1;
        this->m_core->s_axi_wstrb = wstrb;
        this->tick();
        while (this->m_core->s_axi_wready == 0 && timeout > 0) {
            this->tick();
            timeout--;
        }
        this->checkTimeout(timeout, "WRITE (Data)", addr);
        this->tick();
        this->m_core->s_axi_wvalid = 0;
        this->m_core->s_axi_wlast = 0;
    }

    virtual int axiRead(int addr) {
        int timeout = 100;
        this->m_core->s_axi_araddr = addr;
        this->m_core->s_axi_arvalid = 1;
        this->m_core->s_axi_rready = 0;
        while (this->m_core->s_axi_arready == 0 && timeout > 0) {
            this->tick();
            timeout--;
        }
        this->tick();
        if (checkTimeout(timeout, "READ (Addr)", addr)){
            this->m_core->s_axi_araddr = 0;
            this->m_core->s_axi_arvalid = 0;
            this->m_core->s_axi_rready = 0;
            return 0xFFFFFFFF;
        }
        this->m_core->s_axi_arvalid = 0;
        this->m_core->s_axi_rready = 1;
        while (this->m_core->s_axi_rvalid == 0 && timeout > 0) {
            this->tick();
            timeout--;
        }
        this->tick();
        this->checkTimeout(timeout, "READ (Data)", addr);
        this->m_core->s_axi_rready = 0;
        return this->m_core->s_axi_rdata;
    }

private:
    bool checkTimeout(int& timeout, std::string op, int addr){
        if (timeout == 0) {
            std::cout << "ERROR: AXI " << op << " timed out: [" << std::hex
                      << addr << std::endl;
            timeout = 100;
            return true;
        }
        timeout = 100;
        return false;
    }
};