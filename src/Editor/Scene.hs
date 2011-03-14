{-# language PatternGuards, NamedFieldPuns, DeriveDataTypeable, ScopedTypeVariables,
    FlexibleContexts #-}

-- | Here the scene used in the level editor is implemented.
-- The scene contains all available objects and all set objects.
-- The scene implements different modi (via Sum-Types) to
-- do things like associations from terminals to robots.
-- The core function (at the end of the file) is 'keyPress',
-- that gets the user input events and modifies the scene.

module Editor.Scene (
    EditorScene(..),
    initEditorScene,
    setNikkiPosition,
    updateSelected,
    updateEditorScene,
    renderEditorScene,
  ) where

import Data.Map hiding (map, filter, mapMaybe, size, member)
import Data.Set (member)
import Data.SelectTree
import qualified Data.Indexable as I
import Data.Indexable (Index, (>:), modifyByIndex, deleteByIndex, (!!!))
import Data.Abelian

import Control.Monad.State

import Graphics.Qt

import Utils

import Base

import Object

import Sorts.Nikki

import Editor.Scene.Types
import Editor.Scene.Rendering
import qualified Editor.Scene.RenderOrdering as RenderOrdering


-- | looks, if there is an object under the cursor (and therefore selected)
-- in the selected layer
searchSelectedObject :: EditorScene Sort_ -> Maybe (GroundsIndex, Index)
searchSelectedObject s@EditorScene{selectedLayer} =
    let indices = I.findIndices isSelected (content (editorObjects s !|| selectedLayer))
        isSelected o = lowerCorner o == cursor s
        lowerCorner o = editorPosition o
    in case indices of
        [] -> Nothing
        ll -> Just $ (selectedLayer, last ll)

-- * normalizers

updateSelected :: EditorScene Sort_ -> EditorScene Sort_
updateSelected s = s{selected = searchSelectedObject s}

-- * constructors

-- | the initial editor scene
initEditorScene :: SelectTree Sort_ -> Maybe String -> Grounds PickleObject -> IO (EditorScene Sort_)
initEditorScene sorts mPath pickledObjects = flip evalStateT empty $ do
    let objects :: Grounds (EditorObject Sort_) = fmap (pickleObject2EditorObject $ leafs sorts) pickledObjects
    pixmap <- get
    return $ updateSelected EditorScene{
        levelPath = mPath,
        cursor = zero,
        cursorStep = Just $ EditorPosition 64 64,
        availableSorts = sorts,
        editorObjects = objects,
        selectedLayer = MainLayer,
        selected = Nothing,
        editorMode = NormalMode,
        clipBoard = []
      }

-- | sets the position of Nikki (more precisely all Nikkis in the EditorScene) to the given value.
setNikkiPosition :: EditorPosition -> EditorScene Sort_ -> EditorScene Sort_
setNikkiPosition position =
    modifyEditorObjects (modifyMainLayer (fmap modifyNikki))
  where
    modifyNikki :: EditorObject Sort_ -> EditorObject Sort_
    modifyNikki o = if isNikki (editorSort o) then o{editorPosition = position} else o

-- * manipulating

-- | Updates the editor scene for a given key press.
-- Returns True in case the key was recognized and acted upon.
updateEditorScene :: MonadState (EditorScene Sort_) m =>
    AppEvent -> m Bool
updateEditorScene (Press (KeyboardButton key _)) = do
    acted <- keyPress key
    when acted $ do
        modify updateSelected
        modify normalizeOEMStates
    return acted
updateEditorScene _ = return False


-- * gamepad buttons
-- Start (== Escape) is handled above in Editor.MainLoop

keyPress :: MonadState (EditorScene Sort_) m =>
    Key -> m Bool
keyPress key = do
    scene <- get
    let newScene = case editorMode scene of
            NormalMode -> normalMode key scene
            ObjectEditMode{} -> objectEditModeUpdate key scene
            SelectionMode{} -> selectionMode key scene
    case newScene of
        Nothing -> return False
        Just newScene -> do
            -- acted on key event
            put newScene
            return True

-- * Main Editor mode

-- arrow keys
normalMode :: Key -> EditorScene Sort_ -> Maybe (EditorScene Sort_)
normalMode LeftArrow scene@EditorScene{cursor = (EditorPosition x y)} =
    let (EditorPosition sx sy) = getCursorStep scene
    in Just scene{cursor = (EditorPosition (x - sx) y)}
normalMode RightArrow scene@EditorScene{cursor = (EditorPosition x y)} =
    let (EditorPosition sx sy) = getCursorStep scene
    in Just scene{cursor = (EditorPosition (x + sx) y)}
normalMode UpArrow scene@EditorScene{cursor = (EditorPosition x y)} =
    let (EditorPosition sx sy) = getCursorStep scene
    in Just scene{cursor = (EditorPosition x (y - sy))}
normalMode DownArrow scene@EditorScene{cursor = (EditorPosition x y)} =
    let (EditorPosition sx sy) = getCursorStep scene
    in Just scene{cursor = (EditorPosition x (y + sy))}

-- add object
normalMode key scene@EditorScene{cursor, selectedLayer} | aKey == key =
    Just scene{editorObjects = objects'}
  where
    objects' = modifySelectedLayer selectedLayer
        (modifyContent (RenderOrdering.sortMainLayer . (>: new)))
        (editorObjects scene)
    new = mkEditorObject selectedSort cursor
    selectedSort = getSelected $ availableSorts scene

-- delete selected object
normalMode key scene@EditorScene{} | bKey == key =
    case selected scene of
        Nothing -> Just scene
        (Just (layerIndex, i)) ->
            let newObjects = modifySelectedLayer layerIndex (modifyContent (deleteByIndex i)) (editorObjects scene)
            in Just scene{editorObjects = newObjects}

-- skip through available objects
normalMode D scene@EditorScene{} =
    Just $ modifySorts selectNext scene
normalMode A scene@EditorScene{} =
    Just $ modifySorts selectPrevious scene

-- cycle through objects under cursor
-- (ordering of rendering will be automated)
normalMode B scene@EditorScene{editorObjects, selected = Just (layerIndex, i)} =
    let editorObjects' = modifySelectedLayer layerIndex (modifyContent (I.toHead i)) editorObjects
    in Just scene{editorObjects = editorObjects'}

-- change cursor step size

normalMode key scene | key `elem` [W, S] =
    Just $ changeCursorStepSize key scene

-- * Layers

normalMode Plus s@EditorScene{editorObjects, selectedLayer} =
    Just s{selectedLayer = modifyGroundsIndex editorObjects (+ 1) selectedLayer}
normalMode Minus s@EditorScene{editorObjects, selectedLayer} =
    Just s{selectedLayer = modifyGroundsIndex editorObjects (subtract 1) selectedLayer}

-- * paste from clipBoard

normalMode V s = Just $ pasteClipboard s

normalMode Space s = Just $ toSelectionMode s

normalMode _ scene = Nothing


-- * object edit mode

objectEditModeUpdate :: Key -> EditorScene Sort_ -> Maybe (EditorScene Sort_)
objectEditModeUpdate x s@EditorScene{editorMode = ObjectEditMode i, editorObjects} =
    let oldMainLayer = mainLayer editorObjects
        oldContent = content oldMainLayer
        oldObject = oldContent !!! i
        Just oldOemState = editorOEMState oldObject
        newOemState = mod oldOemState
    in case newOemState of
        Nothing -> Nothing
        Just x ->
            let newObject = oldObject{editorOEMState = newOemState}
                newContent = modifyByIndex (const newObject) i oldContent
                newMainLayer = oldMainLayer{content = newContent}
                newEditorObjects = editorObjects{mainLayer = newMainLayer}
            in Just s{editorObjects = newEditorObjects}
  where
    mod :: OEMState -> Maybe OEMState
    mod = oemUpdate s x


-- * selection mode

selectionMode :: Key -> EditorScene Sort_ -> Maybe (EditorScene Sort_)
selectionMode key scene@EditorScene{editorMode = SelectionMode pos}
    | key `member` allArrowKeys =
        Just scene{editorMode = SelectionMode (changeSelectionPosition key pos)}
  where
    changeSelectionPosition UpArrow (EditorPosition x y) = EditorPosition x (y - sy)
    changeSelectionPosition DownArrow (EditorPosition x y) = EditorPosition x (y + sy)
    changeSelectionPosition LeftArrow (EditorPosition x y) = EditorPosition (x - sx) y
    changeSelectionPosition RightArrow (EditorPosition x y) = EditorPosition (x + sx) y
    EditorPosition sx sy = getCursorStep scene
selectionMode X scene = Just $ cutSelection scene
selectionMode C scene = Just $ copySelection scene
selectionMode key scene | bKey == key || Delete == key = Just $ deleteSelection scene
selectionMode key scene | key `elem` [W, S] = Just $ changeCursorStepSize key scene

selectionMode _ scene = Nothing

-- | changes the cursor's step size with W and S
changeCursorStepSize :: Key -> EditorScene Sort_ -> EditorScene Sort_
changeCursorStepSize W scene =
    case cursorStep scene of
        Nothing -> setCursorStep scene $ Just $ EditorPosition 1 1
        Just (EditorPosition x y) -> setCursorStep scene $ Just $ EditorPosition (x * 2) (y * 2)
changeCursorStepSize S scene =
    case cursorStep scene of
        Nothing -> setCursorStep scene Nothing
        Just (EditorPosition 1 1) -> setCursorStep scene Nothing
        Just (EditorPosition x y) -> setCursorStep scene $ Just $ EditorPosition (x / 2) (y / 2)


-- * normalization of OEMStates
normalizeOEMStates :: Sort sort o => EditorScene sort -> EditorScene sort
normalizeOEMStates scene@EditorScene{editorObjects} =
    scene{editorObjects = newEditorObjects}
  where
    newEditorObjects = fmap modEditorObject editorObjects
    modEditorObject :: EditorObject sort -> EditorObject sort
    modEditorObject o@EditorObject{editorOEMState} =
        case editorOEMState of
            Nothing -> o
            Just oemState ->
                o{editorOEMState = Just $ oemNormalize scene oemState}
