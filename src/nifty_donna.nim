# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import init, bitmask as b, game as g, position, piece, move

echo "Hello, Nifty Donna!"
var
  x: Bitmask = 42
  y: Bitmask = 0

echo "x is ", x.empty
echo "y is ", y.empty

var game = newGame()
discard game.ready()
var p = game.start()
p.id = 42'u64
echo "p.id: ", p.id
echo "tree[0].id: ", tree[0].id
echo p.toString

