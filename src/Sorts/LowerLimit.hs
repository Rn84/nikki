{-# language DeriveDataTypeable, MultiParamTypeClasses, ViewPatterns, ScopedTypeVariables,
    NamedFieldPuns #-}

-- | Implements a lower limit for a scene.
-- If Nikki is below that limit, the level is ended with failure.
-- If a robot is below a limit, it becomes uncontrollable.

module Sorts.LowerLimit (
    sorts,
    promoteLowerLimit,
    lowerLimitHandler,
    isBelowLowerLimit,
  ) where


import Prelude hiding (foldr)

import Data.Data
import Data.Indexable as I
import Data.Foldable

import qualified Physics.Chipmunk as CM

import Graphics.Qt

import Utils

import Base
import Base.Types ()

import Sorts.Nikki.Configuration


-- * Configuration

limitEditorColor = alpha ^= 0.5 $ red

-- | height that controlled objects can be below the lower limit while still being controllable
lowerLimitTolerance = (height nikkiSize / 2)


-- * Implementation

sorts :: RM [Sort_]
sorts = return [Sort_ LSort]

data LSort = LSort
  deriving (Show, Typeable)

isLowerLimit :: Sort sort o => sort -> Bool
isLowerLimit (cast -> Just _ :: Maybe LSort) = True
isLowerLimit (cast -> Just (Sort_ inner) :: Maybe Sort_) = isLowerLimit inner
isLowerLimit _ = False

unwrapLowerLimit :: Object_ -> Maybe LowerLimit
unwrapLowerLimit (Object_ sort o) = cast o

data LowerLimit =
    LowerLimit {limit :: Double}
  deriving (Show, Typeable)

instance Sort LSort LowerLimit where
    sortId LSort = SortId "lowerLimit"

    freeSort = const $ return ()

    size = const $ fmap fromKachel $ Size 1 1

    renderIconified sort ptr = do
        eraseRect ptr (fmap (round . fromKachel) $ Position 0 0.5)
                (fmap (round . fromKachel) $ Size 1 0.5) limitEditorColor
    renderEditorObject ptr offset eo = do
        window <- sizeQPainter ptr
        let startHeight = round (editorY (eo ^. editorPosition) + positionY offset)
        resetMatrix ptr
        eraseRect ptr (Position 0 startHeight) (Size (width window) (height window - startHeight)) limitEditorColor

    initialize sort mSpace ep Nothing =
        return $ LowerLimit $ editorY ep

    immutableCopy = removeError

    chipmunks = removeError

    renderObject = removeError

removeError = error "Sort.LowerLimit: LowerLimits have to be removed"


-- | promotes containted lower limits from
promoteLowerLimit :: Scene Object_ -> Scene Object_
promoteLowerLimit scene =
    lowerLimit ^= lookupLowerLimit (scene ^. (objects .> gameMainLayer)) $
    (objects .> gameMainLayer) ^: (I.filter (not . isLowerLimit . sort_)) $
    scene

lookupLowerLimit :: Indexable Object_ -> Maybe Double
lookupLowerLimit =
    fmap unwrapLowerLimit >>>
    fmap (fmap limit) >>>
    foldr maybeMax Nothing
  where
    maybeMax :: Ord a => Maybe a -> Maybe a -> Maybe a
    maybeMax (Just a) (Just b) = Just $ max a b
    maybeMax (Just a) Nothing = Just $ a
    maybeMax Nothing (Just a) = Just $ a
    maybeMax Nothing Nothing = Nothing

lowerLimitHandler :: Scene Object_ -> Maybe CM.Position -> Maybe (Scene Object_)
lowerLimitHandler scene Nothing = Nothing
lowerLimitHandler scene (Just p) =
    if isBelowLowerLimit scene p then
        case scene ^. mode of
            NikkiMode{} -> Just $ mode ^= LevelFinished (scene ^. spaceTime) Failed $ scene
            RobotMode{nikki, terminal} -> Just $ mode ^= TerminalMode nikki terminal $ scene
            _ -> Nothing
      else
        Nothing

isBelowLowerLimit :: Scene Object_ -> CM.Position -> Bool
isBelowLowerLimit scene p = case scene ^. lowerLimit of
    Just l -> CM.vectorY p > l + lowerLimitTolerance
    Nothing -> False