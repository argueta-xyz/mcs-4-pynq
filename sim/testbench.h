#include "verilated_fst_c.h"

template<class MODULE> class TESTBENCH {
public:
	unsigned long	m_tickcount;
	MODULE	*m_core;
	VerilatedFstC* m_trace;
    unsigned long m_time;

	TESTBENCH(void) {
		m_core = new MODULE;
	    Verilated::traceEverOn(true);
		m_tickcount = 0l;
		m_time = 0l;
		m_core->clk = 0;
		m_core->eval();
	}

	virtual ~TESTBENCH(void) {
		closeTrace();
		delete m_core;
		m_core = NULL;
	}

	virtual void openTrace(const char* filename) {
		if (!m_trace) {
		    m_trace = new VerilatedFstC;
		    m_core->trace(m_trace, 99);  // Trace 99 levels of hierarchy
		    m_trace->open(filename);
		}
	}

	virtual	void closeTrace(void) {
		if (m_trace) {
			m_trace->close();
			delete m_trace;
			m_trace = NULL;
		}
	}

	virtual void reset(void) {
		m_core->rst = 1;
		// Make sure any inheritance gets applied
		this->tick();
		m_core->rst = 0;
		this->tick();
	}

	virtual void tick(void) {
		// Increment our own internal m_time reference
		m_tickcount++;

		// Make sure we have our evaluations straight before the top
		// of the clock.  This is necessary since some of the
		// connection modules may have made changes, for which some
		// logic depends.  This forces that logic to be recalculated
		// before the top of the clock.
		m_core->eval();
		if (m_trace) m_trace->dump((vluint64_t)(10*m_tickcount-2));
		m_core->clk = 1;
		m_core->eval();
		if (m_trace) m_trace->dump((vluint64_t)(10*m_tickcount));
		m_core->clk = 0;
		m_core->eval();
		if (m_trace) {
			m_trace->dump((vluint64_t)(10*m_tickcount+5));
			m_trace->flush();
		}
	}

	virtual bool done(void) { return (Verilated::gotFinish()); }
};