{-# language ScopedTypeVariables #-}

module Sorts.Robots.MovingPlatform.Configuration where


import Base

import Sorts.Nikki as Nikki (nikkiMass)


-- | The mass of platforms.
-- (gravity has no effect on platforms
platformMass :: Double = nikkiMass * 3

-- | the acceleration that can will applied to a platform
-- to let it follow its path
platformAcceleration :: Double = 1700

-- | sets the epsilon range for the velocity correction
velocityEpsilon :: Double = 5

-- | general velocity of platforms
platformStandardVelocity :: Double = 150

-- | Factor with which the impulse at the path nodes will be applied.
-- 1.0 = perfect (hard) direction changes
-- 0.0 = no node impulse applied at all.
nodeImpulseFactor :: Double = 0.0


-- * chasing mode

-- | If the platform is more than positionEpsilon from its aim away,
-- it will accelerate to platformMaximumVelocity,
-- thus going into chasing mode.
positionEpsilon :: Double = 2

-- | The maximal velocity a platform can have when chasing the so called
-- guide point (to get in sync again)
platformMaximumVelocity :: Double = 230 -- 180

-- | Distance the aim will be away from the closest point on the path during chasing.
-- (Smaller = go back to the path faster,
--  Greater = go more directly to the end of the current segment)
-- Only relevant during chasing.
aimDistance :: Double = 50


-- * single nodes

-- When the platforms are switched off or there is just one path node,
-- a platform behaves like attached to a spring.

-- | When the platform is further than this value away from its aim,
-- the applied acceleration will have reached platformAcceleration
springConstantAccelerationDistance :: Double = fromKachel 0.4

-- | factor of friction
-- (not dependent on the velocity, like sliding friction)
frictionFactor :: Double = 0.05

-- | factor of drag
-- (dependent on velocity, like air drag)
dragFactor :: Double = 0.1
