# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import times
import init, play, position, search, utils

echo "Donna Nim 0.1.0 (based on Donna v2.1)"
echo "Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved."

let p = newGame().start
echo p.toString

let depth = 5
let start = cpuTime()
let total = p.perft(depth)
let finish = cpuTime() - start
echo "  Depth: " & $depth
echo "  Nodes: " & $total
echo "Elapsed: " & ms(finish) # $finish # ms(finish))
echo "Nodes/s: " & $int(float(total) / finish / 1000.0) & "K"
