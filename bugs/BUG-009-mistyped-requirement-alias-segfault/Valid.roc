app [main] { pf: platform "platform/main.roc" }

import pf.P

main = P.{ step: Run("x") }
