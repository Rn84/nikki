
module Sorts.StoryMode where


import Graphics.Qt

import Base


signs =
    "npcs/cpt-beaugard" :
    "npcs/high-school-girl-1" :
    "npcs/high-school-girl-2" :
    "npcs/high-school-girl-3" :
    "npcs/high-school-girl-4" :
    "npcs/monkey" :
    "npcs/bunny" :
    "data-terminal" :
    []

tiles :: [(String, Position Int, Size Double, Seconds, Maybe [Int])]
tiles =
    ("tiles/black-blue/panel-standard", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-blue/panel-small", Position 1 1, Size 32 32, 1, Nothing) :
    ("tiles/black-blue/panel-large", Position 1 1, Size 128 128, 1, Nothing) :
    ("tiles/black-blue/vent-large", Position 1 1, Size 128 128, 1, Nothing) :
    ("tiles/black-blue/vent-background-large", Position 1 1, Size 128 128, 1, Nothing) :
    ("tiles/black-green/panel-standard", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-green/panel-small", Position 1 1, Size 32 32, 1, Nothing) :
    ("tiles/black-brown/panel-standard", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/panel-small", Position 1 1, Size 32 32, 1, Nothing) :
    ("tiles/black-brown/rounded-corner-upper-left", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/rounded-corner-upper-right", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/rounded-corner-lower-left", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/rounded-corner-lower-right", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/wallpaper-standard", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/wallpaper-large", Position 1 1, Size 128 128, 1, Nothing) :
    ("tiles/black-brown/wallpaper-horizontal", Position 1 1, Size 128 64, 1, Nothing) :
    ("tiles/black-brown/wallpaper-vertical", Position 1 1, Size 64 128, 1, Nothing) :
    ("tiles/black-brown/shadow-standard", Position 1 1, Size 64 64, 1, Nothing) :
    ("tiles/black-brown/chain-standard", Position 1 1, Size 40 512, 1, Nothing) :
    ("tiles/neon/single-heart", Position 1 1, Size 588 532, 0.1, Just [0, 1, 2, 3, 4, 5, 6, 5, 6, 5, 6, 5, 6]) :
    ("tiles/neon/controller", Position 1 1, Size 844 468, 1, Nothing) :
    ("tiles/neon/pong", Position 1 1, Size 716 660, 1, Nothing) :
    ("tiles/neon/rocket", Position 1 1, Size 972 596, 1, Nothing) :
    ("tiles/neon/pac", Position 1 1, Size 716 468, 1, Nothing) :
    ("tiles/neon/tetris-01", Position 1 1, Size 332 340, 1, Nothing) :
    ("tiles/neon/snake", Position 1 1, Size 844 596, 1, Nothing) :
    ("tiles/neon/skull", Position 1 1, Size 588 596, 1, Nothing) :
-- temporary tiles (dummy)
    ("tiles/dummy/night-dusk", Position 0 0, Size 1920 1080, 1, Nothing) :
    ("tiles/dummy/submarine-blue", Position 0 0, Size 1920 1080, 1, Nothing) :
    ("tiles/dummy/skyline-blue-light", Position 0 0, Size 1024 512, 1, Nothing) :
    ("tiles/dummy/skyline-blue-dark", Position 0 0, Size 1024 512, 1, Nothing) :
    ("tiles/dummy/plankton", Position 1 1, Size 512 512, 1, Nothing) :
    ("tiles/dummy/high-school-girl-1", Position 1 1, Size 56 88, 1, Nothing) :
    ("tiles/dummy/high-school-girl-2", Position 1 1, Size 56 104, 1, Nothing) :
    ("tiles/dummy/high-school-girl-3", Position 1 1, Size 56 88, 1, Nothing) :
    ("tiles/dummy/high-school-girl-4", Position 1 1, Size 76 104, 1, Nothing) :
    ("tiles/dummy/cpt-beaugard", Position 1 1, Size 64 96, 1, Nothing) :
    ("tiles/dummy/data-terminal", Position 5 5, Size 128 192, 1, Nothing) :
    []
