import cpp
import semmle.code.cpp.dataflow.new.TaintTracking
import semmle.code.cpp.dataflow.new.DataFlow

class NetworkByteSwap extends Expr {
    NetworkByteSwap() {
        exists(MacroInvocation m |
            m.getMacro().getName().matches("ntoh%")
            and this = m.getExpr()
        )
    }
}

module MyCfg implements DataFlow::ConfigSig {
    predicate isSource(DataFlow::Node src) {
        src.asExpr() instanceof NetworkByteSwap
    }

    predicate isSink(DataFlow::Node sink) {
        exists(FunctionCall memc |
            memc.getTarget().getName() = "memcpy" and
            sink.asExpr() = memc.getArgument(2)
        )
    }
    // input validation
    predicate isBarrier(DataFlow::Node barrier) {
        exists(FunctionCall fc |
            fc.getTarget().getName().matches("validate%|check%") and
            barrier.asExpr() = fc.getArgument(0)
        )
    }
}

module MyFlow = TaintTracking::Global<MyCfg>;

import MyFlow::PathGraph

from MyFlow::PathNode src, MyFlow::PathNode sink
where MyFlow::flowPath(src, sink)
select sink.getNode(), src, sink, "NBS to memcpy + barrier"
